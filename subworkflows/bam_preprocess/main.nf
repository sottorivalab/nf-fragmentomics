workflow BAM_PREPROCESS {

    take:
        sample_ch
        genome_2bit
        blacklist_bed

    main:
        sample_ch.view()

}