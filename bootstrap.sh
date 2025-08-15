#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
TEMPLATE_REPO="https://github.com/srbouffard/vale-workflow-template.git"
TMP_DIR=$(mktemp -d)

# Markers for the gitignore block
GITIGNORE_START_MARKER="# BEGIN VALE WORKFLOW IGNORE"
GITIGNORE_END_MARKER="# END VALE WORKFLOW IGNORE"

# --- Helper Functions for User-Friendly Output ---
info() { echo -e "\033[34mINFO\033[0m: $1"; }
ask() { echo -e "\033[33mACTION\033[0m: $1"; }
success() { echo -e "\033[32mSUCCESS\033[0m: $1"; }

# --- Main Script ---

# 0. Pre-flight check for Git branch
info "Checking Git branch..."
# First, check if we are in a git repository.
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    errmsg "This script must be run from within a Git repository."
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
    errmsg "This script should not be run on the 'main' branch."
    echo "Please create and check out a new branch before running (e.g., 'git checkout -b setup-vale-workflow')."
    exit 1
fi
success "Running on branch '$CURRENT_BRANCH'. Proceeding..."

# 1. Clone the template
info "Cloning Vale workflow template from $TEMPLATE_REPO..."
git clone --depth 1 "$TEMPLATE_REPO" "$TMP_DIR" &>/dev/null

# 2. Handle custom wordlist migration
if [ -f ".custom_wordlist.txt" ]; then
  ask "Found '.custom_wordlist.txt'. Do you want to append its contents to the new Vale 'accept.txt'? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    info "Migrating words from .custom_wordlist.txt..."
    cat ".custom_wordlist.txt" >> "$TMP_DIR/.vale/styles/config/vocabularies/local/accept.txt"
    ask "Wordlist migrated. Would you like to remove the old '.custom_wordlist.txt' file? (y/n)"
    read -r del_response
    if [[ "$del_response" =~ ^[Yy]$ ]]; then
        rm ".custom_wordlist.txt"
        info "Removed .custom_wordlist.txt."
    fi
  fi
fi

# 3. Copy over the core, non-conflicting files
info "Copying Vale configuration and GitHub workflow..."
mkdir -p .github/workflows
mkdir -p .vale/styles/config/vocabularies/local
cp "$TMP_DIR"/.github/workflows/docs.yaml .github/workflows/
cp "$TMP_DIR"/.vale.ini .
cp "$TMP_DIR"/.vale/styles/config/vocabularies/local/accept.txt .vale/styles/config/vocabularies/local/


# 4. Handle Makefiles
info "Updating Makefiles..."
# Always overwrite Makefile.docs to ensure the latest doc targets are present.
cp "$TMP_DIR"/Makefile.docs ./Makefile.docs


# Interactively handle the main Makefile
if [ -f "Makefile" ]; then
  while true; do
    ask "A 'Makefile' already exists. The template provides a core Makefile that includes 'Makefile.docs'."
    echo "  (O)verwrite your existing Makefile. (Not recommended if you have custom targets)."
    echo "  (S)ave the template's Makefile as 'Makefile.tmp' for you to merge manually."
    echo "  (I)gnore and do nothing, leaving your Makefile untouched. (Not recommended)."
    read -p "Choose an option: " mc_response
    case $mc_response in
        [Oo]* )
            info "Overwriting existing Makefile..."
            cp "$TMP_DIR"/Makefile ./Makefile
            break;;
        [Ss]* )
            info "Saving template's Makefile to Makefile.tmp..."
            cp "$TMP_DIR"/Makefile ./Makefile.tmp
            info "Please manually add 'include Makefile.docs' from 'Makefile.tmp' to your main 'Makefile'."
            break;;
        [Ii]* )
            info "Skipping main Makefile update."
            break;;
        * ) echo "Please answer O, S, or I.";;
    esac
  done
else
    info "Creating new Makefile from template..."
    cp "$TMP_DIR"/Makefile ./Makefile
fi

# 5. Intelligently update .gitignore
info "Updating .gitignore..."
GITIGNORE_CONTENT=$(cat "$TMP_DIR"/.gitignore.template)
FULL_GITIGNORE_BLOCK="$GITIGNORE_START_MARKER\n$GITIGNORE_CONTENT\n$GITIGNORE_END_MARKER"

# Check if the block already exists.
if grep -qF "$GITIGNORE_START_MARKER" .gitignore 2>/dev/null; then
    info "Vale ignore block found. Replacing it with the latest version..."
    awk -v start="$GITIGNORE_START_MARKER" -v end="$GITIGNORE_END_MARKER" '
      BEGIN { printing=1 }
      $0 == start { printing=0 }
      printing { print }
      $0 == end { printing=1 }
    ' .gitignore > .gitignore.tmp
    mv .gitignore.tmp .gitignore
fi

echo -e "\n$FULL_GITIGNORE_BLOCK" >> .gitignore
info ".gitignore has been updated."


# 6. Final cleanup and instructions
info "Cleaning up temporary files..."
rm -rf "$TMP_DIR"

success "Vale workflow has been bootstrapped!"
echo "Please review the changes and run 'git add .' to commit them."
