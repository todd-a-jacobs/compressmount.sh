#!/bin/bash

##
## Name:
##      compressmount.sh
##
## Version:
##      $Format:Git ID: (%h) %ci$
##
## Purpose:
##      Mount a fusecompress filesystem.
##
## Usage:
##      compressmount.sh [-h|-u|-v]
##
## Options:
##      -h = show help
##      -u = unmount
##      -v = show version
##
## Environment Variables:
##     FC_PARENT = parent directory for both compressed backing directory
##                 and uncompressed mountpoint
##     FC_NAME   = name of mountpoint; also used to create hidden
##                 backing directory
##
## Errorlevels:
##     0 = Success
##     1 = Failure
##     2 = Other
##
## Copyright:
##     Copyright (c) 2011 by Todd A. Jacobs <bash_junkie@codegnome.org>
##     All Rights Reserved
##
## License:
##     Released under the GNU General Public License (GPL)
##     http://www.gnu.org/copyleft/gpl.html
##
##     This program is free software; you can redistribute it and/or
##     modify it under the terms of the GNU General Public License as
##     published by the Free Software Foundation; either version 3 of the
##     License, or (at your option) any later version.
##
##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##     General Public License for more details.
##

######################################################################
# Initialization
######################################################################

set -e
set -o pipefail

# Default parent directory for fusecompress backing directory and
# mountpoint. Note that the backing directory containing compressed
# files is called the rootDir in the fusecompress man page.
: "${FC_PARENT:=$HOME/Documents}"

# Default directory name for the fusecompress mountpoint. It is expected
# that the backing directory shares the same name, with a dot prepended.
: "${FC_NAME:=fusecompress}"

######################################################################
# Functions
######################################################################

# Show brief help on usage.
function ShowUsage {
    # Lines of usage information in the documentation section at the
    # top.
    local LINES=1

    # Set display options based on the number of lines.
    local TAB=$'\t'
    if [ $LINES -gt 1 ]; then
        echo "Usage: "
    else
        unset TAB
        echo -n "Usage: "
    fi

    # Display usage information parsed from this file.
    egrep -A ${LINES} "^## Usage:" "$0" | tail -n ${LINES} |
        sed -e "s/^##[[:space:]]*/$TAB/"
    exit 2
}

# Show this program's revision number.
function ShowVersion {
    perl -ne 'print "$1\n" and exit 
        if /^##\s*\$(Revision: \d+\.?\d*)/' "$0"
    exit 2
}

######################################################################
# Process options.
######################################################################
while getopts ":huv" opt; do
    case $opt in
        h)
            # If passed "-h" for help, use egrep to show the help
            # comments designated by an inital double-octothorpe and
            # exit with errorlevel 2.
	    egrep '^##([^#]|$)' $0 | sed -e 's/##//' -e 's/^ //'
            exit 2
            ;;
        u)
	    ACTION=unmount
            ;;
        v)
            ShowVersion
            ;;
        \?)
            ShowUsage
            ;;
    esac # End "case $opt"
done # End "while getopts"

# Shift processed options out of the way.
shift $(($OPTIND - 1))

######################################################################
# Main
######################################################################

# Allow positional parameter to override environment.
[[ -n $1 ]] && FC_NAME="$1"

MOUNTPOINT="${FC_PARENT}/${FC_NAME}"
COMPRESSED_DIRECTORY="${FC_PARENT}/.${FC_NAME}"
if [[ $ACTION == unmount ]]; then
    fusermount -u "$MOUNTPOINT"
    rmdir "$MOUNTPOINT"
    echo "Unmounted: $MOUNTPOINT"
else
    mkdir -p "$COMPRESSED_DIRECTORY" "$MOUNTPOINT"
    fusecompress "$COMPRESSED_DIRECTORY" "$MOUNTPOINT"
    echo "Mounted: $MOUNTPOINT"
fi
