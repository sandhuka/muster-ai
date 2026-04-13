#!/usr/bin/env bash
set -euo pipefail

# Muster — New Project Setup Script
# Usage: ./scripts/setup-project.sh <project-name> [muster-repo-url]
#
# Creates a new project directory with:
# - Git repo initialized
# - Muster added as a git submodule
# - Agent bootloaders copied from templates
# - Knowledge-base templates copied with protocol headers
# - Project CLAUDE.md template with placeholders

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-name> [muster-repo-url]"
    echo ""
    echo "  project-name    Name of the new project directory"
    echo "  muster-repo-url Optional: URL of the Muster repo (default: uses local path)"
    echo ""
    echo "Example:"
    echo "  $0 my-app https://github.com/myorg/muster-ai.git"
    exit 1
fi

PROJECT_NAME="$1"
MUSTER_URL="${2:-$MUSTER_ROOT}"

if [ -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' already exists."
    exit 1
fi

echo "Creating project: $PROJECT_NAME"
echo "Muster source: $MUSTER_URL"
echo ""

# Create project directory and initialize git
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"
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
echo "Project '$PROJECT_NAME' created successfully."
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Edit CLAUDE.md — fill in product name, description, tech stack"
echo "  3. Edit knowledge-base/agent-context/*.md — fill in per-agent product context"
echo "  4. Start with: @research Here's my product idea: [description]"
echo "  5. After research, ask Root Claude to plan your first sprint"
echo "  6. As you work, create product-specific skills in knowledge-base/agent-skills/<agent>/"
echo ""
echo "For more info, see muster/README.md and muster/multi-agent-system-overview.md"
