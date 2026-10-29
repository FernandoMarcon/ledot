#!/bin/bash
# translate.sh — translate text via translate-shell (default target: pt-BR)
# Usage: translate.sh "hello world" | echo "hello" | translate.sh | TO=en translate.sh "olá"

set -euo pipefail

command -v trans >/dev/null || { echo "trans not found: run setup/tools.sh" >&2; exit 1; }

TO="${TO:-pt-BR}"

if [ $# -gt 0 ]; then
    text="$*"
elif [ ! -t 0 ]; then
    text="$(cat)"
else
    echo "Usage: translate.sh <text>  (or pipe text in)" >&2
    exit 1
fi

trans -to "${TO}" -join-sentence -brief "${text}"
