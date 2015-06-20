#!/bin/bash

# Pth build script
# Written by Sam Kingston, 2010-2012

# Change this to the path containing pth - leave off a trailing slash.
# Note you probably shouldn't change this, rather just place the current
# script in the same directory as the tarball.
D="./pth-2.0.7-preempt"

# Path to log file that will be written on each build - note this needs to
# be absolute!
LOG="`pwd`/build.log"

# usage message
if [ "$1" = "--help" ] || [ $# -ge 3 ] ; then
    echo "Usage: $0 [--debug] [--extract]"
    echo "(note that the arguments, if present, must be in the specified order)"
    echo
    echo "This script will build the Pth source tree given (located at $D)"
    echo "For the first run, you should use the --extract argument to create the"
    echo "source tree. --debug will enable Pth's debugging support, but will not"
    echo "create a shared library so you will be unable to use LD_LIBRARY_PATH"
    echo "to link against the library at runtime. Instead, link against the static"
    echo "library at compile-time."
    echo
    echo "Build output will be available in ./build.log after running this script."
    exit 1
fi

# version
if [ "$1" = "-v" ] ; then
    echo "version 1.7 - 2012-05-14 15:44"
    echo "(this version supports preemptive Pth)"
    exit 1
fi

# clean the pth build dir
if [ "$1" = "--clean" ] ; then
    set -e
    pushd $D >/dev/null
    make -q clean
    rm -rf bin lib include share doc man $LOG
    popd
    exit 0
fi

# build with debugging supoort (won't create shared library)
if [ "$1" = "--debug" ] ; then
    echo "Will build with debugging -- note that NO shared library will be created!"
    echo "This means you won't be able to use LD_LIBRARY_PATH"
    ARGS="--enable-debug"
    shift
else
    ARGS=""
fi

# extract the archive if needed
if [ "$1" = "--extract" ] ; then
    if [ ! -f "$D.tar.gz" ] ; then
        echo "$D.tar.gz does not exist as a file"
        exit 1
    fi
    if [ -d "$D" ] ; then
        echo "Warning, will remove $D... press a key to confirm (^C to cancel)"
        read
        rm -rf $D || exit 2
    fi
    tar -xzf $D.tar.gz || exit 2
fi

# make sure the directory does exist
if [ ! -d "$D" ] ; then
    echo "Directory $D does not exist. Did you mean to use the --extract argument?"
    exit 2
fi

# make sure the user is specifying the correct version of Pth (preempt)
if [ ! -f "$D/preempt" ] ; then
    echo "You don't seem to be using the preemptive version of Pth. You must download"
    echo "it from the Resources page on the course website and not from any other source."
    exit 3
fi

# last chance before building
echo "Ready to build. Press any key to continue or ^C to cancel"
read

rm -f $LOG

echo "Building, please wait... (any warnings and errors will be printed to screen)"
echo
time (
    pushd $D >>$LOG 2>&1 || exit 3

    rm -f lib/* && \
    make clean >>$LOG 2>/dev/null # this may fail

    # all of the following must succeed
    set -e

    ./configure --prefix=$PWD $ARGS >>$LOG
    make >>$LOG
    make install >>$LOG

    echo
    echo "Build complete. Libraries installed are:"
    ls --color=auto lib/*.{a,so}
    echo "See $LOG for verbose build log"

    popd >>$LOG 2>&1
)
