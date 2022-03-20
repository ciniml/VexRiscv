#include <stdint.h>
#include <stdbool.h>

extern void __attribute__((naked)) __attribute__((section(".isr_vector"))) isr_vector(void)
{
    asm volatile ("j _start");
    asm volatile ("j _start");
}

void __attribute__((noreturn)) main(void);

extern void __attribute__((naked)) _start(void)
{
    asm volatile ("la sp, ramend");
    main();
}

static volatile uint32_t* const REG_GPIO_OUT = (volatile uint32_t*)0x40000000;
static volatile uint32_t* const REG_GPIO_DIR = (volatile uint32_t*)0x40000004;
static const uintptr_t ADDR_REG_UART_BASE = 0x40010000;

static volatile uint32_t* const REG_UART_THR = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1000);
static volatile uint32_t* const REG_UART_RBR = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1000);
static volatile uint32_t* const REG_UART_FCR = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1008);
static volatile uint32_t* const REG_UART_LCR = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x100C);
static volatile uint32_t* const REG_UART_LSR = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1014);
static volatile uint32_t* const REG_UART_DLL = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1000);
static volatile uint32_t* const REG_UART_DLM = (volatile uint32_t*)(ADDR_REG_UART_BASE + 0x1004);

static const uint32_t CLOCK_HZ = 300000000;
static const uint32_t UART_BAUD = 115200;
static const uint16_t UART_DIVISOR = (CLOCK_HZ/(16*UART_BAUD));
static const uint8_t UART_DIVISOR_L = UART_DIVISOR & 0xff;
static const uint8_t UART_DIVISOR_H = UART_DIVISOR >> 8;

static const uintptr_t FDT_BASE = 0x83000000;
static const uintptr_t FDT_END  = 0x83002fff;
static const uintptr_t SBI_BASE = 0x80010000;

static uint32_t set_misa(uint32_t xlen, const char* extensions)
{
    uint32_t misa = xlen == 32 ? (0b01u << 30) : (0b10u << 30);
    for(const char* p = extensions; *p != 0; p++) {
        if( 'A' <= *p && *p <= 'Z') {
            misa |= (1u << (*p - 'A'));
        } else if( 'a' <= *p && *p < 'z' ) {
            misa |= (1u << (*p - 'a'));
        }
    }
    uint32_t old;
    asm volatile ("csrrw %0, misa, %1" : "=r" (old) : "r" (misa) : );
    return old;
}

static uint64_t read_cycle(void)
{
    uint32_t l, h, hv;
    do {
        asm volatile ("rdcycleh %0" : "=r" (h));
        asm volatile ("rdcycle  %0" : "=r" (l));
        asm volatile ("rdcycleh %0" : "=r" (hv));
    } while(h != hv);
    return ((uint64_t)h << 32) | l;
} 

static void uart_tx(uint8_t value) 
{
    while((*REG_UART_LSR & (1u << 5)) == 0);    // THR is not empty.
    *REG_UART_THR = value;
}
static bool uart_rx_ready()
{
    return (*REG_UART_LSR & (1u << 0)) != 0;    // DR is set.
}
static uint8_t uart_rx() 
{
    while(!uart_rx_ready());
    return *REG_UART_RBR;
}
static uint32_t uart_read_32_le()
{
    uint32_t data = (uart_rx() << 24);
    data = (data >> 8) | (uart_rx() << 24);
    data = (data >> 8) | (uart_rx() << 24);
    data = (data >> 8) | (uart_rx() << 24);
    return data;
}
static uint32_t uart_read_32_be()
{
    uint32_t data = uart_rx();
    data = (data << 8) | uart_rx();
    data = (data << 8) | uart_rx();
    data = (data << 8) | uart_rx();
    return data;
}

static void uart_put_hex_8(uint8_t n)
{
    uint8_t nibble = n >> 4;
    uart_tx(nibble < 10 ? '0' + nibble : nibble + 'a' - 10);
    nibble = n & 0xf;
    uart_tx(nibble < 10 ? '0' + nibble : nibble + 'a' - 10);
}
static void uart_put_hex_16(uint16_t n)
{
    uart_put_hex_8(n >> 8);
    uart_put_hex_8(n & 0xff);
}
static void uart_put_hex_32(uint32_t n)
{
    uart_put_hex_16(n >> 16);
    uart_put_hex_16(n & 0xffff);
}

static void uart_puts(const char* s)
{
    while(*s) {
        uart_tx((uint8_t)*(s++));
    }
}
static void uart_flush(void)
{
    while((*REG_UART_LSR & (1u << 6)) == 0);    // TEMT
}


static void wait_cycles(uint64_t cycles)
{
    uint64_t start = read_cycle();
    while(read_cycle() - start < cycles);
}

typedef void __attribute__((noreturn)) (*bootloader_entry_proc)(uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4);

static int strcmp_s(const char* l, const char* r, int len)
{
    for(int i = 0; i < len; i++) {
        if( *l < *r ) {
            return -1;
        } else if( *l > *r ) {
            return 1;
        }
    }
    return 0;
}

static void dump_range(uintptr_t start, uintptr_t end)
{
    for(uintptr_t p = start; p < end; p += 16) {
        uart_put_hex_32(p);
        uart_puts(": ");
        for(int i = 0; i < 16 && p < end; i++, p++) {
            uart_put_hex_8(*(uint8_t*)p);
            uart_tx(' ');
        }
        uart_puts("\r\n");
    }
}

void __attribute__((noreturn)) main(void)
{
    uint32_t led_out = 0x00;
    uint32_t clock_hz = 100000000u;
    *REG_GPIO_DIR = 0x0;
    // Initialize UART
    *REG_UART_LCR = 0b10000000; // Enable access to divisor latch
    *REG_UART_DLL = UART_DIVISOR_L;
    *REG_UART_DLM = UART_DIVISOR_H;
    *REG_UART_LCR = 0b00000011; // Data bits = 8
    *REG_UART_FCR = 0b10000001; // trigger 8 bytes, FIFO EN
    
    uart_puts("BOOTLOADER on VexRiscV\r\n");
    uart_flush();
    
    // uint32_t length = uart_read_32_le();
    // uart_puts("LENGTH: ");
    // uart_put_hex_32(length);
    // uart_puts("\r\n");
    // uart_puts("BUFFER HEAD: ");
    // uart_put_hex_32(*(uint32_t*)0xc0010000);
    // uart_puts("\r\n");
    // uart_flush();
    
    // uint32_t* dest = (uint32_t*)0xc0010000;
    // for(; length > 0; length -= 4) {
    //     uint32_t word = uart_read_32_le();
    //     *(dest++) = word;
    //     led_out ^= 1;
    //     *REG_GPIO_OUT = led_out;
    // }

    char line[81];
    while(1) {
        uint32_t index = 0;
        uart_puts("> ");
        while(1) {
            char c = uart_rx();
            switch(c) {
                case 0x08:  // backspace
                    index = index > 0 ? index - 1 : index;
                    break;
                case 0x0a:  // LF
                    c = 0;
                    line[index] = 0;
                    break;
                default:
                    if( index < sizeof(line) - 1) {
                        line[index] = c;
                        index++;           
                    } else {
                        c = '\b';
                    }
                    break;
            }
            if( c == 0 ) break;
            uart_tx(c);
        }

        if( strcmp_s(line, "boot", sizeof(line)) == 0 ) {
            break;
        }
    }

    *REG_GPIO_OUT = 0b0010;
    asm volatile ("fence");
    uart_puts("FDT:\r\n");
    dump_range(FDT_BASE, FDT_BASE + 0x100);
    uart_puts("SBI:\r\n");
    dump_range(SBI_BASE, SBI_BASE + 0x100);
    uart_puts("Booting...\r\n");
    uart_flush();
    // Setup MISA
    set_misa(32, "imasu");  // 'S' and 'U' extension, MXL = 2'b01 (XLEN = 32)
    // Jump
    asm volatile ("fence.i");
    ((bootloader_entry_proc)SBI_BASE)(
        0,  // BOOT HART ID
        FDT_BASE,   // FDT Base address
        0,
        0,
        0);
}