process MITOGENOME {
    tag "$meta.id"
    label 'process_single'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.8.1--h9ee0642_0':
        'biocontainers/seqkit:2.8.1--h9ee0642_0' }"

    input:
    tuple val(meta), path(sequence)

    output:
    tuple val(meta), path("*.{fa,fq}.gz")  , optional:true, emit: filter
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // fasta or fastq. Exact pattern match .fasta or .fa suffix with optional .gz (gzip) suffix
    def suffix = task.ext.suffix ?: "${sequence}" ==~ /(.*f[astn]*a(.gz)?$)/ ? "fa" : "fq"

    """
    seqkit \\
        grep \\
        $args \\
        ${sequence} \\
        -o ${prefix}.mitogenome.${suffix}.gz \\

    # Remove output if empty
    [ -z "\$(zcat ${prefix}.mitogenome.${suffix}.gz | head)" ] && rm ${prefix}.mitogenome.${suffix}.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // fasta or fastq. Exact pattern match .fasta or .fa suffix with optional .gz (gzip) suffix
    def suffix = task.ext.suffix ?: "${sequence}" ==~ /(.*f[astn]*a(.gz)?$)/ ? "fa" : "fq"

    """
    echo "" | gzip > ${prefix}.${suffix}.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit version | sed 's/seqkit v//' )
    END_VERSIONS
    """
}
