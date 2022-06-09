#!/usr/bin/env python3

import json
import urllib.request

MIDR_PATH = "/sys/devices/system/cpu/cpu0/regs/identification/midr_el1"
CPUS_JSON_URL = "https://raw.githubusercontent.com/ARM-software/data/master/cpus.json"


def get_midr_string():
    """Reads the Main ID Register (MIDR).

    See https://developer.arm.com/documentation/100616/0301/register-descriptions/aarch64-system-registers/midr-el1--main-id-register--el1
    """
    with open(MIDR_PATH) as f:
        return f.readline().rstrip()


def get_cpuid(midr_string=None):
    """Create a CPU ID from the implementer and part num components of the specified MIDR string.

    If no MIDR is specified, the MIDR of the first CPU/core on the current machine will be used."""
    if not midr_string:
        midr_string = get_midr_string()

    midr = int(midr_string, 16)
    implementer = (midr & 0xff000000) >> 24
    part_num = (midr & 0x0000fff0) >> 4
    return (implementer << 12) + part_num


def get_cpu(midr_string=None):
    """Returns the name of the CPU/core specified MIDR string.

    If no MIDR is specified, the MIDR of the first CPU/core on the current machine will be used."""
    cpu_id = get_cpuid(midr_string)
    cpus = read_cpus()

    cpu = cpus.get(cpu_id)
    if cpu:
        cpu = cpu.lower().replace(" ", "-")
    return cpu


def read_cpus():
    """Returns a dict of cpuid => CPU name by fetching metadata from Arm's github repo"""
    try:
        r = urllib.request.urlopen(CPUS_JSON_URL)
        cpus_json = json.loads(r.read())
        return {int(cpu["cpuid"], 16): cpu["name"] for cpu in cpus_json["cpus"]}
    except urllib.error.HTTPError:
        return {}


if __name__ == "__main__":
    print(get_cpu())
