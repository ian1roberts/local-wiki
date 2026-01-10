# Local Wiki

A personal knowledge management system powered by Quarto, supporting both Markdown and Jupyter notebook content with automated publishing via Git.

## Features

- **Quarto-powered**: Build static wiki sites from markdown and Jupyter notebooks
- **Automated Publishing**: Git-based deployment with PowerShell and Bash scripts
- **Notebook Support**: Write wiki entries as interactive Jupyter notebooks
- **Static Site Generation**: Compiled output in the `site/` directory

## Project Structure

- `src/` - Source content and Quarto configuration
  - `wiki/` - Wiki markdown files
  - `notebooks/` - Jupyter notebook entries
  - `_quarto.yml` - Quarto project configuration
- `scripts/` - Automated publishing scripts
- `site/` - Generated static site output

## Development

This project requires Python 3.13+ and Quarto CLI.

### Setup

1. Install dependencies:
   ```sh
   pip install -e .
   ```

2. Preview the site:
   ```sh
   quarto preview src/
   ```

3. Build the site:
   ```sh
   quarto render src/
   ```

### Publishing

Use the provided scripts to publish:
- Windows: `scripts/publish.ps1`
- Unix/Mac: `scripts/publish.sh`

## Development Status

🚧 **In Development** - This project is in active development and may undergo significant changes.