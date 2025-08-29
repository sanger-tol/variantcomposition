# sanger-tol/variantcomposition: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.1.0](https://github.com/sanger-tol/variantcomposition/releases/tag/0.1.0)] - Laurelin - [2025-08-29]

<!-- Can we use plants' name in Tolkein's world to name the releases? :)
Laurelin was one of the two trees of Valinor, the other being Telperion.
These trees, a gold tree and a silver tree respectively, brought light to the lands before the creation of the Sun and Moon.
-->

Initial release of sanger-tol/variantcomposition, created with the [nf-core](https://nf-co.re/) template version 3.3.1.

### Enhancements & fixes

- Use `Bgzip` to index the VCF files
- Use `VCFtools` to calculate SNP density
- Use `VCFtools` to create InDel-sizes distribution in histogram
- Use `VCFtools` to calculate per-site (base) nucleotide diversity
- Use `BCFtools` to generate ROH
- Use `VCFtools` to calculate heterozygosity
- Use `VCFtools` to calculate allele frequency

### Parameters

This release with the following initial parameters:

| Old parameter | New parameter       |
| ------------- | ------------------- |
|               | --input             |
|               | --include_positions |
|               | --exclude_positions |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference. Only `Docker` or `Singularity` containers are supported, `conda` is not supported.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| Htslib     |             | 1.21        |
| BCFtools   |             | 1.21        |
| VCFtools   |             | 0.1.16      |

<!-- Bgzip and BCFtools are part of SAMtools -->

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.
