include { BAMPEFRAGMENTSIZE } from '../../modules/local/deeptools/bamPEfragmentSize/main.nf'
include { PLOTCOVERAGE      } from '../../modules/local/deeptools/plotCoverage/main.nf'
include { FILTERBAMBYSIZE   } from '../../modules/local/samtools/filterBamBySize/main.nf'
include { COMPUTEGCBIAS     } from '../../modules/local/deeptools/computeGCbias/main.nf'
include { CORRECTGCBIAS     } from '../../modules/local/deeptools/correctGCbias/main.nf'
include { COVERAGEBAM       } from '../../modules/local/deeptools/coverageBam/main.nf'

workflow BAM_PREPROCESS {

    take:
        bam_ch
        genome_2bit
        blacklist_bed

    main:
        ch_versions = Channel.empty()
        /////////////////////////////////////////////////
        // BAMQC AND FILTER READS BY SIZE
        /////////////////////////////////////////////////
        BAMPEFRAGMENTSIZE(bam_ch)
        PLOTCOVERAGE(bam_ch)
        FILTERBAMBYSIZE(bam_ch)

        /////////////////////////////////////////////////
        // GC CORRECTION
        /////////////////////////////////////////////////
        gc_correct_ch = FILTERBAMBYSIZE.out.filtered
            .combine(genome_2bit)

        COMPUTEGCBIAS(gc_correct_ch)
        CORRECTGCBIAS(COMPUTEGCBIAS.out.freq)

        gc_correct_ch = CORRECTGCBIAS.out.gc_correct
            // remove    freq file from channel
            .map { it ->
                [it[0], it[1], it[2]]
            }
            .combine(blacklist_bed)

        COVERAGEBAM(gc_correct_ch)
        wiggle_ch = COVERAGEBAM.out.bw
        ch_versions = ch_versions.mix(
            BAMPEFRAGMENTSIZE.out.versions.first(),
            PLOTCOVERAGE.out.versions.first(),
            FILTERBAMBYSIZE.out.versions.first(),
            COMPUTEGCBIAS.out.versions.first(),
            CORRECTGCBIAS.out.versions.first(),
            COVERAGEBAM.out.versions.first()
        )

    emit:
        bw = wiggle_ch
        versions = ch_versions

}