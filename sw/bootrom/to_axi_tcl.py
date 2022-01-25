#!/usr/bin/env python3
import struct
import sys

BASE_ADDRESS = 0x80000000

with open(sys.argv[1], 'rb') as f:
    f.seek(0, 2)
    total_bytes = f.tell()
    f.seek(0, 0)
    data = f.read(total_bytes)
    
    print('delete_hw_axi_txn -quiet [get_hw_axi_txns load_bin_*]')
    for offset in range(0, total_bytes, 4):
        address = BASE_ADDRESS + offset
        word = struct.unpack_from('<L', data, offset)[0]
        print(f'create_hw_axi_txn load_bin_{offset} [lindex [get_hw_axis] 0] -type write -len 1 -address {address:08X} -data {{{word:08X}}}')
    print(f'run_hw_axi -quiet [get_hw_axi_txns load_bin_*]')
    print('delete_hw_axi_txn -quiet [get_hw_axi_txns load_bin_*]')
