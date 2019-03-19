# Arm Mobile Studio Helper Scripts

This directory contains helper scripts for [Arm Mobile Studio](https://developer.arm.com/mobile-studio), a set of performance analysis tools for developers creating Android applications and interested in performance analysis. For more information refer to the [Quick Start Guide](https://developer.arm.com/mobile-studio/get-started).


## Gatorme

The Streamline profiler, a component of Arm Mobile Studio, uses an on-device daemon, `gatord`, to collect performance data from an Android device and transfer it to a host machine for display and analysis. For non-root Android devices this requires many command line
options to set up, because `gatord` must be run within the security sandbox of
a debuggable application. The helper scripts (`gatorme.bat` for Windows hosts and
`gatorme.sh` for Linux and macOS hosts) wrap all of the command line
options into a single command line utility.

### Command line parameters

The `gatorme` scripts accept three parameters:

1. The package name of the Android APK to be profiled.
2. The name of the Mali GPU in the system, excluding the "Mali-" prefix; e.g.
   `G72` for a system containing a Mali-G72 GPU.
3. The host path to the `gatord` binary to push to the device. This binary can
   be found in the `.\streamline\bin` directory of the Arm Mobile Studio
   installation, with 32-bit and 64-bit variants available. By default the
   script will attempt to use a `gatord` binary in the current working
   directory.

### Prerequisites

1. Make sure the Android Debug Bridge utility `adb` can be accessed from
   your `PATH` environment variable.
2. Confirm your target device is in Developer Mode.
3. Verify your target device is accessible to `adb` running on the host
   machine. Use `adb devices` or `adb shell` to confirm.
4. Ensure that your application's manifest marks it as a `debuggable` build.

### Usage

1. Install the application to be tested to the target device.
2. Run the appropriate version of the `gatorme` script for your host machine
   from a shell terminal. For example:
```
.\gatorme.sh com.arm.test G76 \mobilestudio\streamline\bin\arm64\gatord
```
3. Wait for the following prompt from the script (do not press a key!):
```
Manual step: Capture in Streamline, and then press any key.
Press any key to continue . . .
```
4. Start Streamline and enter `localhost:4242` in the box in the Target tab
5. Optionally click the chip icon to configure or change counters to collect 
6. Click the red dot to start the capture
7. Run the application being profiled
8. Click the Stop button in Streamline to end the capture
9. Once your capture is complete switch back to the console and press any key
   to trigger the clean up steps (this will stop the `gatord` process, remove
   `gatord` and any configuration from the device, and kill the application
   under test).
10. Uninstall the application under test (optional)

Steps 6 and 7 can be reversed to get the application to an interesting point before starting the capture.

**IMPORTANT:** Ensure you press a key and let the script cleanup the device
before uninstalling the application from the device. If you uninstall the
application before the script can kill the `gatord` instance running as the
application's user then `gatord` will become unkillable. In this scenario the
device must be power cycled to close the daemon before any further profiling
can take place.

For an example of how to analyze a Streamline capture refer to [Accelerating Mali GPU analysis using Arm Mobile Studio](https://community.arm.com/developer/tools-software/graphics/b/blog/posts/accelerating-mali-gpu-analysis-using-arm-mobile-studio) on the [Arm Community](https://community.arm.com/).
