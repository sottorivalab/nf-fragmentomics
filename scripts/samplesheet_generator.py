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

regexp = re.compile(r"((.*)_(.*))\..*")

def parse_args():
    """Parse arguments"""

    parser = argparse.ArgumentParser(
        description="Generate samplesheet.csv for nf-fragmentomics pipeline",
        epilog="Author: Davide Rambaldi"
    )
    
    parser.add_argument(
        dest="files",
        help="Bam or wiggle files",
        nargs='+',
        metavar="FILE",
    )

    parser.add_argument(
        "-r",
        "--regexp",
        dest="regexp",
        default=regexp,
        metavar="REGEXP",
        help=f"Parser regexp - default: {regexp.pattern}"
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
    """Check if files exist"""
    for file in files:
        _logger.info(f"Checking file: {file}")
        if not file.is_file():
            _logger.error(f"File not found: {file}")
            return False

        if file.suffix not in ['.bam','.bw']:
            _logger.error(f"Invalid file extension: {file}")
            return False
        
        if file.suffix  == '.bam':
            bai_file = Path(f"{str(file)}.bai")            
            if not bai_file.is_file():
                _logger.error(f"Missing bai file: {bai_file}")
                return False
            
    return True

def write_samplesheet(files):
    """Write samplesheet.csv"""
    with open("samplesheet.csv","w") as f:
        f.write("caseid,sampleid,timepoint,bam,bai,bw\n")
        for file in files:
            match = regexp.match(file.name)
            sampleid = match.group(1)
            caseid = match.group(2)
            timepoint = match.group(3)

            _logger.info(
                f"Writing file: {file},\n"
                f"Suffix: {file.suffix},\n"
                f"Name: {file.name},\n"
                f"Match: {match} - sampleid={sampleid} caseid={caseid} timepoint={timepoint}\n"
            )

            file_abs = Path.cwd() / file.name
            if file.suffix == '.bam':
                bai_abs = Path.cwd() / f"{file.name}.bai"
                f.write(f"{caseid},{sampleid},{timepoint},{file_abs},{bai_abs},\n")
            else:
                f.write(f"{caseid},{sampleid},{timepoint},,,{file_abs}\n")
       


def main():
    """Main function"""
    args = parse_args()
    setup_logging(args.loglevel)
    
    _logger.info("Generating samplesheet.csv")
    _logger.info("Parser regexp: %s", regexp)

    files = [Path(f) for f in args.files]
    
    _logger.info("Checking files")

    if check_files(files):
        _logger.info("Files are ok")
        write_samplesheet(files)
        _logger.info("Done")
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
