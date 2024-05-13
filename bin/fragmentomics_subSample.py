#!/usr/bin/env python

import sys
import subprocess
import argparse
import logging
import csv
from pathlib import Path


_author__    = "Davide Rambaldi"
__copyright__ = "Davide Rambaldi"
__license__   = "MIT"

_logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description="Generate report by sample.")

    parser.add_argument(
        dest="neut",
        help="Neut bam"
    )

    parser.add_argument(
        dest="gain",
        help="Gain bam"
    )

    parser.add_argument(
        dest="counts",
        help="Counts table"
    )

    parser.add_argument(
        "--cpus",
        dest="cpus"
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

    counts_table = Path(args.counts)

    segmented = {}

    with open(counts_table) as csvfile:        
        data = list(csv.reader(csvfile))
        for row in data:
            if len(row) > 0:
                segmented[row[0]] = int(row[1])

    print(segmented)

    minval = min(segmented.values())
    minres = [key for key in segmented if segmented[key] == minval]
    
    maxval = max(segmented.values())
    maxres = [key for key in segmented if segmented[key] == maxval]
    ratio = minval/maxval

    # get file withput path
    neut_bam = Path(args.neut)
    gain_bam = Path(args.gain)

    print(f"maxres: {maxres[0]}")
    # find file to downsize
    if maxres[0] == neut_bam.name:        
        target_file = neut_bam
        copy_file = gain_bam
    elif maxres[0] == neut_bam.name:
        target_file = gain_bam
        copy_file = neut_bam
    else:        
        print("file not found!")
        sys.exit(1)

    output_file = f"{target_file.stem}.subsample.bam"
    output_copy_file = f"{copy_file.stem}.subsample.bam"

    print(f"I will downsample {target_file.absolute()} by {str(ratio)} to output: {output_file}")
    cmd = ["samtools","view","-s",str(ratio),str(target_file.absolute()),"-O","bam","-o",output_file,"-@",args.cpus]
    print(cmd)
    print(f"Copying new file with subsample: {copy_file} to {output_copy_file}")
    copy_cmd = ["cp", str(copy_file.absolute()), output_copy_file]
    print(copy_cmd)
    subprocess.run(cmd)
    subprocess.run(copy_cmd)

if __name__ == "__main__":
    sys.exit(main())