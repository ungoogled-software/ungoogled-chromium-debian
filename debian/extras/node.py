#!/usr/bin/python3
# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from os import path as os_path
import platform
import subprocess
import sys
import os


def RunNode(cmd_parts, stdout=None):
  cmd = ['/usr/bin/nodejs'] + cmd_parts
  process = subprocess.Popen(
      cmd, cwd=os.getcwd(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  stdout, stderr = process.communicate()

  # TODO(crbug.com/1098074): Properly handle the returncode of
  # process defined above. Right now, if the process would exit
  # with a return code of non-zero, but the stderr is empty,
  # we would still pass.
  #
  # However, we can't make this change here yet, as there are
  # various presubmit scripts that rely on the runtime error
  # and are unable to handle a `os.exit` call in this branch.
  # These presubmit scripts need to spawn `subprocesses`
  # themselves to handle the exitcode, before we can make the
  # change here.
  if stderr:
    raise RuntimeError('%s failed: %s' % (cmd, stderr))

  return stdout.decode()

if __name__ == '__main__':
  RunNode(sys.argv[1:])
