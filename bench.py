#!/usr/bin/env python3

import os
import subprocess
import sys

repo_path = os.path.dirname(os.path.realpath(__file__))

env = os.environ.copy()
env["BENCHMARKS_ENABLED"] = "1"

args = ["swift", "package", "--allow-writing-to-package-directory", "benchmark"] + sys.argv[1:]

result = subprocess.run(args, cwd=repo_path, env=env).returncode
sys.exit(result)
