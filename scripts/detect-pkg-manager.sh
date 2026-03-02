#!/usr/bin/env bash
# scripts/detect-pkg-manager.sh
# Detects the active package manager and prints its name to stdout.
# Supported: apt, dnf, pacman, zypper
# Exit codes: 0 = detected, 1 = not found
set -Eeuo pipefail

detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
        exit 1
    fi
}

detect_pkg_manager
