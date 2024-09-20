#!/usr/bin/env python

import sys
import argparse
import logging
import csv
from pathlib import Path

__author__    = "Davide Rambaldi"
__copyright__ = "Davide Rambaldi"
__license__   = "MIT"

_logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description="Generate report by sample.")

    parser.add_argument(
        dest="seg",
        help="Seg txt ichorCNA file"
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

    seg_file = Path(args.seg)

    gain = []
    neut = []
    loss = []

    with open(seg_file) as csvfile:
        mreader = csv.reader(csvfile, delimiter="\t")
        next(csvfile)
        for row in mreader:
            ploidy = int(row[5])
            data = f"chr{row[1]}\t{row[2]}\t{row[3]}\tchr{row[1]}_{row[2]}_{row[3]}\t{row[5]}"
            if ploidy == 1:
                loss.append(data)
            elif ploidy == 2:                
                neut.append(data)
            elif 3 <= ploidy <= 4:
                gain.append(data)
    
    with open(f"{seg_file.stem}_GAIN.bed", "w") as gain_fh:
        gain_fh.write("\n".join(gain))

    with open(f"{seg_file.stem}_NEUT.bed", "w") as neut_fh:
        neut_fh.write("\n".join(neut))
    
    with open(f"{seg_file.stem}_LOSS.bed", "w") as loss_fh:
        loss_fh.write("\n".join(loss))





if __name__ == "__main__":
    sys.exit(main())