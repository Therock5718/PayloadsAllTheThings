# Deployment Guide

This repository uses MkDocs Material to generate and deploy documentation to GitHub Pages.

## Automatic Deployment

The repository is configured for automatic deployment through GitHub Actions. When changes are pushed to the `master` branch, the workflow automatically:

1. Checks out the repository
2. Sets up Python and installs dependencies
3. Builds the documentation using MkDocs
4. Deploys to GitHub Pages

## Prerequisites

To enable automatic deployment, ensure:

1. **GitHub Pages is enabled** in repository settings:
   - Go to Settings > Pages
   - Source should be set to "Deploy from a branch"
   - Branch should be set to `gh-pages`

2. **GitHub Actions has write permissions**:
   - Go to Settings > Actions > General
   - Under "Workflow permissions", select "Read and write permissions"

## Manual Deployment

To deploy manually or test locally:

### Local Testing

```bash
# Install dependencies
pip install mkdocs-material
pip install mkdocs-git-revision-date-localized-plugin
pip install mkdocs-git-committers-plugin
pip install mkdocs-material[imaging]
pip install mdx_truly_sane_lists

# Serve locally (preview at http://127.0.0.1:8000)
mkdocs serve

# Build the site
mkdocs build
```

### Manual Deployment to GitHub Pages

```bash
# Deploy to GitHub Pages
mkdocs gh-deploy --force
```

## Workflow File

The deployment workflow is located at `.github/workflows/mkdocs-build.yml`.

## Configuration

The MkDocs configuration is in `mkdocs.yml` at the repository root. Key settings:

- `site_url`: The URL where the site will be published
- `repo_url`: The repository URL
- `theme`: Material theme configuration
- `custom_dir`: Custom theme overrides directory

## Troubleshooting

If deployment fails:

1. Check GitHub Actions logs for error messages
2. Verify all dependencies are installed correctly
3. Ensure the `gh-pages` branch exists and has proper permissions
4. Confirm GitHub Pages is enabled in repository settings

## Site URL

After deployment, the site will be available at:
`https://Therock5718.github.io/PayloadsAllTheThings`
