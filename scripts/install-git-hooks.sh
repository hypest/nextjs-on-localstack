#!/bin/bash
set -euo pipefail

# Install Git hooks by symlinking from git-hooks/ to .git/hooks/
# Run this after clone: ./scripts/install-git-hooks.sh

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOKS_SRC="$REPO_ROOT/git-hooks"
HOOKS_DEST="$REPO_ROOT/.git/hooks"

echo "🔗 Installing Git hooks from $HOOKS_SRC → $HOOKS_DEST"

mkdir -p "$HOOKS_SRC" "$HOOKS_DEST"

for hook in "$HOOKS_SRC"/*; do
    if [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        dest="$HOOKS_DEST/$hook_name"
        
        # Remove existing hook/dangling symlink
        rm -f "$dest"
        
        # Symlink
        ln -sf "$hook" "$dest"
        echo "✅ Symlinked $hook_name"
    fi
done

echo "✅ All Git hooks installed!"
echo ""
echo "💡 To update hooks: re-run this script (idempotent)."
echo "💡 Hooks are now version-controlled in git-hooks/."
