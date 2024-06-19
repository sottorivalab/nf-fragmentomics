include { SEGTARGETINTERSECT } from '../modules/local/segTargetIntersect.nf'
include { COMPUTEMATRIX      } from '../modules/local/computeMatrix.nf'
include { HEATMAP            } from '../modules/local/heatmap.nf'
include { PEAK_STATS         } from '../modules/local/peakStats.nf'
include { PEAK_REPORT        } from '../modules/local/peakReport.nf'
include { TARGETPLOT         } from "../modules/local/targetPlot.nf"

workflow TARGET_PROCESS {
    take:
    target_ch
    ploidy_ch
    all_bw_ch
    gain_bw_ch
    neut_bw_ch
    loss_bw_ch

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
                    it[5].size() > 0 
                }
        }
    }
    else
    {
        // target_ch.view()
        signal_target_ch = all_bw_ch
            .combine(target_ch)
            .map{ it ->
                [ it[0], it[1], it[2], it[3], [type: 'ALL'], it[4]]
            }
    }
    
    COMPUTEMATRIX(signal_target_ch)
    HEATMAP(COMPUTEMATRIX.out.matrix)
    PEAK_STATS(COMPUTEMATRIX.out.matrix)
    
    sample_peaks_ch = PEAK_STATS.out.peaks
        .map{ it ->
            [ it[0], it[1], it[2], it[3], it[5] ]
        }
        .groupTuple(by: 0)
        .dump(tag: 'sample_peaks')
        .view()
    
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
    // HOUSEKEEPING TSS
    /////////////////////////////////////////////////
    // TODO
    // housekeeping_report_ch = PEAK_STATS.out.peaks
    //     .filter{ it ->
    //         it[2].source == "GENEHANCER"
    //     }
    //     .view()

    // emit:

}