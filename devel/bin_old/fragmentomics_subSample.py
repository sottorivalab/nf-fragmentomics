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
        dest="loss",
        help="Loss bam"
    )

    parser.add_argument(
        dest="counts",
        help="Counts table"
    )

    parser.add_argument(
        "--cpus",
        dest="cpus",
        default=1
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

    minval = min(segmented.values())
    maxval = max(segmented.values())
    ratio = minval/maxval

    minres = [key for key in segmented if segmented[key] == minval]
    therest = [key for key in segmented if segmented[key] != minval]
    
    neut_bam = Path(args.neut)
    gain_bam = Path(args.gain)
    loss_bam = Path(args.loss)

    # get file withput path
    ploidy_bams = {
        neut_bam.name: neut_bam.absolute(),
        gain_bam.name: gain_bam.absolute(),
        loss_bam.name: loss_bam.absolute()
    }
    
    # print(ploidy_bams)
    # print(f"minval: {minval} minres: {ploidy_bams[minres[0]]}")
    # print(f"The rest: {therest}")

    # extract file Path by name.
    source_file = ploidy_bams[minres[0]]
    target_files = dict((k, ploidy_bams[k]) for k in therest if k in ploidy_bams)
    
    s = Path(source_file)
    output_s_file = f"{s.stem}.subsample.bam"
    print(f"Copying new file with subsample: {s} to {output_s_file}")
    copy_cmd = ["cp", str(s.absolute()), output_s_file]
    subprocess.run(copy_cmd)
    # print(copy_cmd)

    for file in target_files:
        p = Path(file)
        output_file = f"{p.stem}.subsample.bam"
        print(f"I will downsample {p.absolute()} by {str(ratio)} to output: {output_file}")
        cmd = [
            "samtools",
            "view",
            "-s",
            str(ratio),
            str(p.absolute()),
            "-O",
            "bam",
            "-o",
            output_file,
            "-@",
            args.cpus
        ]
        # print(cmd)
        subprocess.run(cmd)

if __name__ == "__main__":
    sys.exit(main())