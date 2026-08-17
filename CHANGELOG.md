# sanger-tol/variantcomposition: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.2.0](https://github.com/sanger-tol/variantcomposition/releases/tag/0.2.0)] - Telperion - [2025-xx-xx]

### Enhancements & fixes

- Update BCFtools to version 1.22.1
- Use `BCFtools` to produce and plot VCF stats
- Added options to pass parameters to VCFtools and BCFtools
- Support BCF files
- Multiple options to define allele frequencies when computing ROH
- Support multi-sample VCF file
- Can use pre-existing `Tabix` index of the input VCF files

### Parameters

This release with the following initial parameters:

| Old parameter   | New parameter        |
| --------------- | -------------------- |
|                 | --vcftools_filter    |
|                 | --site_pi_filter     |
|                 | --het_filter         |
|                 | --snp_density_filter |
|                 | --af_filter          |
|                 | --indel_len_filter   |
|                 | --roh_filter         |
|                 | --af_tag             |
|                 | --af_default_value   |
| --roh_threshold |                      |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference. Only `Docker` or `Singularity` containers are supported, `conda` is not supported.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| Matplotlib |             | 3.10.6      |
| Tectonic   |             | 0.15.0      |
| Pigz       |             | 2.8         |
| Tar        |             | 1.34        |
| HTSlib     | 1.21        | 1.22.1      |
| BCFtools   | 1.21        | 1.22        |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.

## [[0.1.0](https://github.com/sanger-tol/variantcomposition/releases/tag/0.1.0)] - Laurelin - [2025-09-04]

<!-- Can we use plants' name in Tolkein's world to name the releases? :)
Laurelin was one of the two trees of Valinor, the other being Telperion.
These trees, a gold tree and a silver tree respectively, brought light to the lands before the creation of the Sun and Moon.
-->

Initial release of sanger-tol/variantcomposition, created with the [nf-core](https://nf-co.re/) template version 3.3.1.

### Enhancements & fixes

- Use `Tabix` to index the VCF files
- Use `VCFtools` to calculate SNP density
- Use `VCFtools` to create InDel-sizes distribution in histogram
- Use `VCFtools` to calculate per-site (base) nucleotide diversity
- Use `VCFtools` to calculate heterozygosity
- Use `VCFtools` to calculate allele frequency
- Use `BCFtools` to generate ROH

### Parameters

This release with the following initial parameters:

| Old parameter | New parameter        |
| ------------- | -------------------- |
|               | --input              |
|               | --include_positions  |
|               | --exclude_positions  |
|               | --snp_density_window |
|               | --roh_threshold      |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference. Only `Docker` or `Singularity` containers are supported, `conda` is not supported.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| HTSlib     |             | 1.21        |
| BCFtools   |             | 1.21        |
| VCFtools   |             | 0.1.16      |

<!-- Bgzip and BCFtools are part of SAMtools -->

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.
