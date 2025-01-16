include { COMPUTEMATRIX } from '../../modules/local/deeptools/computeMatrix/main.nf'
include { HEATMAP       } from '../../modules/local/deeptools/heatmap/main.nf'
include { PEAK_STATS    } from '../../modules/local/peakStats/main.nf'

workflow TARGET_PROCESS {
    take:
        target_ch
        wiggle_ch
        blacklist_bed
    
    main:
        signal_target_ch = wiggle_ch
            .combine(target_ch)
            .combine(blacklist_bed)

        COMPUTEMATRIX(signal_target_ch)
        HEATMAP(COMPUTEMATRIX.out.matrix)
        PEAK_STATS(COMPUTEMATRIX.out.matrix)
}