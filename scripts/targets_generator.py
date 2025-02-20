#!/usr/bin/env python

import sys
import argparse
import logging
import re
from pathlib import Path

__author__ = "Davide Rambaldi"
__copyright__ = "Davide Rambaldi"
__license__ = "MIT"

_logger = logging.getLogger(__name__)

regexp = re.compile(r"(.*)\..*")

def parse_args():
    """Parse arguments"""
    parser = argparse.ArgumentParser(
        description="Generate targets.csv for nf-fragmentomics pipeline",
        epilog="Author: Davide Rambaldi"
    )

    parser.add_argument(
        dest="files",
        help="Input bed files",
        nargs='+',
        metavar="FILE",
    )

    parser.add_argument(
        "-s",
        "--source",
        dest="source",
        help="Source of the bed files - by default use the parent directory name",
        default=None,
    )

    parser.add_argument(
        "-v",
        "--verbose",
        dest="loglevel",
        help="set loglevel to INFO",
        action="store_const",
        const=logging.INFO,
    )

    parser.add_argument(
        "-vv",
        "--very-verbose",
        dest="loglevel",
        help="set loglevel to DEBUG",
        action="store_const",
        const=logging.DEBUG,
    )

    args = parser.parse_args()
    return args

def setup_logging(loglevel):
    """Setup basic logging

    Args:
      loglevel (int): minimum loglevel for emitting messages
    """
    logformat = "[%(asctime)s] %(levelname)s:%(name)s:%(message)s"
    logging.basicConfig(
        level=loglevel,
        stream=sys.stdout,
        format=logformat,
        datefmt="%Y-%m-%d %H:%M:%S"
    )

def check_files(files):
    """Check files"""
    for file in files:
        _logger.info("Checking file: %s", file)
        if not file.is_file():
            _logger.error("File not found: %s", f)
            return False

        if file.suffix != ".bed":
            _logger.error("File extension not supported: %s", file)
            return False

        return True

def print_targets(files, source):
    """Write targets.csv to stdout"""
    print("name,source,bed")
    for file in files:
        match = regexp.match(file.name)
        name = match.group(1)
        if source is None:
            source = file.parent.name
        file_abs = file.absolute()
        print(f"{name},{source},{file_abs}")


def main():
    """Main function"""
    args = parse_args()
    setup_logging(args.loglevel)

    _logger.info("Generating targets.csv")
    _logger.info("Parser regexp: %s", regexp.pattern)

    if args.source is not None:
        _logger.info("Source: %s", args.source)

    files = [Path(f) for f in args.files]

    if check_files(files):
        _logger.info("Files are ok")
        print_targets(files, args.source)
        _logger.info("Done")
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())