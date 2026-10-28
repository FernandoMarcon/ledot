Scan the entire project — all pipeline scripts, sub-pipelines, auxiliary 
scripts, config files, and environment/dependency files (e.g., 
environment.yml, requirements.txt, Dockerfile, modules.config).

Identify every external bioinformatics tool, software package, library, 
and command-line utility that is called, imported, or declared as a 
dependency anywhere in the project.

For each tool found, produce a table with the following columns:
1. **Tool name**
2. **Version** (as specified in the project, or "not pinned" if absent)
3. **Where used** (file:line or rule/process name)
4. **Purpose in this pipeline** (one sentence)
5. **Official documentation URL** (main docs or manual page)
6. **CLI reference / flag reference URL** (if separate from main docs)
7. **Best practices or tutorial URL** (if a widely recognized one exists, 
   e.g., GATK Best Practices, nf-core usage docs)
8. **Publication / citation** (DOI or PubMed link for the tool's paper)

Group the table by pipeline stage (e.g., QC, alignment, variant calling, 
annotation, utilities).

Also include a separate section for:
- Workflow managers (Snakemake, Nextflow, etc.)
- Container/environment tools (Conda, Docker, Singularity)
- Programming language libraries (Python packages, R/Bioconductor packages)

If a tool's version is not pinned in the project, flag it with a warning.
If you are not confident about a URL, say so explicitly rather than 
guessing — mark it as "[VERIFY]" so I can check it manually.
