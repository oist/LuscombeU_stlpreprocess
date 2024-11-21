# oist/LuscombeU_stlpreprocess: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v4.0.0 - November 1st, 2024 (Bufo bufo)

 - Replace `seqtk subseq` with `samtools faidx` again for performance on very large genomes.
 - Compress genomes with `bgzip` and index them.
 - Add a `--assemblyscan_memory` parameter to run `assembly-scan` with more memory.

## v3.0.0 - October 8th, 2024 (Chaenocephalus aceratus)

 - Run assemblyscan on the filtered genomes.
 - Allocate only a single CPU for 1 hour with 6 Gb memory for all computations.
 - Collect contig names to better check if sex chromosomes are missing from the assembly, etc.
 - Replace `seqkit` with shell commands and `seqtk` because of memory usage
   (https://github.com/shenwei356/seqkit/issues/487).
   This changes directory and names of output files.

## v2.0.0 - September 24th, 2024 (Lama glama)

 - Allow TSV format and change column names to `id` and `file`.
 - Delete mitogenome files that contain more than one sequence.

## v1.1.0 - September 24th, 2024 (Mus caroli)

 - Expanded the pattern matching chromosome contigs to `^(CM|CP|FR|L[R-T]|O[U-Z])`.

## v1.0.0 - September 20th, 2024 (Orang Outan)

 - Initial release of `oist/LuscombeU_stlpreprocess`, created with the [nf-core](https://nf-co.re/) template.
