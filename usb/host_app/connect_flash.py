#!/usr/bin python3

import os
import time
import sys
import random
import logging
import argparse


# sys.path.append('/home/anton.voloshchuk/design')
# print (sys.path)

from usb_bridge_flash import get_flag, to_hex, get_packet, get_packet_addr, open_port, close_port, init_port_name
from usb_bridge_flash import send_packet
from usb_bridge_flash import BRIDGE_PACKET_CRC, RESPONSE_IDX, WRITE_ENABLE_OFFS, WRITE_IN_PROGRESS_OFFS
from usb_bridge_flash import FLASH_SIZE, FLASH_SECTOR_SIZE, FLASH_PAGE_SIZE, NUM_SECTORS_PER_FLASH

formatter = logging.Formatter('%(asctime)s %(levelname)s : %(name)s - %(message)s : %(filename)s, %(lineno)d', datefmt='%Y/%m/%d %H:%M:%S')
log = logging.getLogger()
log.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setFormatter(formatter)
log.addHandler(ch)
fh = logging.FileHandler(os.path.splitext(os.path.basename(__file__))[0] + '.log', 'w')
fh.setFormatter(formatter)
log.addHandler(fh)

AVV_DEBUG = int(os.environ.get('AVV_DEBUG', '0'))


def erase_sector(size=4, addr=0x_00_01_00_00, prnt=0):
    assert size in [4, 32, 64, 0]

    cmd = {4: 'SUBSECTOR_4KB_ERASE_4B', 32: 'SUBSECTOR_32KB_ERASE_4B', 64: 'SECTOR_64KB_ERASE_4B', 0: 'BULK_ERASE'}
    read_status_reg(prnt=prnt)
    send_packet(get_packet('WRITE_ENABLE'), prnt=prnt)
    send_packet(get_packet('ENTER_4B_ADDRESS_MODE'), prnt=prnt)
    read_status_reg(prnt=prnt)
    send_packet(get_packet(cmd[size], content=get_packet_addr(addr)), prnt=prnt)
    poll_status()


def program_mem_page(data=[0x00] * FLASH_PAGE_SIZE, addr=0x_00_00_00_00, prnt=0):
    """Program 256-Byte page. '4B address' mode should be enable before programming"""
    assert isinstance(data, (list, tuple)) and FLASH_PAGE_SIZE == len(data)
    assert 0x00_00_00_00 == (addr & 0x_00_00_00_FF), f'Non-aligned address: 0x{addr:08X} for page program. Should be multiple of 0x100!!!'

    if prnt:
        log.debug(f'Program page addr: 0x{addr:08X}')

    send_packet(get_packet('WRITE_ENABLE'), prnt=prnt)
    # read_status_regs(prnt=0)

    foo = get_packet('PAGE_PROGRAM_4B', content=get_packet_addr(addr))
    foo['content'].extend(data)
    foo['content'].append(BRIDGE_PACKET_CRC)

    send_packet(foo)
    poll_status()


def program_mem_range(data=[], addr0=0x_00_00_00_00, prnt=0):
    assert isinstance(data, (list, tuple)) and 0 < len(data) and FLASH_SIZE >= len(data)
    data_size = len(data)

    tail = data_size % FLASH_PAGE_SIZE
    if 0 < tail:
        data.extend([0xFF] * (FLASH_PAGE_SIZE - tail))
    data_size = len(data)
    assert 0 == (data_size % FLASH_PAGE_SIZE)

    num_pages_to_program = int(data_size / FLASH_PAGE_SIZE)

    send_packet(get_packet('ENTER_4B_ADDRESS_MODE'), prnt=prnt)     # enable '4 Byte addressing' mode

    for i in range(num_pages_to_program):
        addr = addr0 + i * FLASH_PAGE_SIZE
        log.info(f'Program page #{i} of {num_pages_to_program}, starting address: 0x{addr:08X}')
        program_mem_page(data=data[i * FLASH_PAGE_SIZE:(i + 1) * FLASH_PAGE_SIZE], addr=addr, prnt=prnt)


def erase_mem_range(addr0=0x_00_00_00_00, num_sectors=1, prnt=0):
    assert num_sectors > 0 and num_sectors <= NUM_SECTORS_PER_FLASH

    addr0_aligned = addr0 & 0x_FF_FF_00_00

    # we erase whole 64KB sector in case of unalligned starting address !!!
    if addr0_aligned != addr0:
        log.warning(f'Unaligned starting address! 64KB sector starting on address: 0x{addr0_aligned:08X} will be erased!!!')

    log.info(f'{num_sectors} sector(s)(64KB) starting on address: 0x{addr0_aligned:08X} will be erased')

    for i in range(num_sectors):
        addr = addr0 + i * FLASH_SECTOR_SIZE
        log.info(f'Erase {64}KB sector #{i} of {num_sectors}, starting address: 0x{addr:08X}')
        erase_sector(64, addr)


def read_mem_page(addr=get_packet_addr(0x_00_00_00_00)):
    return send_packet(get_packet('READ_MEM_4B', content=get_packet_addr(addr)))


def read_mem_range(addr0=0x_00_00_00_00, data_size=1, prnt=0):
    assert 0 < data_size and FLASH_SIZE >= data_size
    num_pages_to_read = int(data_size / FLASH_PAGE_SIZE) + ((data_size % FLASH_PAGE_SIZE) > 0)

    response_range = []
    for i in range(num_pages_to_read):
        addr = addr0 + i * FLASH_PAGE_SIZE
        log.info(f'Read page #{i} of {num_pages_to_read}, starting address: 0x{addr:08X}')
        response = read_mem_page(addr)
        response_range[i * FLASH_PAGE_SIZE: (i + 1) * FLASH_PAGE_SIZE] = response[RESPONSE_IDX: RESPONSE_IDX + FLASH_PAGE_SIZE]
        if prnt:
            log.debug(f"{to_hex(response_range[i * FLASH_PAGE_SIZE: (i + 1) * FLASH_PAGE_SIZE])}")
    return response_range


def read_status_regs(prnt=0):
    send_packet(get_packet('READ_STATUS_REGISTER'), prnt=prnt)
    send_packet(get_packet('READ_FLAG_STATUS_REGISTER'), prnt=prnt)
    # time.sleep(0.1)


def read_status_reg(prnt=0):
    response = send_packet(get_packet('READ_STATUS_REGISTER'))
    status_reg = response[RESPONSE_IDX]
    if prnt:
        log.debug(f"{to_hex(response)}")
    return status_reg


def poll_status(prnt=0):
    if prnt:
        log.debug('Poll status..')
    for i in range(10000):
        status_reg = read_status_reg(prnt=prnt)
        if 0 == (get_flag(status_reg, WRITE_ENABLE_OFFS) | get_flag(status_reg, WRITE_IN_PROGRESS_OFFS)):
            if prnt:
                log.debug(f'Status reg cleared after {i} tries')
            break
    else:
        log.error('Poll status timeout')
        sys.exit()


def generate_random_data(data_size, prnt=0):
    assert 0 < data_size and FLASH_SIZE >= data_size

    random.seed()
    data = [0x00] * data_size
    for i in range(data_size):
        j = i % 4
        if 0 == j:
            foo = random.randrange(pow(2, 32))
        data[i] = (foo >> (j * 8)) & 0xFF
    if prnt:
        log.debug(f'\nLen: {len(data)}\nContent:\n{to_hex(data)}')
    return (data)


def check_data_integrity(data, data_read):
    assert len(data) <= len(data_read), f'Data integrity failed: Size of data read is less than expected: {len(data_read)} < {len(data)}'
    for i in range(len(data)):
        assert data[i] == data_read[i], f'Data integrity failed:  data idx={i}, 0x{data[i]:02X} != 0x{data_read[i]:02X}'
    else:
        log.info(f'Data size = {len(data)} bytes, integrity check passed!')


def upload_flash_data(data=[], addr0=0x_00_00_00_00):
    data_size = len(data)
    assert 0 < data_size and FLASH_SIZE >= data_size, f'Too large data size for upload: {data_size} bytes!!!'

    open_port()
    num_sectors_to_erase = int(data_size / FLASH_SECTOR_SIZE) + ((data_size % FLASH_SECTOR_SIZE) > 0)
    erase_mem_range(addr0, num_sectors_to_erase)

    program_mem_range(data=data, addr0=addr0)

    data_read = read_mem_range(addr0=addr0, data_size=data_size, prnt=0)

    check_data_integrity(data, data_read)
    close_port()


def read_flash_data(addr0=0x_00_00_00_00, size=0):
    assert 0 < size and FLASH_SIZE >= size, f'Too large data size for reading: {size} bytes!!!'
    open_port()
    data_read = read_mem_range(addr0=addr0, data_size=size, prnt=0)
    close_port()
    return data_read


def check_flash_erase_program_read_op(addr0=0x_00_00_00_00, data_size=1):
    assert 0 < data_size and FLASH_SIZE >= data_size
    data = generate_random_data(data_size, prnt=1)
    upload_flash_data(data=data, addr0=addr0)


def upload_file_to_flash(flash_content_fn='', addr0=0x_00_00_00_00):
    assert isinstance(flash_content_fn, str), f'Unacceptible file name(<{flash_content_fn}>) type({type(flash_content_fn)}): Should be \'string\'!'
    assert os.path.exists(flash_content_fn), f'File: \'{flash_content_fn}\' doesn\'t exist'
    log.info(f'Uploading binary file: \'{args.file}\' starting from address: 0x{args.addr:08X} using serial port: {args.port}')
    with open(flash_content_fn, mode='rb') as file:
        data = file.read()
    data = [item for item in data]

    t_start = time.time()
    upload_flash_data(data=data, addr0=addr0)
    duration = round(time.time() - t_start)
    log.info(f'Duration: {round(duration / 3600):02d}h {round((duration % 3600) / 60):02d}m {duration % 60:02d}s')


def read_file_from_flash(flash_content_fn='', addr0=0x_00_00_00_00, size=0):
    assert isinstance(flash_content_fn, str), f'Unacceptible file name(<{flash_content_fn}>) type({type(flash_content_fn)}): Should be \'string\'!'
    log.info(f'Reading flash data starting from address: 0x{args.addr:08X} and storing to: \'{args.file}\' using serial port: {args.port}')

    t_start = time.time()

    # data = [item for item in range(256)]
    data = read_flash_data(addr0=addr0, size=size)
    log.info(f'{len(data)} bytes of data were read')
    log.info(bytes(data))

    with open(flash_content_fn, mode='wb') as file:
        file.write(bytes(data))

    duration = round(time.time() - t_start)
    log.info(f'Duration: {int(duration / 3600):02d}h {int((duration % 3600) / 60):02d}m {duration % 60:02d}s')



def run():
    pass


def run_debug():
    t_start = time.time()
    time.sleep(10)
    t_finish = time.time()
    duration = round(t_finish - t_start)
    log.debug(f"{t_start}, {t_finish}, {duration}")
    # check_flash_erase_program_read_op(0x_00_F0_00_00, pow(2, 16) + 5)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Write/read binary file to SPI flash starting from given address', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-m', '--mode', type=str, help="Work mode: 'w' - write data to flash; 'r' - read data from flash", default='w')
    parser.add_argument('-f', '--file', type=str, help="Path to binary file to read/write data")
    parser.add_argument('-a', '--addr', type=int, help="Starting flash address for data to write/read. Integer value in decimal format", default=0)
    parser.add_argument('-s', '--size', type=int, help="Size of data in bytes to be read. Integer value in decimal format", default=256)
    parser.add_argument('-p', '--port', type=str, help="Serial port to communicate with hardware", default='/dev/ttyACM0')
    args = parser.parse_args()

    init_port_name(args.port)

    # Used for ST4 debug
    args.file = '/tmp/tmp.bin' if AVV_DEBUG else args.file
    args.mode = 'r' if AVV_DEBUG else args.mode
    args.size = 512 if AVV_DEBUG else args.size

    if 'w' == args.mode:
        upload_file_to_flash(args.file, args.addr)
    else:
        read_file_from_flash(args.file, args.addr, args.size)

    # run_debug()

    # run()
    log.info('Done')
