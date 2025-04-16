---
title: "Script Consolidation Report"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [consolidation, documentation, report, scripts, system]
---

---

---

# Script Consolidation Report

## Summary

- Total candidate groups: 1
- Consolidated scripts: 1
- Failed consolidations: 0

## Consolidation Groups

### Group 0: example_script1_script2

- **Similarity Score**: 0.45
- **Action**: extract_common
- **Scripts**:
  - `/Users/patricksmith/obsidian/acupcakeshop/Scripts/example_script1.py`
  - `/Users/patricksmith/obsidian/acupcakeshop/Scripts/example_script2.py`
  - `/Users/patricksmith/obsidian/acupcakeshop/Scripts/example_script3.py`
- **Shared Functions**:
  - `load_data`
  - `get_timestamp`
- **Status**: ✅ Success
- **Message**: Extracted 2 shared functions to example_script1_script2.py
- **Consolidated Path**: `Scripts/lib/example_script1_script2.py`
