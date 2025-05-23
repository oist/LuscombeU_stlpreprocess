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
include { methodsDescriptionText       } from '../subworkflows/local/utils_nfcore_stlpreprocess_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow STLPREPROCESS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    if (! params.skip_filtering ) {
        FILTERED_FULL ( ch_samplesheet )
        ch_versions = ch_versions.mix(FILTERED_FULL.out.versions)
        ch_filtered = FILTERED_FULL.out.chromosomes.map{id, chr, idx1, idx2 -> [id, chr]}
    } else {
        FILTERED_SKIP ( ch_samplesheet )
        ch_versions = ch_versions.mix(FILTERED_SKIP.out.versions)
        ch_filtered = FILTERED_SKIP.out.unmasked
    }
    ASSEMBLYSCAN  ( ch_filtered )
    ch_versions = ch_versions.mix(ASSEMBLYSCAN.out.versions)
    MULTIQC_ASSEMBLYSCAN_PLOT_DATA ( ASSEMBLYSCAN.out.json.collect{it[1]} ) // https://github.com/nf-core/pairgenomealign/blob/dev/modules/local/multiqc_assemblyscan_plot_data.nf

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(MULTIQC_ASSEMBLYSCAN_PLOT_DATA.out.tsv)
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
