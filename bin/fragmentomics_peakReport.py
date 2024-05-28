#!/usr/bin/env python

import sys
import argparse
import logging
import csv
import re
from pathlib import Path

__author__    = "Davide Rambaldi"
__copyright__ = "Davide Rambaldi"
__license__   = "MIT"

_logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description="Generate report by sample.")
    
    parser.add_argument(
        dest="targets",
        help="peak report files.",
        nargs='+',
        type=Path
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
        level=loglevel, stream=sys.stdout, format=logformat, datefmt="%Y-%m-%d %H:%M:%S"
    )


def main():
    args = parse_args()
    setup_logging(args.loglevel)
    report_data = "name\tsource\tploidy\tintegration\tlength\tymin\tymax\tx\tratio\n"
    
    for path in args.targets:
        with open(path) as peak_fh:
            statreader = csv.reader(peak_fh)     
            next(peak_fh)       
            for statrow in statreader:
                report_data += "\t".join(statrow)
                report_data += "\n"

    print(report_data.strip())

if __name__ == "__main__":
    sys.exit(main())
