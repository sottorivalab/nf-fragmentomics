include { COMPUTEMATRIX } from '../../modules/local/deeptools/computeMatrix/main.nf'
include { HEATMAP       } from '../../modules/local/deeptools/heatmap/main.nf'
include { PEAK_STATS    } from '../../modules/local/peakStats/main.nf'
include { PEAK_COLLECT } from '../../modules/local/peakCollect/main.nf'

workflow TARGET_PROCESS {
    take:
        target_ch
        wiggle_ch
        blacklist_bed

    main:
        ch_versions = Channel.empty()
        signal_target_ch = wiggle_ch
            .combine(blacklist_bed)
            .combine(target_ch)

        COMPUTEMATRIX(signal_target_ch)
        HEATMAP(COMPUTEMATRIX.out.matrix)
        PEAK_STATS(COMPUTEMATRIX.out.matrix)

        ch_versions = ch_versions.mix(
            COMPUTEMATRIX.out.versions,
            HEATMAP.out.versions,
            PEAK_STATS.out.versions
        )

        peak_stats = PEAK_STATS.out.peaks
            .map { it ->
                it[3]
            }
            .collect()

        PEAK_COLLECT(peak_stats)

    emit:
        peaks = PEAK_STATS.out.peaks
        versions = ch_versions
}