#!/bin/bash

# Ensure script exits on first failure
set -e

# -----------------------
# Check for required dependencies
# -----------------------
check_dependencies() {
    local missing_deps=()
    
    # Check for ripgrep (rg)
    if ! command -v rg &> /dev/null; then
        missing_deps+=("ripgrep")
    fi
    
    # Check for python3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the following:"
        
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "ripgrep")
                    echo "  • ripgrep (rg): brew install ripgrep"
                    echo "    Alternative: https://github.com/BurntSushi/ripgrep#installation"
                    ;;
                "python3")
                    echo "  • python3: brew install python3"
                    echo "    Alternative: https://www.python.org/downloads/"
                    ;;
            esac
        done
        
        echo ""
        echo "After installing dependencies, please run the script again."
        exit 1
    fi
}

# Check dependencies before proceeding
check_dependencies

# -----------------------
# Parse input arguments
# -----------------------
USAGE="Usage: $0 <codebase-dir> <output-dir> <file-type>"

if [ "$#" -ne 3 ]; then
  echo "$USAGE"
  exit 1
fi

CODE_DIR="$1"
OUT_DIR="$2"
FILE_TYPE="$3"

# Validate that the codebase directory exists
if [ ! -d "$CODE_DIR" ]; then
    echo "❌ Error: Codebase directory '$CODE_DIR' does not exist."
    echo "Please provide a valid directory path."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Define output files
ALL_FILES_FILE="$OUT_DIR/all-files.txt"
FILENAMES_FILE="$OUT_DIR/filenames.txt"
REFERENCES_FILE="$OUT_DIR/references.txt"
UNREFERENCED_FILE="$OUT_DIR/unreferenced-files.txt"

echo "📁 Codebase directory: $CODE_DIR"
echo "🗂️ Output directory:   $OUT_DIR"
echo "📄 File type:          $FILE_TYPE"

# -----------------------
# Step 1: Find all .$FILE_TYPE files (excluding node_modules and dist)
# -----------------------
echo "🔍 Finding all .$FILE_TYPE files..."

find "$CODE_DIR" \
  -type f -name "*.$FILE_TYPE" \
  -not -name "*.spec.$FILE_TYPE" \
  -not -path "*/node_modules/*" \
  -not -path "*/automation/*" \
  -not -path "*/ng-mobile/*" \
  -not -path "*/target/*" \
  -not -path "*/dist/*" > "$ALL_FILES_FILE"

# Check if any files were found
if [ ! -s "$ALL_FILES_FILE" ]; then
    echo "❌ No .$FILE_TYPE files found in '$CODE_DIR'"
    echo "Please verify that the codebase directory contains .$FILE_TYPE files."
    exit 1
fi

FILE_COUNT=$(wc -l < "$ALL_FILES_FILE")
echo "📄 Found $FILE_COUNT .$FILE_TYPE files"

# -----------------------
# Step 2: Extract just file names
# -----------------------
echo "🪓 Extracting just file names..."
sed -E 's|.*/||' "$ALL_FILES_FILE" > "$FILENAMES_FILE"

# -----------------------
# Step 3: Search codebase for references to files (excluding node_modules and dist)
# -----------------------
echo "🔎 Searching codebase for references to .$FILE_TYPE files..."

# Clear the references file first
> "$REFERENCES_FILE"

# Use ripgrep to search for file references
if rg -Ff "$FILENAMES_FILE" "$CODE_DIR" --no-ignore \
   --glob '!**/node_modules/**' \
   --glob '!**/automation/**' \
   --glob '!**/ng-mobile/**' \
   --glob '!**/target/**' \
   --glob '!**/dist/**' > "$REFERENCES_FILE" 2>/dev/null; then
    REF_COUNT=$(wc -l < "$REFERENCES_FILE")
    echo "📎 Found $REF_COUNT references to .$FILE_TYPE files"
else
    echo "⚠️  No references found (this might indicate all files are unreferenced)"
fi

# -----------------------
# Step 4: Compare and report unreferenced files
# -----------------------
echo "📊 Comparing and identifying unreferenced .$FILE_TYPE files..."
python3 - <<EOF
import os

with open("$FILENAMES_FILE") as all_file, open("$REFERENCES_FILE") as ref_file:
    all_files_list = [line.strip() for line in all_file]
    all_files = set(all_files_list)
    referenced = set()

    # Check for duplicates
    duplicates = len(all_files_list) - len(all_files)

    for line in ref_file:
        # Extract just the filename from the reference line (which may include file path)
        # The line format from ripgrep is typically: filepath:content
        if ':' in line:
            # Split on first colon to separate filepath from content
            parts = line.split(':', 1)
            if len(parts) > 1:
                content = parts[1]
            else:
                content = line
        else:
            content = line
        
        # Check if any of our target filenames appear in the content (not the file path)
        for file_name in all_files:
            if file_name in content:
                referenced.add(file_name)

unused = sorted(all_files - referenced)
with open("$UNREFERENCED_FILE", "w") as out:
    for file_name in unused:
        print(file_name, file=out)

print(f"Duplicate file names found: {duplicates}")
print(f"Searched File Names: {len(all_files)}")
print(f"Referenced Files: {len(referenced)}")
print(f"Unreferenced Files: {len(unused)}")

if unused:
    print(f"\\nUnreferenced .$FILE_TYPE files:")
    for file_name in unused:
        print(f"  • {file_name}")
else:
    print(f"\\n🎉 All .$FILE_TYPE files are referenced!")
EOF

echo ""
echo "✅ Analysis complete!"
echo "📄 All .$FILE_TYPE files: $ALL_FILES_FILE"
echo "📝 Filenames: $FILENAMES_FILE"
echo "🔗 References found: $REFERENCES_FILE"
echo "🗑️ Unreferenced files: $UNREFERENCED_FILE"
