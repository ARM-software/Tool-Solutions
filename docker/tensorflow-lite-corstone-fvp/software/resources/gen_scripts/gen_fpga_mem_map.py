# The confidential and proprietary information contained in this file may
# only be used by a person authorised under and to the extent permitted
# by a subsisting licensing agreement from ARM Limited or its affiliates.
#
# (C) COPYRIGHT 2020 ARM Limited or its affiliates.
# ALL RIGHTS RESERVED
#
# This entire notice must be reproduced on all copies of this file
# and copies of this file may only be made by a person if such person is
# permitted to do so under the terms of a subsisting license agreement
# from ARM Limited or its affiliates.

import os
import sys
import ntpath

"""
This file is used as part of post build steps to generate 'images.txt' file
which can be copied over onto the MPS3 board's SD card. The purpose is to
limit having to manually edit the file based on different load regions that
the build scatter file might dictate.
"""

def is_commented(line):
    if (line.startswith(";")):
        return True
    else:
        return False


def is_load_rom(line):
    load_region_specifiers = ['LOAD_ROM', 'LD_ROM', 'LOAD_REGION']

    for load_specifier in load_region_specifiers:
        if line.startswith(load_specifier):
            return True

    return False


def mps3_mappings(application_note: int):
    """
    Returns the FPGA <--> MCC address translations
    as a dict
    """
    # We are basing our map on application note 540
    mmap_mcc_fpga_an540 = {
        # FPGA addr |  MCC addr  |
        "0x00000000": "0x00000000",
        "0x10000000": "0x01000000",

        "0x20000000": "0x02000000",
        "0x30000000": "0x03000000",

        "0x60000000": "0x08000000"
    }

    if application_note == 540:
        return mmap_mcc_fpga_an540

    return {}


def mps3_bin_names(application_note: int):
    """
    Returns expected binary names for the executable built
    for Cortex-M55 or Cortex-M55+Ethos-U55 targets in the
    form of a dict with index and name
    """
    bin_names_540 = {
        0: "itcm.bin",
        1: "dram.bin"
    }
    if application_note == 540:
        return bin_names_540

    return {}


def main(args):
    with open(args[1],'r') as scatter_file:
        line = scatter_file.readline()
        str_list = []
        filename = ntpath.basename(args[1])

        bin_names = None
        mem_map = None
        application_note = 540

        mem_map = mps3_mappings(application_note)
        bin_names = mps3_bin_names(application_note)

        str_list.append("TITLE: Arm MPS3 FPGA prototyping board Images Configuration File\n")
        str_list.append("[IMAGES]\n\n")

        cnt = 0
        while line:
            if not is_commented(line):
                if is_load_rom(line):
                    addr = line.split()[1]

                    if mem_map.get(addr, None) == None:
                        raise RuntimeError(
                            'Translation for this address unavailable')
                    if cnt > len(bin_names):
                        raise RuntimeError(
                            f"bin names len exceeded: {cnt}")

                    str_list.append("IMAGE" + str(cnt) + "ADDRESS: " +
                        mem_map[addr] + " ; MCC@" + mem_map[addr] +
                        " <=> FPGA@"  + addr + "\n")
                    str_list.append("IMAGE" + str(cnt) + "UPDATE: AUTO\n")
                    str_list.append("IMAGE" + str(cnt) + "FILE: \SOFTWARE\\" +
                        bin_names[cnt] + "\n\n")
                    cnt += 1
            line = scatter_file.readline()

        if cnt > 0 and cnt < 33:
            str_list.insert(2,
                "TOTALIMAGES: {} ;Number of Images (Max: 32)\n\n".format(
                    cnt))
        else:
            raise RuntimeError('Invalid image count')

        outpath = args[2]
        if os.path.exists(outpath):
            os.remove(outpath)
        print(''.join(str_list), file=open(outpath, "a"))


if __name__ == "__main__":
    main(sys.argv)
