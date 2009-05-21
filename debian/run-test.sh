#!/bin/sh

TEST=$1
LOGDIR=$2

if [ "Z$TEST" = "Z" ] ; then
  echo "Usage: $0 test_file logdir"
  exit 1
fi

if  [ "Z$LOGDIR" = "Z" ] ; then
  echo "Usage: $0 test_file logdir"
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

debug() {
  echo "run\nbt\nbt f\n" > /tmp/gdb-cmds-$$.txt
  gdb -n -batch -x /tmp/gdb-cmds-$$.txt $TEST > $LOGDIR/$TEST--gdb.txt 2>&1
  rm -f /tmp/gdb-cmds-$$.txt
}

echo "# Running '$TEST' ..."
$TEST > $LOGDIR/$TEST.txt 2>&1
RET=$?
if [ $RET -ne 0 ] ; then
  echo "# '$TEST' returned with error code $RET"
fi

if [ $(grep -c 'Global test environment tear-down' $LOGDIR/$TEST.txt) -eq 1 ] ; then
  sed -e '1,/Global test environment tear-down/d' < $LOGDIR/$TEST.txt
else
  echo "# last 100 lines only:"
  tail -100 < $LOGDIR/$TEST.txt
fi

if [ $RET -eq 139 ] ; then
  debug
  echo "---- crash logs ----"
  grep -E '^Program received signal' < $LOGDIR/$TEST--gdb.txt
  sed -e '1,/^Program received signal/d' < $LOGDIR/$TEST--gdb.txt
fi
