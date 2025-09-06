#!/bin/bash
# Kubernetes (kubectl) auto-completion
# ✅ Helm auto-completion
# ✅ Alias k=kubectl with auto-completion
# ✅ Namespace switcher setns with auto-completion
# ✅ Colored PS1 prompt showing Kubernetes context and namespace
set -e

BASHRC_FILE="$HOME/.bashrc"

echo "Updating ~/.bashrc with Kubernetes and Helm completions, aliases, and custom functions..."

# Append configurations if they don't already exist
{
    echo ""
    echo "# Kubernetes and Helm completions, aliases, and custom functions"
    echo "source <(kubectl completion bash)"
    echo "alias k=kubectl"
    echo "complete -F __start_kubectl k"
    echo ""

    echo "setns() {"
    echo "    if [ -z \"\$1\" ]; then"
    echo "        echo \"Usage: setns <namespace>\""
    echo "    else"
    echo "        kubectl config set-context --current --namespace=\"\$1\""
    echo "        echo \"Namespace set to '\$1'\""
    echo "    fi"
    echo "}"
    echo ""

    echo "_setns_completion() {"
    echo "    local cur=\${COMP_WORDS[COMP_CWORD]}"
    echo "    local namespaces=\$(kubectl get namespaces -o jsonpath=\"{.items[*].metadata.name}\" 2>/dev/null)"
    echo "    COMPREPLY=( \$(compgen -W \"\${namespaces}\" -- \"\$cur\") )"
    echo "}"
    echo "complete -F _setns_completion setns"
    echo ""

    echo "# Colors"
    echo "RED='\\[\\033[0;31m\\]'"
    echo "GREEN='\\[\\033[0;32m\\]'"
    echo "BLUE='\\[\\033[0;34m\\]'"
    echo "YELLOW='\\[\\033[0;33m\\]'"
    echo "NO_COLOR='\\[\\033[0m\\]'"
    echo ""

    echo "# Function to get Kubernetes context and namespace"
    echo "function kubecontext {"
    echo "  kubectl config current-context 2>/dev/null"
    echo "}"
    echo ""

    echo "function kubenamespace {"
    echo "  kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null"
    echo "}"
    echo ""

    echo "# Custom PS1 with colors and separators"
    echo "export PS1=\"\${GREEN}\\u\${NO_COLOR}@\${BLUE}\\h\${NO_COLOR} \${YELLOW}\\W\${NO_COLOR}|kcontext:\${RED}\\\$(kubecontext)\${NO_COLOR}(ns:\${RED}\\\$(kubenamespace)\${NO_COLOR}) \\$ \""
    echo ""

    echo "# Enable Helm auto-completion"
    echo "source <(helm completion bash)"
} >> "$BASHRC_FILE"

echo "Applying changes..."
source "$BASHRC_FILE"

echo "Done! Your ~/.bashrc has been updated with Kubernetes, Helm auto-completion, and a custom prompt."
