import express from 'express';
import obsidianParser from '../utils/obsidianParser.js';

const router = express.Router();

// Get a file from the vault
router.get('/file/*', async (req, res) => {
  try {
    const filePath = req.params[0];
    const content = await obsidianParser.getFile(filePath);
    const { frontmatter, content: parsedContent } = obsidianParser.parseFrontmatter(content);
    
    res.json({
      path: filePath,
      frontmatter,
      content: parsedContent
    });
  } catch (error) {
    res.status(404).json({ error: error.message });
  }
});

// List directory contents
router.get('/dir/*', async (req, res) => {
  try {
    const dirPath = req.params[0] || '';
    const items = await obsidianParser.listDirectory(dirPath);
    
    res.json({
      path: dirPath,
      items
    });
  } catch (error) {
    res.status(404).json({ error: error.message });
  }
});

// Search the vault
router.get('/search', async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({ error: 'Search query is required' });
    }
    
    const results = await obsidianParser.searchFiles(query);
    
    res.json({
      query,
      results
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router; 