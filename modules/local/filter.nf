process FILTER {
    tag "$meta.id"
    label 'process_single'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.8.1--h9ee0642_0':
        'biocontainers/seqkit:2.8.1--h9ee0642_0' }"

    input:
    tuple val(meta), path(sequence)

    output:
    tuple val(meta), path("*.{fa,fq}.gz")  , emit: filter, optional: true
    tuple val(meta), path("*patterns.txt") , emit: patterns
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // fasta or fastq. Exact pattern match .fasta or .fa suffix with optional .gz (gzip) suffix
    def suffix = task.ext.suffix ?: "${sequence}" ==~ /(.*f[astn]*a(.gz)?$)/ ? "fa" : "fq"

    """
    # Keep only complete chromosomes but remove the mitogenome
    seqkit grep $args $sequence |
        seqkit grep -vnr -p 'itochondri' \\
            -o ${prefix}.${suffix}.gz \\

    # Keep a record of 2-letter patterns, so later check if we can expand the grep pattern safely.
    zcat $sequence | grep '>' | cut -c 2-3 | sort | uniq -c | sort -n > ${prefix}.patterns.txt

    # Remove output if empty (for some genomes the pattern does match chromosome-level scaffold accession numbers)
    [ -z "\$(zcat ${prefix}.${suffix}.gz | head)" ] && rm ${prefix}.${suffix}.gz

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
