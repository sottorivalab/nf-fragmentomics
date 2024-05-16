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

    report_data = "name\tsource\ttype\tintegration\tlength\tymin\tymax\tx\tratio\n"
    pattern = r"(?P<sample>.*)_(?P<name>[A-Z]*)_(?P<source>[A-Z]*)_(?P<type>ALL|GAIN|NEUT)_peak_stats$"
    
    for path in args.targets:
        target_data = re.search(pattern, path.stem)
        if target_data is not None:
            with open(path) as peak_fh:
                statreader = csv.reader(peak_fh, delimiter="\t")
                next(peak_fh)
                for statrow in statreader:
                    mdata = "\t".join(statrow)
                    report_data += f"{target_data['name']}\t{target_data['source']}\t{target_data['type']}\t{mdata}\n"

    print(report_data.strip())

if __name__ == "__main__":
    sys.exit(main())
