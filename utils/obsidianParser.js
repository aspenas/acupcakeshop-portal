import fs from 'fs/promises';
import path from 'path';

// Get the Obsidian vault path from environment variables
const VAULT_PATH = process.env.OBSIDIAN_VAULT_PATH || process.cwd();

/**
 * Get a file from the Obsidian vault
 * @param {string} filePath - Path to the file within the vault
 * @returns {Promise<string>} - File contents
 */
export async function getFile(filePath) {
  try {
    // Ensure the path doesn't try to access files outside the vault
    const normalizedPath = path.normalize(filePath).replace(/^(\.\.(\/|\\|$))+/, '');
    const fullPath = path.join(VAULT_PATH, normalizedPath);
    
    // Check if the file exists
    await fs.access(fullPath);
    
    // Read the file
    const content = await fs.readFile(fullPath, 'utf8');
    return content;
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error);
    throw new Error('File not found or cannot be read');
  }
}

/**
 * List files and directories in a directory
 * @param {string} dirPath - Path to the directory within the vault
 * @returns {Promise<Array>} - Array of files and directories
 */
export async function listDirectory(dirPath) {
  try {
    // Ensure the path doesn't try to access files outside the vault
    const normalizedPath = path.normalize(dirPath).replace(/^(\.\.(\/|\\|$))+/, '');
    const fullPath = path.join(VAULT_PATH, normalizedPath);
    
    // Check if the directory exists
    await fs.access(fullPath);
    
    // Read the directory
    const items = await fs.readdir(fullPath, { withFileTypes: true });
    
    // Map items to objects with name, type, and path
    return items.map(item => ({
      name: item.name,
      type: item.isDirectory() ? 'directory' : 'file',
      path: path.join(dirPath, item.name)
    }));
  } catch (error) {
    console.error(`Error reading directory ${dirPath}:`, error);
    throw new Error('Directory not found or cannot be read');
  }
}

/**
 * Parse frontmatter from markdown content
 * @param {string} content - Markdown content
 * @returns {Object} - Frontmatter object and content without frontmatter
 */
export function parseFrontmatter(content) {
  const frontmatterRegex = /^---\n([\s\S]*?)\n---\n/;
  const match = content.match(frontmatterRegex);
  
  if (!match) {
    return {
      frontmatter: {},
      content
    };
  }
  
  const frontmatterStr = match[1];
  const contentWithoutFrontmatter = content.slice(match[0].length);
  
  // Parse YAML frontmatter into object
  const frontmatter = {};
  const lines = frontmatterStr.split('\n');
  
  for (const line of lines) {
    if (line.trim() === '') continue;
    
    const colonIndex = line.indexOf(':');
    if (colonIndex !== -1) {
      const key = line.slice(0, colonIndex).trim();
      const value = line.slice(colonIndex + 1).trim();
      frontmatter[key] = value;
    }
  }
  
  return {
    frontmatter,
    content: contentWithoutFrontmatter
  };
}

/**
 * Search for files in the vault
 * @param {string} query - Search query
 * @param {Array<string>} extensions - File extensions to search
 * @returns {Promise<Array>} - Array of matching files
 */
export async function searchFiles(query, extensions = ['.md']) {
  const results = [];
  
  async function searchDir(dirPath) {
    const items = await listDirectory(dirPath);
    
    for (const item of items) {
      if (item.type === 'directory') {
        // Skip .git and other hidden directories
        if (!item.name.startsWith('.')) {
          await searchDir(item.path);
        }
      } else if (item.type === 'file') {
        // Check if the file has one of the specified extensions
        const ext = path.extname(item.name).toLowerCase();
        if (extensions.includes(ext)) {
          try {
            const content = await getFile(item.path);
            
            // Simple search: check if the content includes the query
            if (content.toLowerCase().includes(query.toLowerCase())) {
              results.push({
                path: item.path,
                name: item.name,
                excerpt: getExcerpt(content, query)
              });
            }
          } catch (error) {
            console.error(`Error searching file ${item.path}:`, error);
          }
        }
      }
    }
  }
  
  // Start searching from the root
  await searchDir('');
  
  return results;
}

/**
 * Get a short excerpt from content around the query
 * @param {string} content - Content to get excerpt from
 * @param {string} query - Search query
 * @returns {string} - Excerpt
 */
function getExcerpt(content, query) {
  const index = content.toLowerCase().indexOf(query.toLowerCase());
  if (index === -1) return '';
  
  const start = Math.max(0, index - 50);
  const end = Math.min(content.length, index + query.length + 50);
  let excerpt = content.substring(start, end);
  
  // Add ellipsis if needed
  if (start > 0) excerpt = '...' + excerpt;
  if (end < content.length) excerpt = excerpt + '...';
  
  return excerpt;
}

export default {
  getFile,
  listDirectory,
  parseFrontmatter,
  searchFiles
}; 