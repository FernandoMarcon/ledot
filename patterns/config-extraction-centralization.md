Scan the entire project for hardcoded parameters, thresholds, file paths, 
and tool flags. Extract all of them and:
1. List every hardcoded value with its location (file:line)
2. Propose a centralized config structure (YAML) that groups parameters 
   by pipeline stage and tool
3. Refactor the scripts to read from this config instead of using 
   hardcoded values
4. Add validation logic that checks parameter values are within 
   sensible ranges before pipeline execution
