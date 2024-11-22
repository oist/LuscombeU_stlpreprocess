# Genome download and pre-processing pipeline

## Introduction

**oist/LuscombeU_stlpreprocess** is a bioinformatics pipeline to …

1. Extract chromosomal scaffolds from the assembly file (discard unplaced, alternate, organelle and plasmid sequences, etc.).
2. Unmask the genome (to be re-masked later by another local pipeline).
3. Extract complete mitochondrial genomes from the assembly file (they might be useful later as an internal control).
4. Summarise the occurence of the first two letters of the accession numbers, to ease future changes of the grepping pattern for whole-chromosome scaffolds.
5. Record the name of the contigs, for instance to check if sex chromosomes are missing from the assembly.
6. Show in the MultiQC report some assembly statistics such as GC content and contig length extracted with the <https://github.com/rpetit3/assembly-scan> software.

After running this pipeline, you can follow with repeat masking using <https://github.com/oist/LuscombeU_stlrepeatmask>.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.tsv`:

```
id	file
genome1	/path/to/genome/file.fastq.gz
genome2	https://url.example.com/to/genome/file.fastq.gz
…
```

Now, you can run the pipeline using:

```bash
nextflow run oist/LuscombeU_stlpreprocess -r master \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.tsv \
   --outdir <OUTDIR>
```

The `-r master` option selects the branch or version of the pipeline.  Alternatives are `-r dev` for the latest version in development or version numbers such as `-r 3.0.0` for instance.

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Resource usage

 - On annelids, `assembly-scan` took a maximum of 2 GB memory.  Filtering is now very lean, using less than 300 MB.  All tasks completed in less than 40 min.

Use the `--assemblyscan_memory` parameter to give more memory to `assembly-scan`.  The
default is `6.GB`.  If not all the genomes are big, let the pipeline first
process the small ones with default parameters, and then run it again with
`-resume` and `--assemblyscan_memory`.

## Pattern and exceptions

The current pattern, `CM|CP|FR|L[R-T]|NC|NZ|O[U-Z]` matches complete chromosome
scaffolds, plasmids and organelles almost exclusively. However there are some exceptions.

 - _Drosophila melanogaster_'s `GCA_000001215` uses `AE` for chromosome scaffolds
   and `CP` for `chrY` and unplaced scaffolds.

## Credits

`oist/LuscombeU_stlpreprocess` was originally written by `@charles-plessy`.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

### [nf-core](https://pubmed.ncbi.nlm.nih.gov/32055031/)

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

### [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/)

> Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. Nextflow enables reproducible computational workflows. Nat Biotechnol. 2017 Apr 11;35(4):316-319. doi: 10.1038/nbt.3820. PubMed PMID: 28398311.

### Pipeline tools

- [Samtools](https://pubmed.ncbi.nlm.nih.gov/19505943/)

  > Li H, Handsaker B, Wysoker A, Fennell T, Ruan J, Homer N, Marth G, Abecasis G, Durbin R; 1000 Genome Project Data Processing Subgroup. The Sequence Alignment/Map format and SAMtools. Bioinformatics. 2009 Aug 15;25(16):2078-9. doi: 10.1093/bioinformatics/btp352. Epub 2009 Jun 8. PMID: 19505943; PMCID: PMC2723002.

- [MultiQC](https://pubmed.ncbi.nlm.nih.gov/27312411/)

  > Ewels P, Magnusson M, Lundin S, Käller M. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics. 2016 Oct 1;32(19):3047-8. doi: 10.1093/bioinformatics/btw354. Epub 2016 Jun 16. PubMed PMID: 27312411; PubMed Central PMCID: PMC5039924.

### Software packaging/containerisation tools

- [Anaconda](https://anaconda.com)

  > Anaconda Software Distribution. Computer software. Vers. 2-2.4.0. Anaconda, Nov. 2016. Web.

- [Bioconda](https://pubmed.ncbi.nlm.nih.gov/29967506/)

  > Grüning B, Dale R, Sjödin A, Chapman BA, Rowe J, Tomkins-Tinch CH, Valieris R, Köster J; Bioconda Team. Bioconda: sustainable and comprehensive software distribution for the life sciences. Nat Methods. 2018 Jul;15(7):475-476. doi: 10.1038/s41592-018-0046-7. PubMed PMID: 29967506.

- [BioContainers](https://pubmed.ncbi.nlm.nih.gov/28379341/)

  > da Veiga Leprevost F, Grüning B, Aflitos SA, Röst HL, Uszkoreit J, Barsnes H, Vaudel M, Moreno P, Gatto L, Weber J, Bai M, Jimenez RC, Sachsenberg T, Pfeuffer J, Alvarez RV, Griss J, Nesvizhskii AI, Perez-Riverol Y. BioContainers: an open-source and community-driven framework for software standardization. Bioinformatics. 2017 Aug 15;33(16):2580-2582. doi: 10.1093/bioinformatics/btx192. PubMed PMID: 28379341; PubMed Central PMCID: PMC5870671.

- [Docker](https://dl.acm.org/doi/10.5555/2600239.2600241)

  > Merkel, D. (2014). Docker: lightweight linux containers for consistent development and deployment. Linux Journal, 2014(239), 2. doi: 10.5555/2600239.2600241.

- [Singularity](https://pubmed.ncbi.nlm.nih.gov/28494014/)

  > Kurtzer GM, Sochat V, Bauer MW. Singularity: Scientific containers for mobility of compute. PLoS One. 2017 May 11;12(5):e0177459. doi: 10.1371/journal.pone.0177459. eCollection 2017. PubMed PMID: 28494014; PubMed Central PMCID: PMC5426675.
