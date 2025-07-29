#!/bin/bash

# Enhanced file encryption/decryption script with multiple password input methods
# Author: Claude
# Date: July 9, 2025

set -e  # Exit immediately if a command exits with non-zero status

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
    echo -e "${BLUE}File Encryption/Decryption Utility${NC}"
    echo
    echo "Usage: $0 <encrypt|decrypt> <filename> [options]"
    echo
    echo "Required arguments:"
    echo "  encrypt|decrypt       Action to perform"
    echo "  filename              Path to the file to process"
    echo
    echo "Password options (one method required):"
    echo "  -i                    Interactive mode (prompt for password)"
    echo "  -p <password>         Direct password input (least secure)"
    echo "  -e <env_var>          Use password from environment variable"
    echo "  -f <password_file>    Read password from file"
    echo
    echo "Other options:"
    echo "  -o <output_file>      Specify output filename"
    echo "  -a <algorithm>        Encryption algorithm (default: aes-256-cbc)"
    echo "  -h                    Display this help message"
    echo
    echo -e "${YELLOW}Security Notice:${NC}"
    echo "  - Interactive mode (-i) is the most secure option"
    echo "  - Direct password (-p) is visible in process listings and command history"
    echo "  - Environment variables (-e) are more secure than direct input"
    echo "  - Password files (-f) should be stored securely and deleted after use"
    echo
    exit 1
}

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to securely delete a file
secure_delete() {
    local file="$1"
    if command -v shred &> /dev/null; then
        shred -u "$file"
    elif command -v srm &> /dev/null; then
        srm "$file"
    else
        rm "$file"
        log_warn "Secure deletion tools (shred/srm) not found. Used regular rm instead."
    fi
}

# Default values
ACTION=""
INPUT_FILE=""
OUTPUT_FILE=""
ALGORITHM="aes-256-cbc"
PASS_OPTION=""
TEMP_PWD_FILE=""
INTERACTIVE=0

# Parse arguments
if [ $# -lt 2 ]; then
    usage
fi

ACTION="$1"
INPUT_FILE="$2"
shift 2

# Check if action is valid
if [[ "$ACTION" != "encrypt" && "$ACTION" != "decrypt" ]]; then
    log_error "Invalid action: $ACTION. Must be 'encrypt' or 'decrypt'."
    usage
fi

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    log_error "File not found: $INPUT_FILE"
    exit 1
fi

# Process remaining arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -o)
            if [ $# -lt 2 ]; then
                log_error "Missing output filename after -o"
                usage
            fi
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -a)
            if [ $# -lt 2 ]; then
                log_error "Missing algorithm after -a"
                usage
            fi
            ALGORITHM="$2"
            shift 2
            ;;
        -i)
            INTERACTIVE=1
            shift
            ;;
        -p)
            if [ $# -lt 2 ]; then
                log_error "Missing password after -p"
                usage
            fi
            if [ $INTERACTIVE -eq 1 ] || [ -n "$PASS_OPTION" ]; then
                log_error "Only one password method can be used at a time."
                usage
            fi
            log_warn "Using password on command line is insecure!"
            PASS_OPTION="-pass pass:$2"
            shift 2
            ;;
        -e)
            if [ $# -lt 2 ]; then
                log_error "Missing environment variable name after -e"
                usage
            fi
            if [ $INTERACTIVE -eq 1 ] || [ -n "$PASS_OPTION" ]; then
                log_error "Only one password method can be used at a time."
                usage
            fi
            ENV_VAR_NAME="$2"
            if [ -z "${!ENV_VAR_NAME}" ]; then
                log_error "Environment variable $ENV_VAR_NAME is not set or empty"
                exit 1
            fi
            PASS_OPTION="-pass env:$ENV_VAR_NAME"
            shift 2
            ;;
        -f)
            if [ $# -lt 2 ]; then
                log_error "Missing password file after -f"
                usage
            fi
            if [ $INTERACTIVE -eq 1 ] || [ -n "$PASS_OPTION" ]; then
                log_error "Only one password method can be used at a time."
                usage
            fi
            PASSWORD_FILE="$2"
            if [ ! -f "$PASSWORD_FILE" ]; then
                log_error "Password file not found: $PASSWORD_FILE"
                exit 1
            fi
            PASS_OPTION="-pass file:$PASSWORD_FILE"
            shift 2
            ;;
        -h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Determine the output filename if not specified
if [ -z "$OUTPUT_FILE" ]; then
    case "$ACTION" in
        encrypt)
            OUTPUT_FILE="${INPUT_FILE}.enc"
            ;;
        decrypt)
            OUTPUT_FILE="${INPUT_FILE%.enc}"
            # If removing .enc doesn't change the filename, append .decrypted
            if [ "$OUTPUT_FILE" = "$INPUT_FILE" ]; then
                OUTPUT_FILE="${INPUT_FILE}.decrypted"
            fi
            ;;
    esac
fi

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    read -p "Output file already exists. Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        exit 0
    fi
fi

# Interactive mode (takes precedence if no other method was specified)
if [ $INTERACTIVE -eq 1 ] || [ -z "$PASS_OPTION" ]; then
    # Create a temporary file for the password
    TEMP_PWD_FILE=$(mktemp)
    chmod 600 "$TEMP_PWD_FILE"  # Secure permissions
    
    # Get password securely
    if [ "$ACTION" = "encrypt" ]; then
        read -s -p "Enter password for encryption: " PASSWORD
        echo
        read -s -p "Confirm password: " PASSWORD_CONFIRM
        echo
        
        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            secure_delete "$TEMP_PWD_FILE"
            log_error "Passwords do not match."
            exit 1
        fi
    else
        read -s -p "Enter password for decryption: " PASSWORD
        echo
    fi
    
    echo "$PASSWORD" > "$TEMP_PWD_FILE"
    PASS_OPTION="-pass file:$TEMP_PWD_FILE"
fi

# Validate that we have a password method
if [ -z "$PASS_OPTION" ]; then
    log_error "No password method specified."
    usage
fi

# Perform the requested action
log_info "Processing file: $INPUT_FILE → $OUTPUT_FILE"
log_info "Using algorithm: $ALGORITHM"

# For OpenSSL 1.1.1 and newer, add pbkdf2 for better security
OPENSSL_VERSION=$(openssl version | awk '{print $2}')
PBKDF_OPTION=""
if [[ "$OPENSSL_VERSION" > "1.1.0" ]]; then
    PBKDF_OPTION="-pbkdf2"
fi

if [ "$ACTION" = "encrypt" ]; then
    # Attempt encryption
    if openssl enc -$ALGORITHM -salt -in "$INPUT_FILE" -out "$OUTPUT_FILE" $PBKDF_OPTION $PASS_OPTION; then
        log_info "File encrypted successfully!"
    else
        log_error "Encryption failed!"
        [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
        [ -n "$TEMP_PWD_FILE" ] && secure_delete "$TEMP_PWD_FILE"
        exit 1
    fi
else
    # Attempt decryption
    if openssl enc -d -$ALGORITHM -salt -in "$INPUT_FILE" -out "$OUTPUT_FILE" $PBKDF_OPTION $PASS_OPTION; then
        log_info "File decrypted successfully!"
    else
        log_error "Decryption failed! This could be due to an incorrect password or corrupted file."
        [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
        [ -n "$TEMP_PWD_FILE" ] && secure_delete "$TEMP_PWD_FILE"
        exit 1
    fi
fi

# Clean up temporary password file if used
if [ -n "$TEMP_PWD_FILE" ]; then
    secure_delete "$TEMP_PWD_FILE"
fi

# Verify the output file exists
if [ -f "$OUTPUT_FILE" ]; then
    log_info "Output written to: $OUTPUT_FILE"
    # Show file details
    log_info "File details:"
    ls -lh "$OUTPUT_FILE" | awk '{print "  Size: " $5 "  Created: " $6 " " $7 " " $8}'
else
    log_error "Failed to create output file!"
    exit 1
fi

exit 0
