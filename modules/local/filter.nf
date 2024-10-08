process FILTER {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_1' :
        'biocontainers/seqtk:1.4--he4a0461_1' }"

    input:
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path("*.chromosomes.fa.gz") , emit: chromosomes, optional: true
    tuple val(meta), path("*_unmasked.fa.gz")    , emit: unmasked, optional: true
    tuple val(meta), path("*.mitogenome.fa.gz")  , emit: mitogenome, optional: true
    tuple val(meta), path("*.patterns.txt")      , emit: patterns
    tuple val(meta), path("*.contignames.txt")   , emit: contignames
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    set +o pipefail
    # Keep a record of contig names and 2-letter patterns, to later check:
    # - can expand the grep pattern safely?
    # - does that assembly has sex chromosomes?
    zcat $genome | grep '>' | tee ${prefix}.contignames.txt | cut -c 2-3 | sort | uniq -c | sort -n > ${prefix}.patterns.txt

    # Keep only complete chromosomes but remove the mitogenome
    sed 's/^>//' ${prefix}.contignames.txt |
        grep -vi mitochondri |
        awk '{print \$1}' |
        grep -E "^(CM|CP|FR|L[R-T]|O[U-Z])" | tee ${prefix}.contignames.chromosomes.txt || true
    seqtk subseq $genome ${prefix}.contignames.chromosomes.txt | gzip --best --no-name > ${prefix}.chromosomes.fa.gz

    # And then extract the mitogenome
    sed 's/^>//' ${prefix}.contignames.txt |
        grep -i mitochondri |
        seqtk subseq $genome - | gzip --best --no-name > ${prefix}.mitogenome.fa.gz

    # Remove mitogenome file if containing less or more than one sequence
    [ \$(zcat ${prefix}.mitogenome.fa.gz | grep -c '>') -ne 1 ] && rm ${prefix}.mitogenome.fa.gz

    # Remove outputs if empty (for some genomes the pattern does match chromosome-level scaffold accession numbers)
    # And then, remove soft masks.
    if [ -z "\$(zcat ${prefix}.chromosomes.fa.gz | head)" ]
    then
        rm ${prefix}.chromosomes.fa.gz
    else
        zcat ${prefix}.chromosomes.fa.gz |
            awk '/^>/ {print \$0; next} {print toupper(\$0)}' |
            gzip --best --no-name > ${prefix}.chromosomes_unmasked.fa.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        local_filter_module: 1.0.0
    END_VERSIONS
    """
}
