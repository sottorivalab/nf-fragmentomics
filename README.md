# NF-FRAGMENTOMICS

## USAGE

### PARAMS


### DEBUG

use `-dump-channels` to see channels.



### DEV NOTES


faToTwoBit /scratch/chela.james/references/Homo_sapiens/GATK/GRCh38/Sequence/WholeGenomeFasta/Homo_sapiens_assembly38.fasta GRCh38.2bit

twoBitInfo GRCh38.2bit GRCh38.sizes



### BLACKLIST IN BAM COVERAGE

Using mappability to bed file

in reference:

```
wiggletools write to_exclude.wig lt .6 GRCh38_full_subset_noalt_nopatch_50.bw
```

```
wig2bed -x < to_exclude.wig > to_exclude.bed
```


```
bamCoverage -b MAYA_12_BL.gc_correct.bam -o MAYA_12_BL.mappability.bw --blackListFileName ../../references/to_exclude.bed
```








cd /home/davide.rambaldi/my_scratch/nf-fragmentomics_sandbox/test_bw_manipulation/test_3

```
wiggletools write GRCh38_full_subset_noalt_nopatch_50.wig  gt .6 GRCh38_full_subset_noalt_nopatch_50.bw
wigToBigWig GRCh38_full_subset_noalt_nopatch_50.wig ../../references/GRCh38.sizes mappability_06.bw
wiggletools write MAYA_12_BL.overlap.wig overlaps mappability_06.bw MAYA_12_BL.bw
wigToBigWig MAYA_12_BL.overlap.wig ../../references/GRCh38.sizes MAYA_12_BL.overlap.bw
```

### MAPPABILITY

/home/davide.rambaldi/my_scratch/nf-fragmentomics_sandbox/test_bw_manipulation/test_2

```
bigWigToBedGraph MAYA_12_BL.bw MAYA_12_BL.bedGraph
```

```
awk '{if ($1 ~ /^chr/) { print $1"\t"$2"\t"$3"\tid-"NR"\t"$4; }}' MAYA_12_BL.bedGraph > MAYA_12_BL.bed
```

```
bigWigAverageOverBed ../../references/GRCh38_full_subset_noalt_nopatch_50.bw MAYA_12_BL.bed MAYA_12_BL.mappability.tab
```

```
cut -f 6 MAYA_12_BL.mappability.tab > mappability_score.out
```

```
paste MAYA_12_BL.bed mappability_score.out > MAYA_12_BL.mappability.bed
```

```
awk '$6 >= 0.6' MAYA_12_BL.mappability.bed > MAYA_12_BL.mappability_filter.bed
```

```
awk '{printf "%s\t%d\t%d\t%d\n", $1,$2,$3,$5}' MAYA_12_BL.mappability_filter.bed > MAYA_12_BL.mappability_filter.bedGraph
```

```
#awk '$1 !~ /_/' MAYA_12_BL.mappability_filter.bedGraph | egrep -v "chrEBV" > MAYA_12_BL.mappability_filter.canonical.bedGraph
```

```
LC_ALL=C sort -k1,1 -k2,2n MAYA_12_BL.mappability_filter.bedGraph > MAYA_12_BL.mappability_filter.sorted.bedGraph
bedGraphToBigWig MAYA_12_BL.mappability_filter.sorted.bedGraph ../../references/GRCh38.sizes MMAYA_12_BL.mappability_filter.sorted.bw
```

