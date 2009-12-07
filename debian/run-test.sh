#!/bin/sh

# Authors:
#  Fabien Tassin <fta@sofaraway.org>
# License: GPLv2 or later

usage () {
  echo "Usage: "`basename $0`" [-x] [-t sec] test_file log_dir [filter]"
  echo
  echo "        -x               Run test_file under xvfb"
  echo "        -t sec           Timeout in seconds after which we kill the test"
}

timeout=600
want_x=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help | -help )
      usage
      exit 0 ;;
    -t )
      shift
      if [ $# = 0 ] ; then
        echo Error: -t needs an argument
        exit 1
      fi
      timeout=$1
      shift ;;
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
  XVFB="/usr/bin/xvfb-run -a"
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

T1=$(date +%s)
timeout $timeout $XVFB $TEST $FILTER > $LOGDIR/$TEST.txt 2>&1
RET=$?
DELTA=$(expr $(date +%s) - $T1)
echo "# '$RTEST $FILTER' returned with error code $RET (after $DELTA sec)"

if [ $(grep -c 'Global test environment tear-down' $LOGDIR/$TEST.txt) -eq 1 ] ; then
  echo "## Results"
  sed -e '1,/Global test environment tear-down/d' < $LOGDIR/$TEST.txt
else
  if [ $(grep -c ' FAILED  ' $LOGDIR/$TEST.txt) -ne 0 ] ; then
    echo
    echo "## list of FAILED tests:"
    grep '  FAILED  ' $LOGDIR/$TEST.txt
  fi
fi
echo
if [ $RET -ne 0 ] ; then
  echo "=== Logs ==="
  cat $LOGDIR/$TEST.txt
  echo "==== end of logs ==="
  # debug in gdb
  if [ $want_x -eq 1 ] ; then
    GDB="/usr/bin/xvfb-run -a gdb"
  else
    GDB=gdb
  fi
  echo "run $FILTER\necho ------------------------------------------------\\\\n\necho (gdb) bt\\\\n\nbt\n" > /tmp/gdb-cmds-$$.txt
  echo "echo ------------------------------------------------\\\\n\necho (gdb) bt f\\\\n\nbt f\n" >> /tmp/gdb-cmds-$$.txt
  T2=$(date +%s)
  timeout $timeout $GDB -n -batch -x /tmp/gdb-cmds-$$.txt $TEST > $LOGDIR/$TEST--gdb.txt 2>&1
  RET=$?
  DELTA=$(expr $(date +%s) - $T2)
  echo "# '$GDB -n -batch -x /tmp/gdb-cmds-$$.txt $TEST' returned with error code $RET (after $DELTA sec)"
  rm -f /tmp/gdb-cmds-$$.txt
  echo "---- crash logs ----"
  grep -E '^Program received signal' < $LOGDIR/$TEST--gdb.txt
  sed -e '1,/^Program received signal/d' < $LOGDIR/$TEST--gdb.txt
fi
killall -q -v -9 $(basename $TEST)
