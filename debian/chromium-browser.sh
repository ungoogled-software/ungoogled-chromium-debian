#!/bin/sh

# Chromium launcher

# Authors:
#  Fabien Tassin <fta@sofaraway.org>
# License: GPLv2 or later

APPNAME=chromium-browser
LIBDIR=/usr/lib/chromium-browser
GDB=/usr/bin/gdb

usage () {
  echo "$APPNAME [-h|--help] [-g|--debug] [options] [URL]"
  echo
  echo "        -g or --debug           Start within $GDB"
  echo "        -h or --help            This help screen"
}

# FFmpeg needs to know where its libs are located
if [ "Z$LD_LIBRARY_PATH" != Z ] ; then
  LD_LIBRARY_PATH=$LIBDIR:$LD_LIBRARY_PATH
else
  LD_LIBRARY_PATH=$LIBDIR
fi
export LD_LIBRARY_PATH

want_debug=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help | -help )
      usage
      exit 0 ;;
    -g | --debug )
      want_debug=1
      shift ;;
    -- ) # Stop option prcessing
      shift
      break ;;
    * )
      break ;;
  esac
done

if [ $want_debug -eq 1 ] ; then
  if [ ! -x $GDB ] ; then
    echo "Sorry, can't find usable $GDB. Please install it."
    exit 1
  fi
  tmpfile=`mktemp /tmp/chromiumargs.XXXXXX` || { echo "Cannot create temporary file" >&2; exit 1; }
  trap " [ -f \"$tmpfile\" ] && /bin/rm -f -- \"$tmpfile\"" 0 1 2 3 13 15
  echo "set args ${1+"$@"}" > $tmpfile
  echo "# Env:"
  echo "#     LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
  echo "$GDB $LIBDIR/$APPNAME -x $tmpfile"
  $GDB "$LIBDIR/$APPNAME" -x $tmpfile
  exit $?
else
  exec $LIBDIR/$APPNAME "$@"
fi

