#!/usr/bin/python3
# Wrapper to execute system Node
import sys
import subprocess
import os
if __name__ == '__main__':
    cmd = ['/usr/bin/nodejs'] + sys.argv[1:]
    process = subprocess.Popen(cmd, cwd = os.getcwd(), stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()
    if stderr:
        raise RuntimeError('%s failed: %s' % (cmd, stderr))
