#!/usr/bin/env python

import sys
import csv
import argparse
import logging
from pathlib import Path
from rich import print

def parse_args():
    parser = argparse.ArgumentParser(description="Generate targets.csv")
    
    parser.add_argument(
        "-d",
        '--dirs',
        dest="dirs",
        help="list of target dirs",
        required=True,
        nargs='+'
    )

    parser.add_argument(
        "-s",
        "--sources",
        dest="sources",
        help="List of sources names",
        required=True,
        nargs='+'
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
    
    dirs = [Path(d) for d in args.dirs]
    
    print("name,source,bed")

    for idx, x in enumerate(dirs):
        for mfile in x.glob("*.*"):
            print(f"{mfile.stem.split('.')[0]},{args.sources[idx]},{mfile.absolute()}")
            
    

if __name__ == "__main__":
    sys.exit(main())
