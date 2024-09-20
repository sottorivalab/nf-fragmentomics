workflow TARGET_PROCESS {
    take:
        target_ch
        sample_ch
        blacklist_bed
    
    main:
        target_ch.view()
}