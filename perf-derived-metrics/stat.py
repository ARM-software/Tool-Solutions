#!/usr/bin/env python3

import argparse
import math
import os
import re
import subprocess
import sys
from functools import reduce
from operator import add
from typing import Dict

import pandas
import yaml

import midr

# Separator used in perf stat output
PERF_SEPARATOR = ";"
IDENTIFIER_REGEX = re.compile(r"[a-zA-Z_]\w*")


def events_from_formula(formula: str):
    # TODO: Proper parsing...
    return [e for e in re.findall(IDENTIFIER_REGEX, formula)]


def strip_modifier(event_name: str):
    """Convert EVENT_NAME:modifier to EVENT_NAME"""
    if ":" in event_name:
        return event_name.split(":", 1)[0]
    return event_name


def read_perf_stat(filename: str):
    data = []
    with open(filename) as f:
        for line in f.read().splitlines():
            if not line or line.startswith("#"):
                continue
            # e.g. 139198,,BR_PRED:u,800440,100.00,,
            (count_str, _, event, _, _, _, _) = line.split(PERF_SEPARATOR)
            count = math.nan if count_str == "<not counted>" else float(count_str)
            data.append((strip_modifier(event), count))
    return data


def column_name(event: str):
    """Escape event or derived metric name to be evaluated by Pandas"""
    # Pandas support backtick escaping of spaces, but doesn't display nicely - replace with underscore for now
    return event.replace(" ", "_")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", nargs="+")
    parser.add_argument("--events", help='name of derived metric group to collect - e.g. "instruction-mix"')
    parser.add_argument("--cpu", help="CPU name to use to look up event data (auto-detect by default)")
    parser.add_argument("--output", help="Output file for perf data", default="perf.stat.txt")
    parser.add_argument("--group", help="Collect derived metrics in strong groups, ensuring they're collecting simultaneously", action="store_true")
    args = parser.parse_args()

    cpu = args.cpu
    if not cpu:
        cpu = midr.get_cpu()
        if not cpu:
            print("Could not detect CPU. Specify via --cpu")
            sys.exit(1)

    with open(os.path.join("metrics", f"{cpu}.yaml")) as f:
        derived_data = yaml.safe_load(f)
    metrics_data = derived_data["metrics"]

    if not args.events:
        print("No events specified. Options are:\n  " + "\n  ".join(metrics_data.keys()))
        sys.exit(1)

    formulae = metrics_data[args.events]
    positional_formulae = []
    events = []
    print("Collecting derived metrics:")
    for k, v in formulae.items():
        e = [x for x in events_from_formula(v) if x not in formulae.keys()]
        events.append(e)
        positional_formulae += [k] * len(e)
        print(f"    {k} = {v}")
    print()

    if args.group:
        perf_events_str = ",".join(["{%s}" % ",".join(x) for x in events if x])
    else:
        perf_events_str = ",".join(list(set(reduce(add, events))))

    perf_command = ["perf", "stat", "-e", perf_events_str, "-o", args.output, "-x", PERF_SEPARATOR] + args.command
    print('Running "%s"' % " ".join(perf_command))
    print()
    subprocess.check_call(perf_command)
    print()

    stat_data = read_perf_stat(args.output)
    pandas_dict = {}
    locals_for_derived_metric: Dict[str, Dict[str, str]] = {}
    for (index, (event, count)) in enumerate(stat_data):
        if args.group:
            derived_metric = positional_formulae[index]
            locals_for_derived_metric.setdefault(column_name(derived_metric), {})[event] = count
            event = column_name(f"{derived_metric}.{event}")

        pandas_dict[event] = count

    frame = pandas.DataFrame(pandas_dict, index=["Event Data"])
    for k, v in formulae.items():
        locals = {}
        if args.group:
            locals = locals_for_derived_metric.get(column_name(k), {})

            # Replace EVENT with @EVENT so pandas will read local_dict
            def replace_locals(m):
                x = m.group(0)
                if x not in formulae.keys():
                    return "@" + x
                # Leave derivied metrics as-is
                return x

            v = IDENTIFIER_REGEX.sub(replace_locals, v)

        frame.eval(f"{column_name(k)} = {v}", inplace=True, target=frame, local_dict=locals)

    print("Events")
    print(frame[pandas_dict.keys()].transpose())
    print()
    print("Derived Metrics")
    derived = frame[[column_name(k) for k in formulae.keys()]].transpose()
    derived["Formula"] = formulae.values()
    print(derived)
