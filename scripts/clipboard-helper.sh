#!/usr/bin/env bash
# Helper script for Lunar Shell Clipboard Manager

set -eo pipefail

ACTION="${1:-}"
ARG1="${2:-}"
ARG2="${3:-}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/clipboard_previews"
mkdir -p "$CACHE_DIR"

case "$ACTION" in
    paste)
        if [[ -n "$ARG1" ]]; then
            # 1. Decode to clipboard
            cliphist decode "$ARG1" | wl-copy
            # 2. Wait for clipboard readiness and window focus restoration
            sleep 0.2
            # 3. Simulate Ctrl+V to paste into active window
            wtype -M ctrl v -m ctrl
        fi
        ;;

    copy)
        if [[ -n "$ARG1" ]]; then
            cliphist decode "$ARG1" | wl-copy
        fi
        ;;

    delete)
        if [[ -n "$ARG1" ]]; then
            printf "%s\n" "$ARG1" | cliphist delete
        fi
        ;;

    decode-image)
        # $ARG1 = id, $ARG2 = target filepath
        if [[ -n "$ARG1" && -n "$ARG2" ]]; then
            if [[ ! -s "$ARG2" ]]; then
                cliphist decode "$ARG1" > "$ARG2"
            fi
            echo "$ARG2"
        fi
        ;;

    decode-text)
        # $ARG1 = id
        if [[ -n "$ARG1" ]]; then
            cliphist decode "$ARG1"
        fi
        ;;

    wipe)
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        ;;

    *)
        echo "Usage: $0 {paste|copy|delete|decode-image|decode-text|wipe} [args...]" >&2
        exit 1
        ;;
esac
