/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ASSEMBLYSCAN                 } from '../modules/nf-core/assemblyscan/main'
include { MULTIQC                      } from '../modules/nf-core/multiqc/main'
include { MULTIQC_ASSEMBLYSCAN_PLOT_DATA} from '../modules/local/multiqc_assemblyscan_plot_data'
include { FILTER     as FILTERED_FULL  } from '../modules/local/filter'
include { UNMASK     as FILTERED_SKIP  } from '../modules/local/unmask'
include { paramsSummaryMap             } from 'plugin/nf-validation'
include { paramsSummaryMultiqc         } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML       } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText       } from '../subworkflows/local/utils_nfcore_luscombeu_stlpreprocess_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LUSCOMBEU_STLPREPROCESS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    if (! params.skip_filtering ) {
        FILTERED_FULL ( ch_samplesheet )
        ch_filtered = FILTERED_FULL.out.chromosomes.map{id, chr, idx1, idx2 -> [id, chr]}
    } else {
        FILTERED_SKIP ( ch_samplesheet )
        ch_filtered = FILTERED_SKIP.out.unmasked
    }
    ASSEMBLYSCAN  ( ch_filtered )
    MULTIQC_ASSEMBLYSCAN_PLOT_DATA ( ASSEMBLYSCAN.out.report.collect{it[1]} ) // https://github.com/nf-core/pairgenomealign/blob/dev/modules/local/multiqc_assemblyscan_plot_data.nf

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'luscombeu_stlpreprocess_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    ch_multiqc_files = ch_multiqc_files.mix(MULTIQC_ASSEMBLYSCAN_PLOT_DATA.out.tsv)
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'luscombeu_stlpreprocess'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
