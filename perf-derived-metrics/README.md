Perf Derived Metrics
====================

Demonstration calculating derived metrics from data collected via Linux `perf stat` and formulate stored in per-CPU YAML files.

Code is included to map the CPU to the appropriate data file based on data found in the [Arm data repository](https://github.com/ARM-software/data).

Example data is included for Neoverse N1 CPUs, based on the [Arm Neoverse N1 Performance Analysis Methodology Whitepaper](https://community.arm.com/arm-community-blogs/b/tools-software-ides-blog/posts/arm-neoverse-n1-performance-analysis-methodology).

Usage
-----

See `stat.py --help` for more information.

```
$ pip3 install -r requirements.txt
$ python3 ./stat.py --help
usage: stat.py [-h] [--events EVENTS] [--cpu CPU] [--output OUTPUT] [--group]
               ...

positional arguments:
  command

optional arguments:
  -h, --help       show this help message and exit
  --events EVENTS  name of derived metric group to collect - e.g.
                   "instruction-mix"
  --cpu CPU        CPU name to use to look up event data (auto-detect by
                   default)
  --output OUTPUT  Output file for perf data
  --group          Collect derived metrics in strong groups, ensuring they're
                   collecting simultaneously
```

Example
-------

```
$ pip3 install --upgrade pip
$ pip3 install -r requirements.txt
```

```
$ python3 ./stat.py --events cycle-accounting sleep 1
Collecting derived metrics:
    IPC = INST_RETIRED / CPU_CYCLES
    Frontend Stall Rate = STALL_FRONTEND / CPU_CYCLES
    Backend Stall Rate = STALL_BACKEND / CPU_CYCLES

Running "perf stat -e CPU_CYCLES,STALL_FRONTEND,INST_RETIRED,STALL_BACKEND -o perf.stat.txt -x ; sleep 1"


Events
                Event Data
CPU_CYCLES       1253029.0
STALL_FRONTEND    343336.0
INST_RETIRED     1212873.0
STALL_BACKEND     435881.0

Derived Metrics
                     Event Data                      Formula
IPC                    0.967953    INST_RETIRED / CPU_CYCLES
Frontend_Stall_Rate    0.274005  STALL_FRONTEND / CPU_CYCLES
Backend_Stall_Rate     0.347862   STALL_BACKEND / CPU_CYCLES
```
