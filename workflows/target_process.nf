include { SEGTARGETINTERSECT     } from '../modules/local/segTargetIntersect/main.nf'
include { BIGWIG_AVERAGE_OVERBED } from '../modules/local/ucsc/bigWigAverageOverBed/main.nf'
include { COMPUTEMATRIX          } from '../modules/local/deeptools/computeMatrix/main.nf'
include { HEATMAP                } from '../modules/local/deeptools/heatmap/main.nf'
include { PEAK_REPORT            } from '../modules/local/peakReport/main.nf'

include { PEAK_STATS             } from '../modules/local/peakStats.nf'
include { TARGETPLOT             } from '../modules/local/targetPlot.nf'
include { HOUSEKEEPING_PLOT      } from '../modules/local/houseKeepingPlot.nf'

workflow TARGET_PROCESS {
    take:
    target_ch
    ploidy_ch
    all_bw_ch
    gain_bw_ch
    neut_bw_ch
    loss_bw_ch
    blacklist_bed

    main:
    /////////////////////////////////////////////////
    // TARGET SEGMENTS
    /////////////////////////////////////////////////
    
    if (params.ploidysplit) 
    {
        // combine segments and targets
        target_sample_ploidy_ch = ploidy_ch
            .map{
                [it[0], it[3], it[4], it[5]]        
            }
            .combine(target_ch)
            
        // betools intersect segments and targets
        SEGTARGETINTERSECT(target_sample_ploidy_ch)

        all_targets_ch = SEGTARGETINTERSECT.out.all_targets
            .map { it ->
                [ it[0], it[1], [ type: 'ALL' ], it[2] ]
            }

        gain_targets_ch = SEGTARGETINTERSECT.out.gain_targets
            .map { it ->
                [ it[0], it[1], [ type: 'GAIN' ], it[2] ]
            }

        neut_targets_ch = SEGTARGETINTERSECT.out.neut_targets
            .map { it ->
                [ it[0], it[1], [ type: 'NEUT' ], it[2] ]
            }

        loss_targets_ch = SEGTARGETINTERSECT.out.loss_targets
            .map { it ->
                [ it[0], it[1], [ type: 'LOSS' ], it[2] ]
            }

        // combine bams (ALL) with targets (all)
        all_signal_target_ch = all_bw_ch
            .combine(all_targets_ch, by: 0)
            
        gain_signal_target_ch = gain_bw_ch
            .combine(gain_targets_ch, by: 0)

        neut_signal_target_ch = neut_bw_ch
            .combine(neut_targets_ch, by: 0)

        loss_signal_target_ch = loss_bw_ch
            .combine(loss_targets_ch, by: 0)

        // concat all and filter for size > 0
        signal_target_ch = all_signal_target_ch
            .concat(gain_signal_target_ch, neut_signal_target_ch, loss_signal_target_ch)

        if (workflow.stubRun == false) {
            signal_target_ch = signal_target_ch
                .filter{ it ->
                    it[5].readLines().size() > 1
                }
        }
    }
    else
    {
        signal_target_ch = all_bw_ch
            .combine(target_ch)
            .map{ it ->
                [ it[0], it[1], it[2], it[3], [type: 'ALL'], it[4]]
            }
            .view()

        if (workflow.stubRun == false) {
            signal_target_ch = signal_target_ch
                .filter{ it ->
                    it[5].readLines().size() > 1
                }
        }
    }

    //
    // need to verify if there is signal on targets regions otherwise computeMatrix return:
    // ValueError: need at least one array to concatenate end EXIT STATUS 1
    // because there are no reads on target


    BIGWIG_AVERAGE_OVERBED(signal_target_ch)

    signal_target_filtered_ch = BIGWIG_AVERAGE_OVERBED.out.bwtab
        .filter{ it ->
            def count = 0;
            it[6].eachLine { line ->
                count += line.split("\t")[3].toInteger()
            }
            count > 0
        }
        .map {
            [it[0],it[1],it[2],it[3],it[4],it[5]]
        }        
    
    COMPUTEMATRIX(signal_target_filtered_ch.combine(blacklist_bed))
    HEATMAP(COMPUTEMATRIX.out.matrix)
    PEAK_STATS(COMPUTEMATRIX.out.matrix)
    
    sample_peaks_ch = PEAK_STATS.out.peaks
        .map{ it ->
            [ it[0], it[1], it[2], it[3], it[5] ]
        }
        .groupTuple(by: 0)
        .dump(tag: 'sample_peaks')
    
    // ----- PEAK_STATS.out.peaks ----------
    // [
    //     [caseid:MAYA_12, sampleid:MAYA_12_BL, timepoint:BL], 
    //     [type:NEUT], 
    //     [name:YY1, source:GRIFFIN], 
    //     [type:NEUT], 
    //     /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_peak_data.tsv, 
    //     /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_peak_stats.csv, 
    //     /scratch/davide.rambaldi/nf-fragmentomics_sandbox/work/26/c3e9f55f4b2334f6c0bbbf01370401/MAYA_12_BL_NEUT_YY1_GRIFFIN_PeakIntegration.pdf
    // ]

    // peak report with ./bin/fragmentomics_peakReport.py
    PEAK_REPORT(sample_peaks_ch)

    if (params.multisamples) {
        // GROUP BY TARGET
        // when we have more than one sample (target peak analysis)
        // regroup peak data from different samples by target and target ploidy
        // remove GeneHancer targets
        target_peaks_ch = PEAK_STATS.out.peaks
            .map{ it ->
                [ it[0], it[1], it[2], it[3], it[4] ]
            }
            .groupTuple(by: [2,3])
            .filter{ it ->
                it[2].source != 'GENEHANCER'
            }

        TARGETPLOT(target_peaks_ch)
    }

    /////////////////////////////////////////////////
    // HOUSEKEEPING TSS for ploidy ALL
    /////////////////////////////////////////////////
    
    housekeeping_report_ch = PEAK_STATS.out.peaks
        .filter{ it -> 
            it[2].name == "HouseKeeping" && it[2].source == "GENEHANCER" && it[3].type == "ALL"
        }
        .map{ it ->
            [ it[0], it[4] ]
        }

    random_report_ch = PEAK_STATS.out.peaks
        .filter{ 
            it[2].source == "GENEHANCER" && it[3].type == "ALL" && it[2].name != "HouseKeeping"
        }
        .map {
            [ it[0], it[4]]
        }        

    tss_report_ch = housekeeping_report_ch
        .concat(random_report_ch)
        .groupTuple(by: 0)
        .map{ it ->
            def hk   = it[1].find { el -> el =~ "HouseKeeping" }
            def rand = it[1].findAll { el -> el =~ "rand" }
            return [it[0], hk, rand]
        }

    HOUSEKEEPING_PLOT(tss_report_ch)
    
    // emit:

}