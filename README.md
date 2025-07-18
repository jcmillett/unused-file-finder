# Unused File Finder

A powerful bash script that helps identify unreferenced files in your codebase. This tool is particularly useful for maintaining clean codebases by finding files that are no longer being used or imported anywhere in your project.

## What It Does

The `find-unreferenced.sh` script analyzes your codebase to identify files of a specific type that are not referenced anywhere in your project. It performs the following steps:

1. **Scans** your codebase directory for all files of the specified type
2. **Excludes** common build/dependency directories (node_modules, dist, automation, ng-mobile)
3. **Filters out** test files (*.spec.* files)
4. **Searches** the entire codebase for references to these files
5. **Generates** detailed reports showing which files are unreferenced

## Use Cases

- **Code cleanup**: Identify dead code and unused components
- **Bundle optimization**: Find unreferenced assets that increase bundle size
- **Refactoring**: Safely remove unused files during code refactoring
- **Code auditing**: Get insights into which parts of your codebase are actively used

## System Requirements

This script works on **Unix-like systems** including:
- **macOS** (tested)
- **Linux** distributions
- **Windows** with WSL (Windows Subsystem for Linux)

### Dependencies

The script requires the following tools to be installed:

1. **ripgrep** (`rg`) - Fast text search tool
2. **python3** - For data processing and analysis

## Installation & Setup

### 1. Install Dependencies

#### On macOS (using Homebrew):
```bash
brew install ripgrep python3
```

#### On Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install ripgrep python3
```

#### On Linux (CentOS/RHEL/Fedora):
```bash
# For newer versions with dnf
sudo dnf install ripgrep python3

# For older versions with yum
sudo yum install ripgrep python3
```

### 2. Clone the Repository
```bash
git clone https://github.com/jcmillett/unused-file-finder.git
cd unused-file-finder
```

### 3. Make the Script Executable
```bash
chmod +x find-unreferenced.sh
```

## Usage

```bash
./find-unreferenced.sh <codebase-dir> <output-dir> <file-type>
```

### Parameters

- `<codebase-dir>`: Path to your project's source code directory
- `<output-dir>`: Directory where analysis results will be saved
- `<file-type>`: File extension to analyze (without the dot)

## Examples

### Example 1: Find Unreferenced JSP Files
```bash
./find-unreferenced.sh /path/to/my-project ./jsp-results jsp
```

### Example 2: Find Unreferenced JavaScript Files
```bash
./find-unreferenced.sh ~/projects/my-app ./js-results js
```

### Example 3: Find Unreferenced CSS Files
```bash
./find-unreferenced.sh /home/user/website ./css-results css
```

### Example 4: Analyze Current Directory
```bash
./find-unreferenced.sh . ./temp-results jsx
```

## Output Files

The script generates four detailed report files in your specified output directory:

1. **`all-files.txt`** - Complete list of all found files with full paths
2. **`filenames.txt`** - Just the filenames (without paths)
3. **`references.txt`** - All found references to the files in your codebase
4. **`unreferenced-files.txt`** - List of files that have no references (these may be safe to remove)

## Sample Output

```
📁 Codebase directory: ./src
🗂️ Output directory:   ./results
📄 File type:          ts

🔍 Finding all .ts files...
📄 Found 45 .ts files
🪓 Extracting just file names...
🔎 Searching codebase for references to .ts files...
📎 Found 127 references to .ts files
📊 Comparing and identifying unreferenced .ts files...

Duplicate file names found: 0
Searched File Names: 45
Referenced Files: 38
Unreferenced Files: 7

Unreferenced .ts files:
  • old-util.ts
  • deprecated-service.ts
  • temp-component.ts
  • unused-helper.ts
  • legacy-model.ts
  • test-data.ts
  • backup-config.ts

✅ Analysis complete!
📄 All .ts files: ./results/all-files.txt
📝 Filenames: ./results/filenames.txt
🔗 References found: ./results/references.txt
🗑️ Unreferenced files: ./results/unreferenced-files.txt
```

## Excluded Directories

The script automatically excludes the following directories from analysis:
- `node_modules/` - Package dependencies
- `dist/` - Build output
- `automation/` - Automation scripts
- `ng-mobile/` - Angular mobile builds

## File Exclusions

- Test files matching the pattern `*.spec.*` are automatically excluded from the unreferenced files list

## Important Notes

⚠️ **Before deleting files**: Always review the results carefully! A file might appear "unreferenced" but could be:
- Dynamically imported at runtime
- Used in configuration files
- Required by external tools
- Referenced in a way the script doesn't detect
