#!/usr/bin/env bash
set -euo pipefail

# Muster — New Project Setup Script
#
# Creates a new project directory with:
# - Git repo initialized
# - Muster added as a git submodule
# - Agent bootloaders copied from templates
# - Knowledge-base templates copied with protocol headers
# - Project CLAUDE.md template with placeholders
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s <project-name>
#   ./setup-project.sh <project-name> [muster-repo-url]

DEFAULT_MUSTER_URL="https://github.com/sandhuka/muster-ai.git"

if [ $# -lt 1 ]; then
    echo "Usage: ${BASH_SOURCE[0]:-setup-project.sh} <project-name> [muster-repo-url]"
    echo ""
    echo "  project-name    Name of the new project directory (created in current directory)"
    echo "  muster-repo-url Optional: URL of the Muster repo (default: $DEFAULT_MUSTER_URL)"
    echo ""
    echo "Examples:"
    echo "  curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s my-app"
    echo "  ./setup-project.sh my-app https://github.com/myorg/muster-ai.git"
    exit 1
fi

PROJECT_NAME="$1"
MUSTER_URL="${2:-$DEFAULT_MUSTER_URL}"
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory '$PROJECT_DIR' already exists."
    exit 1
fi

echo "Creating project: $PROJECT_NAME"
echo "Location: $PROJECT_DIR"
echo "Muster source: $MUSTER_URL"
echo ""

# Create project directory in the current working directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
git init

# Add Muster as submodule
echo "Adding Muster as submodule..."
git submodule add "$MUSTER_URL" muster

# Copy agent bootloaders
echo "Copying agent bootloaders..."
mkdir -p .claude/agents
cp muster/templates/.claude/agents/*.md .claude/agents/

# Copy project CLAUDE.md template
echo "Copying project CLAUDE.md template..."
cp muster/templates/CLAUDE.md CLAUDE.md

# Copy knowledge-base templates
echo "Copying knowledge-base templates..."
cp -r muster/templates/knowledge-base .

# Create agent-skills directories for product-specific skills
echo "Creating agent-skills directories..."
for agent in content developer legal marketing pm qa research ui-ux; do
    mkdir -p "knowledge-base/agent-skills/$agent"
    touch "knowledge-base/agent-skills/$agent/.gitkeep"
done

# Remove .DS_Store files copied from templates
find . -name ".DS_Store" -delete 2>/dev/null || true

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
.DS_Store
*.swp
*.swo
*~
GITIGNORE

# Initial commit with all scaffolded files
echo "Creating initial commit..."
git add -A
git commit -m "Initial project setup with Muster AI framework

Scaffolded from muster/templates/ via setup-project.sh.
Includes agent bootloaders, knowledge-base templates, and project CLAUDE.md."

echo ""
echo "✅ Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Get started:"
echo ""
echo "  cd $PROJECT_DIR"
echo "  claude"
echo ""
echo "Then tell Root Claude your product idea:"
echo ""
echo "  \"Here's my product idea: [describe it]. Kick off the discovery phase.\""
echo ""
echo "Root Claude is your PM — it will handle everything from there."
echo "For a full walkthrough, see: muster/getting-started.md"
