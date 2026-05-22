#!/usr/bin/env python3

import argparse
import logging
import re
import semver
import subprocess
import sys

DESCRIPTION = ('Computes the next release version from existing git tags, '
               'and creates a new tag for it')

TAG_PATTERN = re.compile(r'^v(\d+\.\d+\.\d+)$')


def require_no_changes():
    build_result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
    output = build_result.stdout.split('\n') + build_result.stderr.split('\n')
    output = list(filter(None, output))

    if len(output) == 0:
        logging.debug('No changes found in repo')
    else:
        logging.error('Release failed - uncommitted changes found in repo [\n    {}\n]'.format('\n    '.join(output)))
        sys.exit(1)


def get_current_version():
    result = subprocess.run(['git', 'tag', '--list'], capture_output=True, text=True)
    if result.returncode != 0:
        logging.error('Release failed - could not list git tags')
        sys.exit(1)

    versions = []
    for line in result.stdout.split('\n'):
        match = TAG_PATTERN.match(line.strip())
        if match:
            versions.append(semver.Version.parse(match.group(1)))

    if not versions:
        logging.debug('No existing version tags found, starting from 0.0.0')
        return '0.0.0'

    current = str(max(versions))
    logging.debug('Loaded current version [{}] from git tags'.format(current))
    return current


def get_next_version(current_version, next_version):
    current = semver.Version.parse(current_version)

    next = {
        'patch': current.bump_patch(),
        'minor': current.bump_minor(),
        'major': current.bump_major(),
    }.get(next_version.lower())

    return str(next or semver.Version.parse(next_version))


def exec_git_command(command):
    if subprocess.run(command).returncode == 0:
        logging.debug('Executed git command [{}]'.format(' '.join(command)))
    else:
        logging.error('Release failed - could not execute git command [{}]'.format(' '.join(command)))
        sys.exit(1)


def create_tag(next_version):
    exec_git_command(command=['git', 'tag', 'v{}'.format(next_version)])


def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)

    parser.add_argument(
        '-n', '--next',
        required=False,
        default='patch',
        help='select next release version; can be either one of [major|minor|patch] or an explicit version (ex: 1.5.0)'
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='enable debug logging'
    )

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)-15s] [%(levelname)s] [%(name)-5s]: %(message)s',
        level=logging.getLevelName(logging.DEBUG if args.verbose else logging.INFO)
    )

    require_no_changes()

    current_version = get_current_version()
    next_version = get_next_version(current_version=current_version, next_version=args.next)

    logging.info('Releasing [{}] -> [{}]'.format(current_version, next_version))

    create_tag(next_version=next_version)


if __name__ == '__main__':
    main()
