#!/usr/bin/env python

import sys
import csv
import argparse
import logging

def parse_args():
    parser = argparse.ArgumentParser(description="Generate samplesheet.csv")
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
            level=loglevel, stream=sys.stdout, format=logformat, datefmt="%Y-%m-%d %H:%M:%S"
            )

def main():
    args = parse_args()
    setup_logging(args.loglevel)
    print(args)

if __name__ == "__main__":
    sys.exit(main())
