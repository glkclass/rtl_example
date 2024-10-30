#!/usr/bin python3

import serial
import logging


log = logging.getLogger()


def get_serial_port(port_id='/dev/ttyACM0', timeout=0):
    try:
        port = serial.Serial(port=port_id, timeout=timeout)
    except Exception as ex:
        log.critical(ex)
        return None

    if port.isOpen():
        log.info(f'Port "{port.name}" is opened')
    else:
        port.open()

        if port.isOpen():
            log.info(f'Port "{port.name}" is opened')
        else:
            log.warning(f'Can\'t open port "{port.name}"')

    return port


def close_serial_port(port):
    name = port.name
    if port.isOpen():
        port.close()
        log.info(f'Port "{name}" is closed')
    else:
        log.info(f'Port "{name}" is already closed')
