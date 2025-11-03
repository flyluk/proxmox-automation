#!/bin/bash
set -e

echo "Setting up kubectl completion and alias..."

# Add to bashrc
cat >> ~/.bashrc <<'EOF'

# kubectl completion and alias
source <(kubectl completion bash)
alias kc=kubectl
complete -o default -F __start_kubectl kc
EOF

# Apply to current session
source ~/.bashrc

echo "✓ kubectl completion and alias 'kc' configured"
echo "Run: source ~/.bashrc"
