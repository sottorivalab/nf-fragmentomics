process PEAK_COLLECT {
	label 'process_low'

    debug true

    input:
    path 'peaks?.tsv'

    // output:
    // path("peaks.tsv")

    script:
    """
    """

    stub:
    """
    for i in *.tsv; do
        cat \$i
    done
    """
}