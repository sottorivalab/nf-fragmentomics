process VERSIONS {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    val versions

    output:
    path("versions.yml")

    script:
    """
cat <<-END_VERSIONS > versions.yml
${versions.join("\n")}
END_VERSIONS
    """

    stub:
    """
cat <<-END_VERSIONS > versions.yml
${versions.join("\n")}
END_VERSIONS
    """
}