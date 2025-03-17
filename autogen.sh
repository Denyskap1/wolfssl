#!/bin/sh
#
# Script to prepare configuration and Makefile generation for wolfSSL
#

# Exit on any error
set -e

# Utility functions
warn() { printf '%s\n' "$*" >&2; }
die() { printf '\nERROR: %s\n\n' "$*" >&2; exit 1; }

# Check for WSL environment and filesystem compatibility
check_wsl() {
    no_links=""
    if [ -n "$WSL_DISTRO_NAME" ]; then
        current_path=$(pwd) || die "Failed to get current directory"
        case "$current_path" in
            /mnt/?/*)
                warn "Detected WSL with Windows filesystem - symbolic links disabled"
                no_links=true
                ;;
            *)
                warn "Detected WSL with Linux filesystem - symbolic links enabled"
                ;;
        esac
    fi
    # Export for use in subsequent commands if needed
    export NO_LINKS="$no_links"
}

# Create necessary directories
create_directories() {
    for dir in \
        "./wolfssl/wolfcrypt/port/intel" \
        "./wolfssl/wolfcrypt/port/cavium"
    do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || die "Failed to create directory: $dir"
        fi
    done
}

# Create empty stub files if they don't exist
create_stub_files() {
    for file in \
        "./wolfssl/options.h" \
        "./wolfcrypt/src/fips.c" \
        "./wolfcrypt/src/fips_test.c" \
        "./wolfcrypt/src/wolfcrypt_first.c" \
        "./wolfcrypt/src/wolfcrypt_last.c" \
        "./wolfssl/wolfcrypt/fips.h" \
        "./wolfcrypt/src/selftest.c" \
        "./wolfcrypt/src/async.c" \
        "./wolfssl/wolfcrypt/async.h" \
        "./wolfcrypt/src/port/intel/quickassist.c" \
        "./wolfcrypt/src/port/intel/quickassist_mem.c" \
        "./wolfcrypt/src/port/cavium/cavium_nitrox.c" \
        "./wolfssl/wolfcrypt/port/intel/quickassist.h" \
        "./wolfssl/wolfcrypt/port/intel/quickassist_mem.h" \
        "./wolfssl/wolfcrypt/port/cavium/cavium_nitrox.h"
    do
        if [ ! -e "$file" ]; then
            # Ensure directory exists before creating file
            file_dir=$(dirname "$file")
            [ -d "$file_dir" ] || mkdir -p "$file_dir" || die "Failed to create directory: $file_dir"
            touch "$file" || die "Failed to create file: $file"
        fi
    done
}

# Configure build warnings based on source type
setup_build_config() {
    if [ -e ".git" ]; then
        warn "Detected git repository - enabling strict warnings"
        export WARNINGS="all,error"
    else
        warn "No git repository detected - enabling standard warnings"
        export WARNINGS="all"
    fi
}

# Main execution
main() {
    # Check prerequisites
    command -v autoreconf >/dev/null 2>&1 || die "autoreconf not found in PATH"

    check_wsl
    create_directories
    create_stub_files
    setup_build_config

    # Run autoreconf
    warn "Running autoreconf..."
    autoreconf --install --force || die "autoreconf failed"
    warn "Configuration preparation completed successfully"
}

main "$@"
