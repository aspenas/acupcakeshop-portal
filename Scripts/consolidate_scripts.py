#!/usr/bin/env python3
# consolidate_scripts.py
# Script consolidation tool for Obsidian vault scripts
# Created: 2025-04-15

import os
import sys
import re
import json
import shutil
import hashlib
from pathlib import Path
import argparse
from typing import Dict, List, Set, Tuple, Optional

# Add lib directory to path for imports
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(str(SCRIPT_DIR / "lib"))

try:
    from logger import VaultLogger
    from config_manager import ConfigManager
    from file_utils import VaultFile, find_files
    from error_handler import ErrorHandler, safe_execution
except ImportError:
    print("Error: Required library modules not found. Please ensure the lib directory is properly set up.")
    sys.exit(1)

# Initialize
logger = VaultLogger("consolidate_scripts")
error_handler = ErrorHandler("consolidate_scripts")
config = ConfigManager("script_consolidation_config.json", "script_consolidation")
VAULT_PATH = os.environ.get("VAULT_PATH", os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Script Database
SCRIPT_DB_PATH = os.path.join(VAULT_PATH, "System/Configuration/script_database.csv")

class ScriptConsolidator:
    """Identifies and consolidates duplicate script functionality"""
    
    def __init__(self, vault_path: str = VAULT_PATH):
        self.vault_path = vault_path
        self.scripts = {}  # Dict to store script info
        self.duplicates = {}  # Dict to store identified duplicates
        self.function_map = {}  # Map of functions across scripts
        self.candidate_groups = []  # Groups of scripts that may be consolidated
        self.consolidated_scripts = {}  # Track consolidated scripts
        self.load_script_database()
    
    def load_script_database(self):
        """Load script database from CSV"""
        try:
            db_file = VaultFile(SCRIPT_DB_PATH)
            content = db_file.read()
            lines = content.strip().split('\n')
            headers = lines[0].split(',')
            
            for line in lines[1:]:  # Skip header
                values = line.split(',')
                script_data = dict(zip(headers, values))
                script_path = script_data.get('Path', '')
                if script_path:
                    self.scripts[script_path] = script_data
            
            logger.info(f"Loaded {len(self.scripts)} scripts from database")
        except Exception as e:
            error_handler.handle_error(f"Error loading script database: {str(e)}")
            
    def analyze_scripts(self):
        """Analyze scripts to identify function definitions and imports"""
        logger.info("Analyzing scripts for functions and imports...")
        
        # Analysis by script type
        for script_path, script_data in self.scripts.items():
            script_type = script_data.get('Type', '').lower()
            
            try:
                script_file = VaultFile(script_path)
                content = script_file.read()
                
                if 'py' in script_type:
                    self._analyze_python_script(script_path, content)
                elif 'sh' in script_type:
                    self._analyze_shell_script(script_path, content)
                elif 'js' in script_type:
                    self._analyze_js_script(script_path, content)
            except Exception as e:
                logger.warning(f"Could not analyze {script_path}: {str(e)}")
    
    def _analyze_python_script(self, script_path: str, content: str):
        """Analyze Python script for functions and imports"""
        # Extract function definitions
        function_pattern = re.compile(r'def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(')
        functions = function_pattern.findall(content)
        
        # Extract class definitions
        class_pattern = re.compile(r'class\s+([a-zA-Z_][a-zA-Z0-9_]*)')
        classes = class_pattern.findall(content)
        
        # Extract imports
        import_pattern = re.compile(r'(?:from\s+([a-zA-Z0-9_.]+)\s+import)|(?:import\s+([a-zA-Z0-9_.]+))')
        imports = []
        for match in import_pattern.finditer(content):
            module = match.group(1) or match.group(2)
            if module:
                imports.append(module)
        
        # Store info
        self.scripts[script_path]['functions'] = functions
        self.scripts[script_path]['classes'] = classes
        self.scripts[script_path]['imports'] = imports
        
        # Update function map
        for func in functions:
            if func not in self.function_map:
                self.function_map[func] = []
            self.function_map[func].append(script_path)
    
    def _analyze_shell_script(self, script_path: str, content: str):
        """Analyze Shell script for functions and imports"""
        # Extract function definitions
        function_pattern = re.compile(r'(?:function\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)')
        functions = function_pattern.findall(content)
        
        # Extract source/imports
        source_pattern = re.compile(r'source\s+["\'](.*?)["\']')
        sources = source_pattern.findall(content)
        
        # Store info
        self.scripts[script_path]['functions'] = functions
        self.scripts[script_path]['imports'] = sources
        
        # Update function map
        for func in functions:
            if func not in self.function_map:
                self.function_map[func] = []
            self.function_map[func].append(script_path)
    
    def _analyze_js_script(self, script_path: str, content: str):
        """Analyze JavaScript script for functions and imports"""
        # Extract function definitions
        function_pattern = re.compile(r'function\s+([a-zA-Z_][a-zA-Z0-9_]*)')
        functions = function_pattern.findall(content)
        
        # Extract arrow functions with names
        arrow_pattern = re.compile(r'const\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:\([^)]*\)|[a-zA-Z_][a-zA-Z0-9_]*)\s*=>')
        arrow_functions = arrow_pattern.findall(content)
        
        # Extract imports
        import_pattern = re.compile(r'(?:import\s+.*?from\s+["\']([^"\']+)["\'])|(?:require\s*\(["\']([^"\']+)["\']\))')
        imports = []
        for match in import_pattern.finditer(content):
            module = match.group(1) or match.group(2)
            if module:
                imports.append(module)
        
        # Store info
        self.scripts[script_path]['functions'] = functions + arrow_functions
        self.scripts[script_path]['imports'] = imports
        
        # Update function map
        for func in functions + arrow_functions:
            if func not in self.function_map:
                self.function_map[func] = []
            self.function_map[func].append(script_path)
    
    def identify_duplicate_functions(self):
        """Identify functions that appear in multiple scripts"""
        logger.info("Identifying duplicate functions across scripts...")
        
        duplicated_functions = {func: scripts for func, scripts in self.function_map.items() if len(scripts) > 1}
        
        # Group scripts by shared functions
        script_groups = {}
        for func, scripts in duplicated_functions.items():
            scripts_tuple = tuple(sorted(scripts))
            if scripts_tuple not in script_groups:
                script_groups[scripts_tuple] = []
            script_groups[scripts_tuple].append(func)
        
        # Convert to list of candidate groups for consolidation
        for scripts, functions in script_groups.items():
            if len(functions) >= 2:  # If they share at least 2 functions
                self.candidate_groups.append({
                    'scripts': list(scripts),
                    'shared_functions': functions,
                    'script_types': self._get_script_types(scripts),
                    'similarity': self._calculate_similarity(scripts)
                })
        
        # Sort by similarity score (descending)
        self.candidate_groups.sort(key=lambda x: x['similarity'], reverse=True)
        
        logger.info(f"Identified {len(self.candidate_groups)} candidate groups for consolidation")
        return self.candidate_groups
    
    def _get_script_types(self, scripts):
        """Get script types for a list of scripts"""
        return {script: self.scripts[script].get('Type', '') for script in scripts}
    
    def _calculate_similarity(self, scripts):
        """Calculate similarity score between scripts"""
        if len(scripts) < 2:
            return 0
        
        # Get all functions from all scripts
        all_functions = set()
        script_functions = {}
        
        for script in scripts:
            functions = set(self.scripts[script].get('functions', []))
            script_functions[script] = functions
            all_functions.update(functions)
        
        # Calculate Jaccard similarity for each pair
        total_similarity = 0
        pair_count = 0
        
        for i, script1 in enumerate(scripts):
            for script2 in scripts[i+1:]:
                fns1 = script_functions[script1]
                fns2 = script_functions[script2]
                
                if not fns1 or not fns2:
                    continue
                
                intersection = len(fns1.intersection(fns2))
                union = len(fns1.union(fns2))
                
                if union > 0:
                    similarity = intersection / union
                    total_similarity += similarity
                    pair_count += 1
        
        return total_similarity / pair_count if pair_count > 0 else 0
    
    def analyze_script_content_similarity(self):
        """Analyze content similarity between scripts"""
        logger.info("Analyzing content similarity between candidate scripts...")
        
        for group in self.candidate_groups:
            scripts = group['scripts']
            script_content = {}
            
            for script in scripts:
                try:
                    script_file = VaultFile(script)
                    content = script_file.read()
                    script_content[script] = content
                except Exception as e:
                    logger.warning(f"Could not read {script}: {str(e)}")
            
            # Calculate content similarity
            content_similarities = {}
            for i, script1 in enumerate(scripts):
                for script2 in scripts[i+1:]:
                    if script1 in script_content and script2 in script_content:
                        similarity = self._content_similarity(
                            script_content[script1], 
                            script_content[script2]
                        )
                        content_similarities[f"{script1}|{script2}"] = similarity
            
            # Add to group data
            group['content_similarities'] = content_similarities
            if content_similarities:
                group['avg_content_similarity'] = sum(content_similarities.values()) / len(content_similarities)
            else:
                group['avg_content_similarity'] = 0
        
        # Re-sort by combined similarity score
        for group in self.candidate_groups:
            group['combined_score'] = (group['similarity'] + group['avg_content_similarity']) / 2
        
        self.candidate_groups.sort(key=lambda x: x['combined_score'], reverse=True)
    
    def _content_similarity(self, text1, text2):
        """Calculate content similarity between two text strings"""
        # Normalize text
        t1 = re.sub(r'\s+', ' ', text1).lower()
        t2 = re.sub(r'\s+', ' ', text2).lower()
        
        # Split into words
        words1 = set(t1.split())
        words2 = set(t2.split())
        
        # Calculate Jaccard similarity
        intersection = len(words1.intersection(words2))
        union = len(words1.union(words2))
        
        return intersection / union if union > 0 else 0
    
    def generate_consolidation_plan(self):
        """Generate a consolidation plan for script groups"""
        logger.info("Generating consolidation plan...")
        
        plans = []
        for i, group in enumerate(self.candidate_groups):
            if group['combined_score'] < 0.3:  # Skip if similarity is too low
                continue
                
            # Identify primary script type
            script_types = list(group['script_types'].values())
            primary_type = max(set(script_types), key=script_types.count)
            
            # Create plan
            plan = {
                'group_id': i,
                'scripts': group['scripts'],
                'shared_functions': group['shared_functions'],
                'primary_type': primary_type,
                'similarity_score': group['combined_score'],
                'consolidated_name': self._suggest_name(group['scripts'], group['shared_functions']),
                'action': 'consolidate' if group['combined_score'] > 0.5 else 'extract_common',
                'estimated_benefit': 'high' if group['combined_score'] > 0.7 else 'medium'
            }
            plans.append(plan)
        
        # Save consolidation plan
        plan_path = os.path.join(VAULT_PATH, "System/Configuration/script_consolidation_plan.json")
        with open(plan_path, 'w') as f:
            json.dump(plans, f, indent=2)
        
        logger.info(f"Generated consolidation plan with {len(plans)} groups")
        return plans
    
    def _suggest_name(self, scripts, functions):
        """Suggest a name for the consolidated script"""
        # Extract name components from script paths
        name_parts = []
        for script in scripts:
            base_name = os.path.basename(script)
            name_without_ext = os.path.splitext(base_name)[0]
            name_parts.extend(name_without_ext.split('_'))
        
        # Count frequency of name parts
        name_counts = {}
        for part in name_parts:
            if len(part) > 3:  # Skip short parts
                name_counts[part] = name_counts.get(part, 0) + 1
        
        # Get common words from function names
        function_words = []
        for func in functions:
            function_words.extend(re.findall(r'[a-z]+', func))
        
        # Find common function words
        func_counts = {}
        for word in function_words:
            if len(word) > 3:  # Skip short words
                func_counts[word] = func_counts.get(word, 0) + 1
        
        # Combine the most frequent name parts and function words
        combined_counts = {**name_counts, **func_counts}
        top_words = sorted(combined_counts.items(), key=lambda x: x[1], reverse=True)[:3]
        
        # Form a name
        suggested_name = '_'.join(word for word, _ in top_words)
        
        # Add suffix based on primary function
        if 'util' not in suggested_name.lower() and any('util' in word.lower() for word, _ in top_words):
            suggested_name += '_utils'
        elif 'helper' not in suggested_name.lower() and any('help' in word.lower() for word, _ in top_words):
            suggested_name += '_helpers'
        
        return suggested_name
    
    def execute_consolidation(self, plan_ids=None, dry_run=True):
        """Execute the consolidation plan"""
        logger.info(f"Executing consolidation plan (dry_run={dry_run})...")
        
        # Load consolidation plan
        plan_path = os.path.join(VAULT_PATH, "System/Configuration/script_consolidation_plan.json")
        try:
            with open(plan_path, 'r') as f:
                plans = json.load(f)
        except Exception as e:
            error_handler.handle_error(f"Error loading consolidation plan: {str(e)}")
            return False
        
        # Filter plans if specific IDs are provided
        if plan_ids:
            plans = [p for p in plans if p['group_id'] in plan_ids]
        
        results = []
        for plan in plans:
            try:
                if plan['action'] == 'consolidate':
                    result = self._consolidate_scripts(plan, dry_run)
                else:  # extract_common
                    result = self._extract_common_functions(plan, dry_run)
                
                results.append({
                    'group_id': plan['group_id'],
                    'success': result['success'],
                    'message': result['message'],
                    'consolidated_path': result.get('consolidated_path', ''),
                    'modified_scripts': result.get('modified_scripts', [])
                })
            except Exception as e:
                error_msg = f"Error consolidating group {plan['group_id']}: {str(e)}"
                logger.error(error_msg)
                results.append({
                    'group_id': plan['group_id'],
                    'success': False,
                    'message': error_msg
                })
        
        # Save results
        results_path = os.path.join(VAULT_PATH, "System/Configuration/script_consolidation_results.json")
        with open(results_path, 'w') as f:
            json.dump(results, f, indent=2)
        
        return results
    
    def _consolidate_scripts(self, plan, dry_run=True):
        """Consolidate scripts into a single script"""
        scripts = plan['scripts']
        target_name = plan['consolidated_name']
        primary_type = plan['primary_type']
        
        logger.info(f"Consolidating scripts: {scripts} -> {target_name}.{primary_type}")
        
        # Determine the target path for the consolidated script
        target_path = os.path.join(VAULT_PATH, "Scripts/lib", f"{target_name}.{primary_type}")
        
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
            
            # 3. Create symbolic links for the original script paths
            for script_path in scripts:
                # Backup original script
                script_file = VaultFile(script_path)
                script_file.backup()
                
                # Create symlink from original script to consolidated script
                try:
                    os.remove(script_path)
                except FileNotFoundError:
                    pass
                
                os.symlink(target_path, script_path)
                
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
    
    def _extract_common_functions(self, plan, dry_run=True):
        """Extract common functions into a shared library"""
        scripts = plan['scripts']
        shared_functions = plan['shared_functions']
        target_name = plan['consolidated_name']
        primary_type = plan['primary_type']
        
        logger.info(f"Extracting {len(shared_functions)} shared functions to {target_name}.{primary_type}")
        
        # Determine the target path for the shared library
        target_path = os.path.join(VAULT_PATH, "Scripts/lib", f"{target_name}.{primary_type}")
        
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
                        for config in self.config.get('script_types', []):
                            if config.get('extension') == script_type:
                                script_type_config = config
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
    
    def generate_report(self):
        """Generate a report of the consolidation process"""
        logger.info("Generating consolidation report...")
        
        # Load plan and results
        plan_path = os.path.join(VAULT_PATH, "System/Configuration/script_consolidation_plan.json")
        results_path = os.path.join(VAULT_PATH, "System/Configuration/script_consolidation_results.json")
        
        try:
            with open(plan_path, 'r') as f:
                plans = json.load(f)
            
            results = []
            if os.path.exists(results_path):
                with open(results_path, 'r') as f:
                    results = json.load(f)
        except Exception as e:
            error_handler.handle_error(f"Error loading plan or results: {str(e)}")
            return False
        
        # Create report markdown
        report = [
            "---",
            "title: Script Consolidation Report",
            f"date: {os.popen('date +%Y-%m-%d').read().strip()}",
            "tags: [system, scripts, consolidation, report]",
            "---",
            "",
            "# Script Consolidation Report",
            "",
            "## Summary",
            "",
            f"- Total candidate groups: {len(plans)}",
            f"- Consolidated scripts: {len([r for r in results if r['success']])}",
            f"- Failed consolidations: {len([r for r in results if not r['success']])}",
            "",
            "## Consolidation Groups",
            ""
        ]
        
        # Add details for each group
        for plan in plans:
            group_id = plan['group_id']
            result = next((r for r in results if r['group_id'] == group_id), None)
            
            report.append(f"### Group {group_id}: {plan['consolidated_name']}")
            report.append("")
            report.append(f"- **Similarity Score**: {plan['similarity_score']:.2f}")
            report.append(f"- **Action**: {plan['action']}")
            report.append(f"- **Scripts**:")
            for script in plan['scripts']:
                report.append(f"  - `{script}`")
            report.append(f"- **Shared Functions**:")
            for func in plan['shared_functions']:
                report.append(f"  - `{func}`")
            
            if result:
                status = "✅ Success" if result['success'] else "❌ Failed"
                report.append(f"- **Status**: {status}")
                report.append(f"- **Message**: {result['message']}")
                if result['success'] and 'consolidated_path' in result:
                    report.append(f"- **Consolidated Path**: `{result['consolidated_path']}`")
            else:
                report.append("- **Status**: ⏳ Pending")
            
            report.append("")
        
        # Write report
        report_path = os.path.join(VAULT_PATH, "Dashboards/System/script_consolidation_report.md")
        with open(report_path, 'w') as f:
            f.write("\n".join(report))
        
        logger.info(f"Generated consolidation report at {report_path}")
        return report_path

@safe_execution
def main():
    parser = argparse.ArgumentParser(description="Script Consolidation Tool")
    parser.add_argument('--analyze', action='store_true', help='Analyze scripts and identify consolidation candidates')
    parser.add_argument('--plan', action='store_true', help='Generate consolidation plan')
    parser.add_argument('--execute', action='store_true', help='Execute consolidation plan')
    parser.add_argument('--report', action='store_true', help='Generate consolidation report')
    parser.add_argument('--group-ids', type=str, help='Comma-separated list of group IDs to consolidate')
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry run without making changes')
    parser.add_argument('--all', action='store_true', help='Run all steps')
    args = parser.parse_args()
    
    # Set defaults if no options specified
    if not any([args.analyze, args.plan, args.execute, args.report, args.all]):
        args.analyze = True
    
    consolidator = ScriptConsolidator()
    
    # Process group IDs
    group_ids = None
    if args.group_ids:
        group_ids = [int(x.strip()) for x in args.group_ids.split(',')]
    
    # Analysis phase
    if args.analyze or args.all:
        logger.info("Starting script analysis...")
        consolidator.analyze_scripts()
        consolidator.identify_duplicate_functions()
        consolidator.analyze_script_content_similarity()
        logger.info("Analysis completed")
    
    # Planning phase
    if args.plan or args.all:
        logger.info("Generating consolidation plan...")
        plan = consolidator.generate_consolidation_plan()
        logger.info(f"Generated plan with {len(plan)} consolidation groups")
    
    # Execution phase
    if args.execute or args.all:
        logger.info(f"Executing consolidation plan (dry_run={args.dry_run})...")
        results = consolidator.execute_consolidation(group_ids, args.dry_run)
        success_count = len([r for r in results if r['success']])
        logger.info(f"Executed {len(results)} consolidations with {success_count} successes")
    
    # Reporting phase
    if args.report or args.all:
        logger.info("Generating consolidation report...")
        report_path = consolidator.generate_report()
        logger.info(f"Generated report at {report_path}")
    
    logger.info("Script consolidation process completed")
    return 0

if __name__ == "__main__":
    sys.exit(main())