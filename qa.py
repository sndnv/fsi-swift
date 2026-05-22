#!/usr/bin/env python3

import os
import platform
import subprocess
import sys

repo_path = os.path.dirname(os.path.realpath(__file__))


def run_command(command, description, cwd=None):
    print("\n>: {}".format(description))
    result = subprocess.run(command, cwd=cwd).returncode
    if result != 0:
        print(">: {} failed with exit code [{}]".format(description, result))
        sys.exit(result)


run_command(
    command=["swiftlint", "lint", "--strict"],
    description="Linting",
    cwd=repo_path,
)

run_command(
    command=["swift", "build"],
    description="Building",
    cwd=repo_path,
)

run_command(
    command=["swift", "test", "--enable-code-coverage"],
    description="Testing",
    cwd=repo_path,
)

if platform.system() == "Darwin":
    profdata = os.path.join(repo_path, ".build/debug/codecov/default.profdata")
    binary = os.path.join(repo_path, ".build/debug/fsiPackageTests.xctest/Contents/MacOS/fsiPackageTests")

    run_command(
        command=[
            "xcrun", "llvm-cov", "report",
            binary,
            "-instr-profile={}".format(profdata),
            "-ignore-filename-regex=.build|Tests",
        ],
        description="Coverage",
        cwd=repo_path,
    )

print("\n>: Done")
