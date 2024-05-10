#!/usr/bin/env python

import sys
import csv
import argparse
import logging
import re
from pathlib import Path
from rich import print

def parse_args():
    parser = argparse.ArgumentParser(description="Collate timon targets")

    parser.add_argument(
        dest="dirs",
        help="list of target dirs",
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
    tfactors = {}

    for idx, x in enumerate(dirs):
        for mfile in x.glob("*.*"):
            tf = re.sub(r"_.*$","", mfile.stem)
            if tf in tfactors.keys():
                tfactors[tf].append(mfile)
            else:
                tfactors[tf] = [mfile]
 
    for tf, files in tfactors.items():
        destfile = Path(f"{tf}_regions.txt")
        with open(destfile, "a") as dest_fh:
            for mf in files:
                with open(mf,"r") as input_fh:
                    dest_fh.writelines(input_fh.readlines())
                

if __name__ == "__main__":
    sys.exit(main())