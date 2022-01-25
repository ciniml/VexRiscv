#!/use/bin/env python3

import sys
import serial
import serial.threaded
import struct


with serial.Serial('/dev/ttyUSB2', 1500000, timeout=1000) as port:
    with open('/home/kenta/vexriscv/VexRiscv/sw/bootrom/firmware/fw_jump.bin', 'rb') as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(0, 0)
        fw = f.read(size)
    
    class LinePrinter(serial.threaded.LineReader):
        def __init__(self):
            super(LinePrinter, self).__init__()
        def handle_line(self, data):
            print(data)

    t = serial.threaded.ReaderThread(port, LinePrinter)
    with t:
        size_aligned = (size + 3) & ~3
        print(f">> Bytes to transmit: {size_aligned}")
        t.write(struct.pack("<L", size_aligned))
        print("Transferring...")
        bytes_written = 0
        view = memoryview(fw)
        while bytes_written < size:
            w = t.write(view[bytes_written:])
            bytes_written += w
        padding_size = size_aligned - size
        if padding_size > 0:
            for i in range(padding_size):
                t.write(b'\0')

        print("Done.")

