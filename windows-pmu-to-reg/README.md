
Script to expose Arm Performance Monitoring Unit (PMU) events to the [Windows Management Instrumentation (WMI)](https://docs.microsoft.com/en-us/windows/win32/wmisdk/wmi-start-page) system.

A Microsoft Windows registry file is generated for the specified CPU. Once imported, the PMU events will be available to the WMI system, and can be collected via tools such as [Windows Performance Recorder](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/windows-performance-recorder).

PMU event information is sourced from the [Arm Data repository](https://github.com/ARM-software/data). For event descriptions, see comments in the registry file, or the technical reference manual for your CPU on the [Arm Developer website](developer.arm.com).

Usage
=====
```
usage: pmu-to-reg.py [-h] cpu output

Generate registry file for aarch64 PMU events

positional arguments:
  cpu         CPU to read PMU events for - e.g. "neoverse-n1". See https://github.com/ARM-software/data/ for more information
  output      output (.reg) file for the PMU event data

optional arguments:
  -h, --help  show this help message and exit
```
Where CPU corresponds to a CPU filename in the [Arm Data repository](https://github.com/ARM-software/data/tree/master/pmu) - e.g.

    $ python pmu-to-reg.py neoverse-n1 events.reg

Collecting PMU events with Windows Performance Recorder
=======================================================

### Import event data

    regedit events.reg

### Reboot

Reboot your system for the changes to take effect.

### Verify events

Verify that Windows Performance Recorder is now aware of the new events.

```
wpr -pmcsources
Id  Name                        Interval  Min      Max
--------------------------------------------------------------
  0 Timer                          10000  1221    1000000
...
 73 ASE_SPEC                       65536  4096 2147483647
 74 BR_IMMED_RETIRED               65536  4096 2147483647
 75 BR_INDIRECT_SPEC               65536  4096 2147483647
 ...
```

### Create Windows Performance Recorder profile

[Create a WPR profile](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/authoring-recording-profiles) to specify which events to collect.

[Example.wprp](Example.wprp) shows a profile named "PMC" that collects events for L1 cache analysis:
* ``INST_RETIRED``
* ``L1I_CACHE_REFILL``
* ``L1I_CACHE``
* ``L1D_CACHE_REFILL``
* ``L1D_CACHE``

### Collect a profile

Using an administrator Command Prompt or PowerShell:

Start recording:

    wpr -start Example.wprp!PMC

and later stop recording:

    wpr -stop cache.etl

### Analyse results

e.g. by converting to a CSV file

    xperf -i cache.etl -o cache.csv

See the "Pmc" data rows.
