process PEAK_COLLECT {
	label 'process_low'

    debug true

    input:
    path 'peaks?.tsv'

    output:
    path("peaks.tsv")

    script:
    """
    head -n 1 peaks1.tsv > peaks.tsv
    for i in *.tsv; do
        tail -n 1 \$i >> peaks.tsv
    done    
    """

    stub:
    """
    for i in *.tsv; do
        ls \$i > peaks.tsv
    done
    """
}