#!/bin/bash
# setup.sh — One-time local setup for ask-epics
#
# Usage:
#   ./setup.sh [DATA_DIR]
#
# Clones 25 epics-base GitHub repos, builds the FTS5 search index, and
# generates env.local so the skill is ready to use.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$HOME/.local/share/docs-skills/epics-docs}"

if [[ -d "$DATA_DIR" ]]; then
    echo "Data directory already exists: $DATA_DIR"
    echo "To re-index, run: $SKILL_DIR/bin/docs-index index \"$DATA_DIR\" --incremental --ext hpp java h c cpp py md dbd txt pl rst sh"
    exit 0
fi

# epics-base organization repos
REPOS=(
    ci-scripts
    directoryService
    doxy-libcom
    eget
    epics-base
    epicsCoreJava
    epicscorelibs
    exampleJava
    jca
    masarService
    normativeTypesCPP
    p4p
    pva2pva
    pvAccessCPP
    pvaClientCPP
    pvaClientJava
    pvaPy
    pvCommonCPP
    pvDatabaseCPP
    pvDatabaseJava
    pvDataCPP
    pvxs
    secure-pva-design
    setuptools_dso
    website
)

echo "Cloning ${#REPOS[@]} epics-base repos → $DATA_DIR ..."
mkdir -p "$DATA_DIR"

fail_count=0
for repo in "${REPOS[@]}"; do
    echo "  Cloning $repo..."
    if ! git clone "https://github.com/epics-base/$repo.git" "$DATA_DIR/$repo" 2>&1; then
        echo "  WARNING: Failed to clone $repo"
        fail_count=$((fail_count + 1))
    fi
done

if [[ $fail_count -gt 0 ]]; then
    echo "WARNING: $fail_count repo(s) failed to clone"
fi

echo "Building search index..."
"$SKILL_DIR/bin/docs-index" index "$DATA_DIR" --incremental \
    --ext hpp java h c cpp py md dbd txt pl rst sh

# Keep the facility's shared uv reachable. Written FIRST, so the skill's own
# bin line below still prepends last and bin/docs-index keeps the precedence
# it had before this block existed; the shared bin sits behind it, supplying uv.
: > "$SKILL_DIR/env.local"
if [ -d /sdf ]; then
    echo 'export PATH="/sdf/group/lcls/ds/dm/apps/dev/bin:$PATH"' >> "$SKILL_DIR/env.local"
elif [ -d /lustre/orion ]; then
    echo 'export PATH="/ccs/home/cwang31/.local/bin:$PATH"' >> "$SKILL_DIR/env.local"
fi

cat >> "$SKILL_DIR/env.local" <<EOF
export EPICS_DOCS_ROOT="$DATA_DIR"
export PATH="$SKILL_DIR/bin:\$PATH"
EOF

echo ""
echo "Done. Skill is ready to use."
echo "env.local created at: $SKILL_DIR/env.local"
