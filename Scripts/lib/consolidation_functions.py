#!/usr/bin/env python3
# consolidation_functions.py
# Improved implementation of script consolidation functions
# Created: 2025-04-15

import os
import sys
import re
from datetime import datetime
import shutil
import glob

# Add lib directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(SCRIPT_DIR)
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(SCRIPT_DIR, "../..")))
sys.path.append(PARENT_DIR)

try:
    from lib.logger import VaultLogger
    from lib.file_utils import VaultFile
    logger = VaultLogger("consolidation_functions")
except ImportError:
    import logging
    logger = logging.getLogger("consolidation_functions")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler()
    logger.addHandler(handler)

def consolidate_scripts(scripts, target_name, primary_type, vault_path, dry_run=True):
    """Consolidate multiple scripts into a single script"""
    logger.info(f"Consolidating scripts: {scripts} -> {target_name}.{primary_type}")
    
    # Determine the target path for the consolidated script
    target_path = os.path.join(vault_path, "Scripts/lib", f"{target_name}.{primary_type}")
    
    if dry_run:
        return {
            'success': True,
            'message': f"Would consolidate {len(scripts)} scripts into {target_name}.{primary_type}",
            'consolidated_path': f"Scripts/lib/{target_name}.{primary_type}",
            'modified_scripts': scripts
        }
    
    try:
        # 1. Extract all imports and function definitions from source scripts
        all_imports = set()
        all_functions = {}
        main_functions = {}
        script_descriptions = {}
        
        for script_path in scripts:
            try:
                script_file = VaultFile(script_path)
                content = script_file.read()
                
                if content:
                    # Get script description from comments
                    description_match = re.search(r'^#\s*(.*?)$', content, re.MULTILINE)
                    if description_match:
                        script_name = os.path.basename(script_path)
                        script_descriptions[script_name] = description_match.group(1).strip()
                    
                    # Extract imports
                    import_matches = re.findall(r'^import\s+([^\n]+)', content, re.MULTILINE)
                    from_import_matches = re.findall(r'^from\s+([^\s]+)\s+import\s+([^\n]+)', content, re.MULTILINE)
                    
                    for imp in import_matches:
                        all_imports.add(f"import {imp}")
                    
                    for module, items in from_import_matches:
                        all_imports.add(f"from {module} import {items}")
                    
                    # Extract function definitions (excluding main)
                    func_pattern = re.compile(r'def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^)]*\):[^\n]*(?:\n\s+[^\n]*)*', re.MULTILINE)
                    for match in func_pattern.finditer(content):
                        func_def = match.group(0)
                        func_name = match.group(1)
                        
                        if func_name != 'main':
                            if func_name not in all_functions:
                                all_functions[func_name] = {
                                    'definition': func_def,
                                    'sources': [script_path]
                                }
                            else:
                                all_functions[func_name]['sources'].append(script_path)
                        else:
                            script_name = os.path.basename(script_path)
                            main_functions[script_name] = func_def
            except Exception as e:
                logger.warning(f"Error processing {script_path}: {str(e)}")
        
        # 2. Create the consolidated script
        consolidated_content = [
            "#!/usr/bin/env python3",
            f"# {target_name}.{primary_type}",
            "# Consolidated script created by script_consolidation.py",
            f"# Created: {datetime.now().strftime('%Y-%m-%d')}",
            "# Original scripts:",
        ]
        
        # Add original script descriptions
        for script_name, description in script_descriptions.items():
            consolidated_content.append(f"# - {script_name}: {description}")
        
        consolidated_content.append("")
        
        # Add imports
        consolidated_content.extend(sorted(all_imports))
        consolidated_content.append("")
        
        # Helper function for resolving conflicts
        consolidated_content.append("def _script_name_from_argv0():")
        consolidated_content.append("    \"\"\"Get the script name from sys.argv[0] for dispatching\"\"\"")
        consolidated_content.append("    import os")
        consolidated_content.append("    return os.path.basename(sys.argv[0])")
        consolidated_content.append("")
        
        # Add function definitions (sorted by name)
        for func_name in sorted(all_functions.keys()):
            func_data = all_functions[func_name]
            definition = func_data['definition']
            sources = func_data['sources']
            
            # Add source comment if function comes from multiple scripts
            if len(sources) > 1:
                source_scripts = [os.path.basename(s) for s in sources]
                consolidated_content.append(f"# Function from: {', '.join(source_scripts)}")
            
            consolidated_content.append(definition)
            consolidated_content.append("")
        
        # Add main function dispatcher
        consolidated_content.append("def main():")
        consolidated_content.append("    \"\"\"Main function dispatcher based on script name\"\"\"")
        consolidated_content.append("    script_name = _script_name_from_argv0()")
        
        # Handle different script names
        for script_name, main_def in main_functions.items():
            # Extract main function body (everything after the first line and indented)
            main_body = re.sub(r'^def\s+main\s*\([^)]*\):[^\n]*\n', '', main_def)
            main_body = re.sub(r'^    ', '        ', main_body, flags=re.MULTILINE)
            
            consolidated_content.append(f"    if script_name == '{script_name}':")
            consolidated_content.append(f"        # {script_descriptions.get(script_name, 'Main function')}")
            consolidated_content.append(main_body)
        
        # Add default case
        consolidated_content.append("    else:")
        consolidated_content.append("        print(f\"Unknown script name: {script_name}\")")
        consolidated_content.append("        print(f\"Available scripts: {', '.join(list(main_functions.keys()))}\")")
        consolidated_content.append("        return 1")
        consolidated_content.append("")
        
        # Add script execution code
        consolidated_content.append("if __name__ == \"__main__\":")
        consolidated_content.append("    sys.exit(main())")
        consolidated_content.append("")
        
        # Write the consolidated file
        consolidated_text = "\n".join(consolidated_content)
        lib_file = VaultFile(target_path)
        lib_file.write(consolidated_text)
        
        # Make the consolidated file executable
        os.chmod(target_path, 0o755)
        
        # 3. Create import stubs for the original script paths
        for script_path in scripts:
            # Backup original script
            script_file = VaultFile(script_path)
            script_file.backup()
            
            # Create import stub instead of symlink
            script_name = os.path.basename(script_path)
            stub_content = [
                "#!/usr/bin/env python3",
                f"# {script_name} - Import stub for consolidated script",
                "# This file redirects to the consolidated implementation",
                "",
                "import os",
                "import sys",
                "",
                "# Add lib directory to path",
                "SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))",
                "LIB_DIR = os.path.join(SCRIPT_DIR, \"lib\")",
                "sys.path.append(LIB_DIR)",
                "",
                f"# Import consolidated script: {os.path.basename(target_path)}",
                f"from {os.path.splitext(os.path.basename(target_path))[0]} import *",
                "",
                "# Execute main function if run directly",
                "if __name__ == \"__main__\":",
                "    sys.exit(main())"
            ]
            
            # Write import stub
            with open(script_path, 'w') as f:
                f.write('\n'.join(stub_content))
            
        return {
            'success': True,
            'message': f"Consolidated {len(scripts)} scripts into {target_name}.{primary_type}",
            'consolidated_path': f"Scripts/lib/{target_name}.{primary_type}",
            'modified_scripts': scripts
        }
        
    except Exception as e:
        error_msg = f"Failed to consolidate scripts: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'message': error_msg
        }

def extract_common_functions(scripts, shared_functions, target_name, primary_type, vault_path, config=None, dry_run=True):
    """Extract common functions into a shared library"""
    logger.info(f"Extracting {len(shared_functions)} shared functions to {target_name}.{primary_type}")
    
    # Determine the target path for the shared library
    target_path = os.path.join(vault_path, "Scripts/lib", f"{target_name}.{primary_type}")
    
    if dry_run:
        return {
            'success': True,
            'message': f"Would extract {len(shared_functions)} shared functions to {target_name}.{primary_type}",
            'consolidated_path': f"Scripts/lib/{target_name}.{primary_type}",
            'modified_scripts': scripts
        }
    
    try:
        # 1. Extract function definitions and necessary imports from source scripts
        extracted_content = {}
        all_imports = set()
        
        for script_path in scripts:
            try:
                script_file = VaultFile(script_path)
                content = script_file.read()
                
                if content:
                    # Extract imports
                    import_matches = re.findall(r'^import\s+([^\n]+)', content, re.MULTILINE)
                    from_import_matches = re.findall(r'^from\s+([^\s]+)\s+import\s+([^\n]+)', content, re.MULTILINE)
                    
                    for imp in import_matches:
                        all_imports.add(f"import {imp}")
                    
                    for module, items in from_import_matches:
                        all_imports.add(f"from {module} import {items}")
                    
                    # Extract function definitions
                    for func_name in shared_functions:
                        # Look for function definition
                        func_pattern = re.compile(f"def\\s+{func_name}\\s*\\([^)]*\\):[^\\n]*(?:\\n\\s+[^\\n]*)*", re.MULTILINE)
                        func_match = func_pattern.search(content)
                        
                        if func_match and func_name not in extracted_content:
                            func_def = func_match.group(0)
                            extracted_content[func_name] = func_def
            except Exception as e:
                logger.warning(f"Error processing {script_path}: {str(e)}")
        
        # 2. Create the shared library file
        library_content = [
            "#!/usr/bin/env python3",
            f"# {target_name}.{primary_type}",
            f"# Shared functions extracted from scripts by consolidation tool",
            f"# Created: {datetime.now().strftime('%Y-%m-%d')}",
            ""
        ]
        
        # Add imports
        filtered_imports = [imp for imp in all_imports if not any(func in imp for func in shared_functions)]
        library_content.extend(sorted(filtered_imports))
        library_content.append("")
        
        # Add function definitions
        for func_name in shared_functions:
            if func_name in extracted_content:
                library_content.append(extracted_content[func_name])
                library_content.append("")
        
        # Write the library file
        lib_file = VaultFile(target_path)
        library_text = "\n".join(library_content)
        lib_file.write(library_text)
        
        # Make the library file executable
        os.chmod(target_path, 0o755)
        
        # 3. Update the original scripts to import from the new library
        for script_path in scripts:
            try:
                script_file = VaultFile(script_path)
                content = script_file.read()
                
                if content:
                    # Determine script type to set correct import pattern
                    script_type = os.path.splitext(script_path)[1]
                    
                    # Find appropriate script_type configuration
                    script_type_config = None
                    if config and 'script_types' in config:
                        for script_config in config['script_types']:
                            if script_config.get('extension') == script_type:
                                script_type_config = script_config
                                break
                    
                    # Set default import pattern if no config found
                    import_pattern = "from {module} import {functions}"
                    if script_type_config:
                        import_pattern = script_type_config.get('import_pattern', import_pattern)
                    
                    # Add path setup if needed
                    path_setup = ""
                    if not re.search(r'SCRIPT_DIR\s*=\s*os\.path\.dirname', content):
                        path_setup = "\n# Add lib directory to path\n"
                        path_setup += "SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))\n"
                        path_setup += "LIB_DIR = os.path.join(SCRIPT_DIR, \"lib\")\n"
                        path_setup += "sys.path.append(LIB_DIR)\n"
                    
                    # Ensure os and sys are imported
                    if 'import os' not in content:
                        content = re.sub(r'(import [^\n]+)', r'import os\n\1', content, 1)
                    if 'import sys' not in content:
                        content = re.sub(r'(import [^\n]+)', r'import sys\n\1', content, 1)
                    
                    # Add path setup
                    if path_setup:
                        import_block_end = re.search(r'((?:^import|\s+import|^from|\s+from)[^\n]+\n)+', content).end()
                        content = content[:import_block_end] + path_setup + content[import_block_end:]
                    
                    # Format import statement
                    functions_str = ", ".join(shared_functions)
                    module_name = os.path.basename(target_name)
                    import_statement = import_pattern.format(module=module_name, functions=functions_str)
                    
                    # Add import statement
                    import_position = re.search(r'(?:import|from)[^\n]*\n\s*\n', content).end()
                    content = content[:import_position] + f"\n# Import from shared library\n{import_statement}\n" + content[import_position:]
                    
                    # Remove original function definitions
                    for func_name in shared_functions:
                        func_pattern = re.compile(f"def\\s+{func_name}\\s*\\([^)]*\\):[^\\n]*(?:\\n\\s+[^\\n]*)*", re.MULTILINE)
                        content = func_pattern.sub('', content)
                    
                    # Clean up empty lines
                    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
                    
                    # Write updated script
                    script_file.write(content)
                    
            except Exception as e:
                logger.warning(f"Error updating {script_path}: {str(e)}")
        
        return {
            'success': True,
            'message': f"Extracted {len(shared_functions)} shared functions to {target_name}.{primary_type}",
            'consolidated_path': f"Scripts/lib/{target_name}.{primary_type}",
            'modified_scripts': scripts
        }
        
    except Exception as e:
        error_msg = f"Failed to extract common functions: {str(e)}"
        logger.error(error_msg)
        return {
            'success': False,
            'message': error_msg
        }