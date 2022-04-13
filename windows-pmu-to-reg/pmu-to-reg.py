#!/usr/bin/env python3

# Copyright 2022 Arm Limited

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import json
import urllib
from urllib.request import urlopen
import sys

ARM_ARCHITECTURE_ID = 0
BASE_PATH = r"HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\WMI\ProfileSource"
GITHUB_URL = "https://github.com/ARM-software/data"
NEWLINE_PLACEHOLDER = " +//0 "


def reg_path(*path_components):
    return "[%s]" % "\\".join(path_components)


def reg_dword(key, value):
    return '"%s"=dword:%s' % (key, format(value, "08x"))


def reg_comment(comment):
    return "\n".join(["; " + x for x in comment.split(NEWLINE_PLACEHOLDER)])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate registry file for aarch64 PMU events")
    parser.add_argument("cpu", help='CPU to read PMU events for - e.g. "neoverse-n1". See %s for more information' % GITHUB_URL)
    parser.add_argument("output", help="output (.reg) file for the PMU event data")
    args = parser.parse_args()

    # Fetch PMU events
    json_data_url = "%s/raw/HEAD/pmu/%s.json" % (GITHUB_URL, args.cpu)
    json_github_url = "%s/blob/HEAD/pmu/%s.json" % (GITHUB_URL, args.cpu)
    pmu_tree_url = "%s/tree/HEAD/pmu" % GITHUB_URL
    try:
        root = json.load(urlopen(json_data_url))
    except urllib.error.HTTPError:
        print('Could not fetch PMU data for CPU "%s". See %s for available CPUs' % (args.cpu, pmu_tree_url), file=sys.stderr)
        sys.exit(1)

    events = root["events"]

    # Write to registry file
    with open(args.output, "w", newline="\r\n") as f:
        def output(s=""):
            print(s, file=f)

        output("Windows Registry Editor Version 5.00")
        output()
        output(reg_comment("WMI profile source data for %s hardware PMU events." % args.cpu))
        output(reg_comment("Generated from %s" % json_github_url))
        output()
        output(reg_path(BASE_PATH, args.cpu))
        output(reg_dword("Architecture", ARM_ARCHITECTURE_ID), )
        output()

        for e in events:
            if e["name"] != "CHAIN":  # Skip CHAIN meta-event
                output(reg_path(BASE_PATH, args.cpu, e["name"]))
                output(reg_comment(e["description"]))
                output(reg_dword("Event", e["code"]))
                output()
