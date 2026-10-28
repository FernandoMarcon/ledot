For every external tool called anywhere in this pipeline, generate a 
parameter report with this structure:

## [Tool Name]
- **Called in:** [which script/rule/process]
- **Version assumed:** [version]
- **Parameters actively set:**
  | Flag | Value | Justification | Impact if changed |
- **Important defaults being relied upon:**
  | Flag | Default value | Why default is appropriate |
- **Parameters deliberately not used:**
  | Flag | Why excluded |
- **Known sensitive parameters** (where small changes significantly 
  affect results):
  | Flag | Current value | Typical range | What it controls |
