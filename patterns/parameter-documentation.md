For every tool invocation in this pipeline, add a comment block directly 
above the command that includes:
1. The tool name and version assumption
2. Every flag/parameter being used, with a one-line justification
3. Any important default parameters that are NOT being set, and why 
   we are relying on the default
4. Any parameters that were deliberately excluded and the reasoning

Format example:
# TOOL: BWA-MEM2 v2.2.1
# -t 8         : threads, adjust to available cores
# -M           : mark shorter split hits as secondary (Picard compatibility)
# -R           : read group string, required for downstream GATK
# NOT SET: -k (min seed length) — default of 19 is appropriate for 150bp reads
# EXCLUDED: -a (output all alignments) — would inflate BAM size without benefit for variant calling
