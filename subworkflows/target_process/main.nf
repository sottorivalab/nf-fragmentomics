include { COMPUTEMATRIX } from '../../modules/local/deeptools/computeMatrix/main.nf'
include { HEATMAP       } from '../../modules/local/deeptools/heatmap/main.nf'
include { PEAK_STATS    } from '../../modules/local/peakStats/main.nf'
include { PEAK_COLLECT } from '../../modules/local/peakCollect/main.nf'

process  DEBUG {
    debug true
    
    input:
    tuple val(meta_sample), path(bw), path(blacklist_bed)
    each targets_batch

    output:
    tuple val(meta_sample), val(sources), path("*_matrix.gz"), emit: matrix

    script:
    """
    echo ${targets_batch}
    """

    stub:
    def beds = targets_batch.collect { it[1] }
    def sources = targets_batch.collect { it[0] }
    """
    echo SAMPLE ${meta_sample.sampleid}
    for BED in ${beds.join(' ')} ; do
        BASENAME=\$(basename \${BED} .bed)
        echo BED \${BED}
        echo BASENAME \${BASENAME}
        OUTPUT_FILE=\${BASENAME}_matrix.gz
        touch \${OUTPUT_FILE}
    done    
    """
}

workflow TARGET_PROCESS {
    take:
        target_ch
        wiggle_ch
        blacklist_bed
    
    main:
        ch_versions = Channel.empty()
        signal_target_ch = wiggle_ch
            .combine(blacklist_bed)
        
        DEBUG(signal_target_ch, target_ch)

        // COMPUTEMATRIX(signal_target_ch)
        // HEATMAP(COMPUTEMATRIX.out.matrix)
        // PEAK_STATS(COMPUTEMATRIX.out.matrix)

        // ch_versions = ch_versions.mix(
        //     COMPUTEMATRIX.out.versions,
        //     HEATMAP.out.versions,
        //     PEAK_STATS.out.versions
        // )

        // peak_stats = PEAK_STATS.out.peaks
        //     .map { it ->
        //         it[3]
        //     }
        //     .collect()
            
        // PEAK_COLLECT(peak_stats)
    emit:
        // peaks = PEAK_STATS.out.peaks
        versions = ch_versions
}