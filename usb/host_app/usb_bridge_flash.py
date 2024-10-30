#!/usr/bin python3

# import os
# import sys
import logging

import serial_ports


from enum import Enum

# sys.path.append('/home/anton.voloshchuk/design')
# print (sys.path)


log = logging.getLogger()

# Serial port settings
port = ''
timeout = 1
usb_port = None

# Flash / bridge consts
BRIDGE_RETURN_PACKET_HEADER_SIZE = 3  # Number of packet heading bytes: ['header', 'bcmd', 'fcmd', ...]
BRIDGE_RETURN_PACKET_FOOTER_SIZE = 2  # Number of packet footer bytes: [..., 'crc', 'header']

BRIDGE_PACKET_HEADER = 0x5A
BRIDGE_PACKET_CRC = 0x53

FLASH_SIZE = pow(2, 26)  # 2^26 MBytes = 64 MBytes = 512 Mbits
FLASH_PAGE_SIZE = pow(2, 8)
FLASH_SECTOR_SIZE = pow(2, 16)
NUM_PAGES_PER_FLASH = int(FLASH_SIZE / FLASH_PAGE_SIZE)  # 2^18 = 262144 pages
NUM_SECTORS_PER_FLASH = int(FLASH_SIZE / FLASH_SECTOR_SIZE)  # 2^10 = 1024 sectors
NUM_PAGES_PER_SECTOR = int(FLASH_SECTOR_SIZE / FLASH_PAGE_SIZE)  # 2^8 = 256 pages

RESPONSE_IDX = 3  # Index of start of response(byte[0]) in response packet

# Status reg flag offsets
WRITE_IN_PROGRESS_OFFS = 0
WRITE_ENABLE_OFFS = 1


class FPLen(Enum):
    """Class "FPLen" - 'Flash packet length in bytes' field. Width - 5 bits"""
    L_1B = 0x1
    L_2B = 0x2
    L_3B = 0x3
    L_4B = 0x4
    L_5B = 0x5
    L_21B = 0x6
    L_256B = 0x1F


class Bcmd(Enum):
    """Class "Bcmd" - 'Bridge packet cmd' field. Width - 3 bits"""
    READ_BRIDGE_STATUS_REG_BCMD = 0x01
    EXECUTE_FLASH_WR_REG_BCMD = 0x2
    EXECUTE_FLASH_WR_MEM_BCMD = 0x3
    EXECUTE_FLASH_RD_REG_BCMD = 0x4
    EXECUTE_FLASH_RD_MEM_BCMD = 0x5


def get_bcmd(bcmd, fp_len):
    """Combine 'Bridge Cmd' (8 bits) from two fields:
    'bcmd' - (3 bits).
    'fp_len' -  5 bits. Define flash packet length including cmd, data-in/addr-in, data-out. See 'FPLen' enum"""
    assert isinstance(bcmd, int) and bcmd < 8
    assert isinstance(fp_len, int) and fp_len < 32
    return bcmd + (fp_len << 3)


Pcmd = {
    'READ_BRIDGE_STATUS_REG_BCMD':              {'fcmd': 0x00, 'bcmd': get_bcmd(Bcmd.READ_BRIDGE_STATUS_REG_BCMD.value, 0), 'response_len': 500},

    # 1-Byte commands
    'RESET_ENABLE':                             {'fcmd': 0x66, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'RELEASE_FROM_DEEP_POWER_DOWN':             {'fcmd': 0xAB, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'WRITE_ENABLE':                             {'fcmd': 0x06, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'WRITE_DISABLE':                            {'fcmd': 0x04, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'ENTER_4B_ADDRESS_MODE':                    {'fcmd': 0xB7, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'EXIT_4B_ADDRESS_MODE':                     {'fcmd': 0xE9, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},

    # Erase commands
    'BULK_ERASE':                               {'fcmd': 0xC7, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_1B.value), 'response_len': 5},
    'SECTOR_64KB_ERASE_4B':                     {'fcmd': 0xDC, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_5B.value), 'response_len': 5},
    'SUBSECTOR_32KB_ERASE_4B':                  {'fcmd': 0x5C, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_5B.value), 'response_len': 5},
    'SUBSECTOR_4KB_ERASE_4B':                   {'fcmd': 0x21, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_5B.value), 'response_len': 5},

    # Write reg commands
    'WRITE_STATUS_REGISTER':                    {'fcmd': 0x01, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_2B.value), 'response_len': 500},
    'WRITE_VOLATILE_CONFIGURATION_REGISTER':    {'fcmd': 0x81, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_REG_BCMD.value, FPLen.L_2B.value), 'response_len': 500},

    # Read reg commands
    'READ_STATUS_REGISTER':                     {'fcmd': 0x05, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_REG_BCMD.value, FPLen.L_2B.value), 'response_len': 6},
    'READ_FLAG_STATUS_REGISTER':                {'fcmd': 0x70, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_REG_BCMD.value, FPLen.L_2B.value), 'response_len': 6},
    'READ_NONVOLATILE_CONFIGURATION_REGISTER':  {'fcmd': 0xB5, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_REG_BCMD.value, FPLen.L_3B.value), 'response_len': 500},
    'READ_VOLATILE_CONFIGURATION_REGISTER':     {'fcmd': 0x85, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_REG_BCMD.value, FPLen.L_2B.value), 'response_len': 500},
    'READ_ID':                                  {'fcmd': 0x9E, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_REG_BCMD.value, FPLen.L_21B.value), 'response_len': 500},

    #Program mem
    'PAGE_PROGRAM_4B':                          {'fcmd': 0x12, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_WR_MEM_BCMD.value, FPLen.L_256B.value), 'response_len': 5},

    #Read mem
    'READ_MEM_4B':                              {'fcmd': 0x13, 'bcmd': get_bcmd(Bcmd.EXECUTE_FLASH_RD_MEM_BCMD.value, FPLen.L_256B.value), 'response_len': 261}
}


def init_port_name(port_name):
    global port
    port = port_name


def open_port():
    global usb_port
    usb_port = serial_ports.get_serial_port(port_id=port, timeout=timeout)
    assert(usb_port is not None), f'Cant open serial port: {port}. Do not forget to grant access permissions: sudo chmod 666 {port}'


def close_port():
    global usb_port
    assert usb_port is not None
    serial_ports.close_serial_port(usb_port)


def get_flag(reg=0x00, offset=0, prnt=0):
    reg >>= offset
    reg &= 0x01
    if prnt:
        log.debug(f'Status reg flag: {reg:1b}')
    return reg


def get_packet_addr(addr):
    assert addr >= 0 and addr <= (FLASH_SIZE - FLASH_PAGE_SIZE), f'log.debug 0x{addr:X}'
    packet = []
    for i in range(4):
        packet.append(addr & 0xFF)
        addr >>= 8
    packet.reverse()
    return packet


def get_packet(cmd, content=None):
    """Assemble 8-byte packet to be sent to bridge"""
    assert cmd in Pcmd.keys()
    packet = [BRIDGE_PACKET_HEADER, Pcmd[cmd]['bcmd'], Pcmd[cmd]['fcmd']]
    if content is not None:
        if isinstance(content, int):
            packet.append(content)
        elif isinstance(content, (list, tuple)):
            assert len(content) <= 4
            packet.extend(content)

    if len(packet) < 7:
        packet.extend([0] * (7 - len(packet)))
    packet.append(BRIDGE_PACKET_CRC)

    for item in packet:
        assert (isinstance(item, int) and item >= 0 and item <= 0xFF)
    return {'cmd': cmd, 'content': packet, 'response_len': Pcmd[cmd]['response_len']}


def to_hex(packet):
    assert isinstance(packet, (list, tuple))
    return[f"0x{item:02X}" for item in packet]


def to_bin(packet):
    assert isinstance(packet, (list, tuple))
    return[f"b{item:08b}" for item in packet]


def send_packet(packet, prnt=0):
    global usb_port
    assert usb_port is not None
    foo = bytes(packet['content'])
    if prnt:
        log.info(f"Send cmd: {packet['cmd']}\t{to_hex(packet['content'])}")
    usb_port.write(foo)
    return recieve_packet(packet['response_len'], prnt=prnt)


def recieve_packet(n, prnt=0):
    global usb_port
    assert usb_port is not None
    foo = usb_port.read(n)
    assert isinstance(foo, bytes), log.critical(f"Wrong type: {type(foo)}")
    foo = [item for item in foo]
    assert n == len(foo), f'Actual packet size {len(foo)} != expected size {n} for {foo}'
    if prnt:
        log.info(f"Recieved packet length = {len(foo)}\n{to_hex(foo)}")
    return foo
