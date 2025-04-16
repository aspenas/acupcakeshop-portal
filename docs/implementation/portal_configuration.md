---
title: Portal Configuration Guide
date: 2025-04-16
author: Patrick Smith
tags: [portal, configuration, credentials, security]
---

# Portal Configuration Guide

## Overview
This document outlines the configuration for the `portal.acupcake.shop` web portal, which provides a secure, read-only view of our Obsidian vault content. The portal is deployed on DigitalOcean App Platform using a Node.js application.

## Architecture
- **Content Source**: GitHub repository (`aspenas/acupcakeshop-portal`)
- **Application**: Node.js app on DigitalOcean App Platform
- **Authentication**: Google OAuth (restricted to `acupcake.shop` domain)
- **Domain**: `portal.acupcake.shop` (CNAME pointing to DigitalOcean)

## Content Synchronization
To keep the portal's content in sync with the Obsidian vault, we use the `scripts/sync_vault.sh` script, which:
1. Pulls the latest changes from the remote repository
2. Stages all local changes
3. Commits with a timestamped message
4. Pushes to the GitHub repository

This automation ensures that changes made in the Obsidian vault are reflected in the portal.

## Credentials Management

### Secure Credential Storage
All credentials and API keys are stored as environment variables in DigitalOcean App Platform, **not** in the repository files. This provides a secure way to manage sensitive information without exposing it in the codebase.

### Stored Credentials
The following credentials are configured as environment variables:

| Environment Variable | Description | Usage |
|----------------------|-------------|-------|
| MONGO_URI | MongoDB Atlas connection string | Database connection for user data and portal configuration |
| JWT_SECRET | Secret for JWT tokens | Authentication token signing |
| SESSION_SECRET | Secret for session cookies | Session management |
| GOOGLE_CLIENT_ID | Google OAuth client ID | User authentication |
| GOOGLE_CLIENT_SECRET | Google OAuth client secret | User authentication |
| ADOBE_FONTS_TOKEN | Adobe Fonts API token | Font rendering in portal |
| GITHUB_TOKEN | GitHub API token | Content synchronization |
| VERCEL_TOKEN | Vercel API token | Preview deployments |
| VERCEL_TEAM_ID | Vercel team identifier | Preview deployments |
| DIGITALOCEAN_TOKEN | DigitalOcean API token | Infrastructure management |
| ANTHROPIC_API_KEY | Anthropic Claude API key | AI-powered content search and assistance |
| AWS_BEDROCK_ACCESS_KEY | AWS Bedrock access key | Vector embedding and similarity search |
| AWS_BEDROCK_SECRET_KEY | AWS Bedrock secret key | Vector embedding and similarity search |

### Managing Credentials
To update or modify these credentials:

1. Use the DigitalOcean web UI:
   - Navigate to the App Platform console
   - Select the `acupcakeshop-app`
   - Go to Settings > Environment Variables
   - Update the values as needed

2. Or use the DigitalOcean CLI:
   ```bash
   # Create or update app spec with new environment variables
   doctl apps update APP_ID --spec app_spec.yaml
   ```

**Important Security Notes:**
- Never commit credentials directly to the repository
- Rotate credentials periodically
- When sharing credential information, use placeholders instead of actual values

## Deployment Process
The DigitalOcean App Platform is configured to automatically deploy when changes are pushed to the `main` branch of the GitHub repository. This includes both content updates from the Obsidian vault and application code changes.

## Troubleshooting
If the portal isn't displaying the latest content:
1. Check if the `sync_vault.sh` script has been run recently
2. Verify that commits are being pushed to GitHub
3. Check the DigitalOcean deployment logs for errors 