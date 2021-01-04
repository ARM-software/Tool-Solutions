#!/bin/bash
#
# Copyright 2019 ARM Limited.
# All rights reserved.
#

set -e
set -u
set -o pipefail

tmpfile=$(mktemp /tmp/run.XXX)

cleanup() {
    rm -fr "$tmpfile"
}

#trap cleanup 0

# Use -h for command line options
usage() {
	echo "Usage: $0 [-u --use-case] Select the use case to run on the Corstone-300 FVP. Valid options are (img_class, micro_speech)" 1>&2
	echo "          [-h --help] prints help message" 1>&2
	exit 1
}

# Allow the script to be called from another location using an absolute path
mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All of the functionality is in a common script
includepath=$mydir

# Compiled SystemC executable, unique to this system
# shellcheck disable=SC2034
SIM="$mydir/models/Linux64_GCC-6.4/FVP_Corstone_SSE-300_Ethos-U55"

# Get the args
use_case=
args=$(getopt -o u:hx -l use-case:,help -n "$(basename "$0")" -- "$@")
eval set -- "$args"
while [ $# -gt 0 ]; do
  if [ -n "${opt_prev:-}" ]; then
    eval "$opt_prev=\$1"
    opt_prev=
    shift 1
    continue
  elif [ -n "${opt_append:-}" ]; then
    eval "$opt_append=\"\${$opt_append:-} \$1\""
    opt_append=
    shift 1
    continue
  fi
  case $1 in

  -h | --help)
    usage
    exit 0
    ;;

  -u | --use-case)
    # Example of option with an following argument
    opt_prev=use_case
    ;;

  -x)
    set -x
    ;;

  --)
    shift
    break 2
    ;;
    esac
    shift 1
    done

# Run the simulation
# We capture the stdout/stderr into a temporary file whilst showing them in the
# console. tee cannot be piped because it will not pass all the variables to
# the rest of the script
# shellcheck source=../../../../_/common/scripts/fm_run.sh
#. "$includepath/fm-run.sh" > >(tee "$tmpfile") 2>&1
time=
if [ "$use_case" == "img_class" ]; then
	time=200
else
	time=10
fi

$SIM -a ~/software/exe/$use_case/$use_case.axf -T $time -C cpu0.CFGITCMSZ=14 -C cpu0.CFGDTCMSZ=14 -C mps3_board.telnetterminal0.start_telnet=0 -C mps3_board.uart0.out_file="-"  | (tee uart0.log) 2>&1

# Import post processing and common script
# shellcheck source=_common/scripts/resources/common/utils.sh
. "$mydir/resources/common/utils.sh"

# shellcheck source=_common/scripts/resources/app_name/post_processing.sh
. "$mydir/resources/$use_case/post_processing.sh"

printf "Post process data from simulation output\n"
post_process_output "$use_case" uart0.log
