process FILTER {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path("*.chromosomes.fa.gz"),   path("*.chromosomes.fa.fai"),   path("*.chromosomes.fa.gz.gzi")   , emit: chromosomes,   optional: true
    tuple val(meta), path("*_unmasked.fa.gz"),      path("*_unmasked.fa.fai"),      path("*_unmasked.fa.gz.gzi")      , emit: unmasked,      optional: true
    tuple val(meta), path("*.orig_bgzipped.fa.gz"), path("*.orig_bgzipped.fa.fai"), path("*.orig_bgzipped.fa.gz.gzi") , emit: orig_bgzipped, optional: true
    tuple val(meta), path("*.mitogenome.fa.gz")                                                                       , emit: mitogenome,    optional: true
    tuple val(meta), path("*.contignames.txt")   , emit: contignames
    tuple val(meta), path("*.patterns.txt")      , emit: patterns
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    set +o pipefail
    # Uncompress, save contig names and their description, recompress and index
    zcat $genome | tee >( grep '>' > ${prefix}.contignames.txt) | bgzip --threads $task.cpus --compress-level 9 > ${prefix}.orig_bgzipped.fa.gz
    samtools faidx --fai-idx ${prefix}.orig_bgzipped.fa.fai ${prefix}.orig_bgzipped.fa.gz

    # Keep a record of contig names and 2-letter patterns, to later check:
    # - can expand the grep pattern safely?
    # - does that assembly has sex chromosomes?
    cut -c 1-2 ${prefix}.orig_bgzipped.fa.fai | sort | uniq -c | sort -n > ${prefix}.patterns.txt

    # Keep only complete chromosomes but remove the mitogenome
    sed 's/^>//' ${prefix}.contignames.txt |
        grep -vi mitochondri |
        awk '{print \$1}' |
        grep -E "^(CM|CP|FR|L[R-T]|O[U-Z])" > ${prefix}.contignames.chromosomes.txt ||
        true > /dev/null # Returns success even if list is empty.
    samtools faidx -r ${prefix}.contignames.chromosomes.txt ${prefix}.orig_bgzipped.fa.gz | bgzip --threads $task.cpus --compress-level 9 > ${prefix}.chromosomes.fa.gz

    # Remove output if empty (for some genomes the pattern does match chromosome-level scaffold accession numbers)
    # And otherwise, index, remove soft masks and index again
    if [ -z "\$(zcat ${prefix}.chromosomes.fa.gz | head)" ]
    then
        rm ${prefix}.chromosomes.fa.gz
    else
        samtools faidx --fai-idx ${prefix}.chromosomes.fa.fai ${prefix}.chromosomes.fa.gz
        zcat ${prefix}.chromosomes.fa.gz |
            awk '/^>/ {print \$0; next} {print toupper(\$0)}' |
            bgzip --threads $task.cpus --compress-level 9 > ${prefix}.chromosomes_unmasked.fa.gz
            samtools faidx --fai-idx ${prefix}.chromosomes_unmasked.fa.fai ${prefix}.chromosomes_unmasked.fa.gz
    fi

    # And then extract the mitogenome
    sed 's/^>//' ${prefix}.contignames.txt |
        grep -i mitochondri |
        awk '{print \$1}' |
        samtools faidx -r - ${prefix}.orig_bgzipped.fa.gz | gzip --best --no-name > ${prefix}.mitogenome.fa.gz

    # Remove mitogenome file if containing less or more than one sequence
    [ \$(zcat ${prefix}.mitogenome.fa.gz | grep -c '>') -ne 1 ] && rm ${prefix}.mitogenome.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        local_filter_module: 1.0.0
    END_VERSIONS
    """
}
