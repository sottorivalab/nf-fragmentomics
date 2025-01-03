#!/usr/bin/env python

import sys
import csv
import argparse
import logging
import re
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description="Generate samplesheet.csv")
    
    parser.add_argument(
        dest="bams",
        help="Bam files",
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
    logging.basicConfig(level=loglevel, stream=sys.stdout, format=logformat, datefmt="%Y-%m-%d %H:%M:%S")

def main():
    args = parse_args()
    setup_logging(args.loglevel)
    bams = [Path(b) for b in args.bams]
    print("caseid,sampleid,timepoint,bam,bai,seg")
    for bam in bams:
        case_name = bam.parents[3].name
        sample_name = bam.parents[2].name
        timepoint = re.sub(".*[0-9]+_","",sample_name)
        bai_file = Path(str(bam).replace("bam","bai"))
        if not bai_file.is_file():
            bai_file = Path(f"{str(bam)}.bai")
        if not bai_file.is_file():
            print(f"ERROR missing bai file: {bai_file}")
            return 1
        # search for seg file
        low_pass_dir = bam.parents[1]
        seg_file = low_pass_dir / f"ichorcna_1000kb/filter_90_150/{sample_name}.seg"
        if not seg_file.is_file():
            print(f"ERROR missing {seg_file.absolute()}")
            return 1
        print(f"{case_name},{sample_name},{timepoint},{bam.absolute()},{bai_file.absolute()},{seg_file.absolute()}")

if __name__ == "__main__":
    sys.exit(main())
