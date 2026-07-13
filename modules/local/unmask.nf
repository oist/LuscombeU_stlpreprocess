process UNMASK {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path("*_unmasked.fa.gz"), emit: unmasked
    tuple val("${task.process}"), val('local_unmask_module'), val("1.0.0"), emit: versions_local_unmask_module, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    set +o pipefail

    zcat ${genome} |
        awk '/^>/ {print \$0; next} {print toupper(\$0)}' |
        bgzip --threads $task.cpus --compress-level 9 > ${prefix}_unmasked.fa.gz
    """
}
