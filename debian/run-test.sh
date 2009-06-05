#!/bin/sh

# Authors:
#  Fabien Tassin <fta@sofaraway.org>
# License: GPLv2 or later

usage () {
  echo "Usage: "`basename $0`" [-x] test_file log_dir [filter]"
  echo
  echo "        -x               Run test_file under xvfb"
}

want_x=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help | -help )
      usage
      exit 0 ;;
    -x )
      want_x=1
      shift ;;
    -- ) # Stop option prcessing
      shift
      break ;;
    * )
      break ;;
  esac
done

TEST=$1
LOGDIR=$2
FILTER=$3

if [ "Z$TEST" = "Z" ] ; then
  usage
  exit 1
fi

if  [ "Z$LOGDIR" = "Z" ] ; then
  usage
  exit 1
fi

if [ ! -x $TEST ] ; then
  echo "Error: $TEST must be an executable"
  exit 1
fi

if [ ! -d $LOGDIR ] ; then
  echo "Error: $LOGDIR is not a directory"
  exit 1
fi

if [ $want_x -eq 1 ] ; then
  XVFB="xvfb-run -w 5"
  RTEST="$XVFB $TEST"
else
  XVFB=""
  RTEST=$TEST
fi

if [ "Z$FILTER" != Z ] ; then
  FILTER="--gtest_filter=$FILTER"
  echo "# Running '$RTEST $FILTER' ..."
else
  echo "# Running '$RTEST' ..."
fi

$XVFB $TEST $FILTER > $LOGDIR/$TEST.txt 2>&1
RET=$?
if [ $RET -ne 0 ] ; then
  echo "# '$RTEST' returned with error code $RET"
fi

if [ $(grep -c 'Global test environment tear-down' $LOGDIR/$TEST.txt) -eq 1 ] ; then
  sed -e '1,/Global test environment tear-down/d' < $LOGDIR/$TEST.txt
else
  echo "# last 100 lines only:"
  tail -100 < $LOGDIR/$TEST.txt
  echo "# list of FAILED tests (if any):"
  grep '  FAILED  ' $LOGDIR/$TEST.txt
fi
echo
if [ $RET -eq 139 ] ; then
  # debug in gdb
  if [ $want_x -eq 1 ] ; then
    GDB="xvfb-run -w 5 gdb"
  else
    GDB=gdb
  fi
  echo "run $FILTER\necho ------------------------------------------------\\\\n\necho (gdb) bt\\\\n\nbt\n" > /tmp/gdb-cmds-$$.txt
  echo "echo ------------------------------------------------\\\\n\necho (gdb) bt f\\\\n\nbt f\n" >> /tmp/gdb-cmds-$$.txt
  $GDB -n -batch -x /tmp/gdb-cmds-$$.txt $TEST > $LOGDIR/$TEST--gdb.txt 2>&1
  rm -f /tmp/gdb-cmds-$$.txt
  echo "---- crash logs ----"
  grep -E '^Program received signal' < $LOGDIR/$TEST--gdb.txt
  sed -e '1,/^Program received signal/d' < $LOGDIR/$TEST--gdb.txt
fi
