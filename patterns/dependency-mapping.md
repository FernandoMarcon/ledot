Analyze this project and generate a dependency map showing:
1. Every sub-pipeline/module and what it produces as output
2. What each module expects as input (file format, naming convention, index files)
3. The exact handoff points between modules — what format conversions happen
4. Any implicit dependencies (e.g., a .fai index must exist before samtools view)
5. Which steps can run in parallel vs. which are strictly sequential

Output this as both a text description and a Mermaid diagram.
