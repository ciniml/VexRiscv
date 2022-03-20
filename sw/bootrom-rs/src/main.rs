#![no_std]
#![no_main]

use core::{arch::{global_asm, asm}, panic::PanicInfo};
use core::fmt::Write;
use hal::serial::nb::Read;
use vexriscv_pac;
use embedded_hal as hal;

global_asm!(r#"
.section .isr_vector,"ax",@progbits
    j _start
    j _start
.section .text,"ax",@progbits
_start:
    la sp, ramend
    j main
"#);

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

struct Uart<UART> {
    uart: UART,
}
impl Uart<vexriscv_pac::UART> {
    pub fn init(uart: vexriscv_pac::UART, clock: u32, baud_rate: u32) -> Self {
        uart.lcr.write(|w| w.dlab().set_bit()); 
        let divisor = clock / (16 * baud_rate);
        uart.dll().write(|w| w.dll().bits((divisor & 0xff) as u8)); 
        uart.dlm.write(|w| w.dlm().bits((divisor >> 8) as u8));
        uart.lcr.write(|w| w.wls().eight());
        uart.fcr.write(|w| w.rcvr_fifo_trigger_level().eight_bytes().fifoen().set_bit());
        Self {
            uart,
        }
    }
}
impl hal::serial::ErrorType for Uart<vexriscv_pac::UART> {
    type Error = hal::serial::ErrorKind;
}
impl hal::serial::nb::Write<u8> for Uart<vexriscv_pac::UART> {
    fn write(&mut self, word: u8) -> hal::nb::Result<(), Self::Error> {
        if self.uart.lsr.read().thre().bit_is_clear() { // THR is not empty
            Err(hal::nb::Error::WouldBlock)
        } else {
            self.uart.thr().write(|w| w.thr().bits(word));
            Ok(())
        }
    }
    fn flush(&mut self) -> hal::nb::Result<(), Self::Error> {
        if self.uart.lsr.read().temt().bit_is_set() {
            Ok(())
        } else {
            Err(hal::nb::Error::WouldBlock)
        }
    }
}
impl hal::serial::nb::Read<u8> for Uart<vexriscv_pac::UART> {
    fn read(&mut self) -> hal::nb::Result<u8, Self::Error> {
        if self.uart.lsr.read().dr().bit_is_set() {
            Ok(self.uart.rbr().read().rbr().bits())
        } else {
            Err(hal::nb::Error::WouldBlock)
        }
    }
}
impl core::fmt::Write for Uart<vexriscv_pac::UART> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        use hal::serial::nb::Write;
        for byte in s.as_bytes().into_iter() {
            hal::nb::block!(self.write(*byte)).map_err(|_| core::fmt::Error)?
        }
        Ok(())
    }
}

fn read_line<const N: usize>(uart: &mut Uart<vexriscv_pac::UART>, line: &mut heapless::String<N>) {
    loop {
        let c = hal::nb::block!(uart.read()).unwrap();
        match c {
            0x08 => {
                if line.len() > 0 {
                    line.pop();
                }
            },
            0x0d => {}, // Ignore CR
            0x0a => {
                return;
            },
            c => {
                let valid = match char::from_u32(c as u32) {
                    Some(c) => line.push(c).is_ok(),
                    None => false,
                };
                use hal::serial::nb::Write;
                if !valid {
                    hal::nb::block!(uart.write(0x0b)).unwrap();
                } else {
                    hal::nb::block!(uart.write(c)).unwrap();
                }
            }
        }
    }
}

fn set_misa(xlen: u32, extensions: &[u8]) -> u32 {
    let mut misa = if xlen == 32 {0b01u32 << 30} else {0b10u32 << 30};
    for extension in extensions {
        if b'A' <= *extension && *extension <= b'Z' {
            misa |= 1 << (*extension - b'A');
        } else if b'a' <= *extension && *extension < b'z' {
            misa |= 1 << (*extension - b'a');
        }
    }
    let mut old: u32;
    unsafe { asm!("csrrw {old}, misa, {new}", old = out(reg) old, new = in(reg) misa ); }
    old
}


const FDT_BASE: usize = 0x83000000;
const FDT_END: usize  = 0x83002fff;
const SBI_BASE: usize = 0x80010000;

type BootloaderEntry = extern fn(a0: u32, a1: u32, a2: u32, a3: u32, a4: u32) -> !;

#[no_mangle]
pub extern "C" fn main() -> ! {
    let clock_hz = 300000000;
    let uart_baud = 115200;
    let peripherals = vexriscv_pac::Peripherals::take().unwrap();
    let mut uart = Uart::<vexriscv_pac::UART>::init(peripherals.UART, clock_hz, uart_baud);
    
    writeln!(&mut uart, "BOOTLOADER on VexRiscV").unwrap();

    let mut line: heapless::String<80> = heapless::String::new();
    loop {
        write!(&mut uart, "> ").unwrap();
        read_line(&mut uart, &mut line);
        writeln!(&mut uart, "").unwrap();
        writeln!(&mut uart, "{}", &line).unwrap();
        if line == "boot" {
            break;
        }
    }
    unsafe { asm!("fence"); }
    writeln!(&mut uart, "FDT: {:08X} to {:08X}", FDT_BASE, FDT_END).unwrap();
    writeln!(&mut uart, "Jump to address {:08X}", SBI_BASE).unwrap();
    hal::nb::block!(hal::serial::nb::Write::flush(&mut uart)).unwrap();
    set_misa(32, b"imasu");
    unsafe { asm!("fence.i"); }
    let entry: BootloaderEntry = unsafe { core::mem::transmute(SBI_BASE as *const ())};
    entry(
        0,
        FDT_BASE as u32,
        0,
        0,
        0,
    );
}