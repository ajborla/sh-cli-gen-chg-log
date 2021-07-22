#!/usr/bin/env bash

# ----------------------------------------------------------------------
# PROJECT: https://github.com/ajborla/sh-cli-gen-chg-log.git
# NAME:    gen-chg-log.sh
# AUTHOR:  Anthony J. Borla (ajborla@bigpond.com)
# CREATED: 2021-07-16
#
# ---
# TARGET ENVIRONMENT: Linux (bash) [Native, WSL or msys]
#
# ---
# DESCRIPTION:
#
# Generates a changelog from git commits.
#
# Requirements:
#
# * *NIX environment, native or emulated (WSL or msys)
# * Recent versions of bash, gawk, and git installed
# * Target repository exists, and is filesystem-based i.e. local repo
#
# ---
# USAGE:
#
#    ...
#
#    <scriptname>.sh --[help|version] | <REPO> | <REPO> <URL>
#
# Examples:
#
#    ./<scriptname>.sh --help
#    ./<scriptname>.sh --version
#    ./<scriptname>.sh .
#    ./<scriptname>.sh ~/local_repo
#    ./<scriptname>.sh ~/local_repo https://github.com/user/reponame
#
# ----------------------------------------------------------------------

# Global Constants =====================================================

# Generic --------------------------------------------------------------

SUCCESS=0
FAILURE=1

# Application-specific -------------------------------------------------

USAGE="$0 --[help|version] | <REPO> | <REPO> <URL>"
APPDESC='Changelog Generator'
VERSION=0.0.0

# Subroutines ==========================================================

# Generic --------------------------------------------------------------

# ----------------------------------------------------------------------
# NAME:    badargs
# PARMS:   N/A
# RETURNS: N/A
# PURPOSE: Prints message and command-line usage.
# ----------------------------------------------------------------------
function badargs ()
{
    printf "ERROR: Incorrect arguments.\nUsage: $USAGE\n"
}

# ----------------------------------------------------------------------
# NAME:    badrepo
# PARMS:   N/A
# RETURNS: N/A
# PURPOSE: Prints message and command-line usage.
# ----------------------------------------------------------------------
function badrepo ()
{
    printf "ERROR: Not a local git repository.\nUsage: $USAGE\n"
}

# ----------------------------------------------------------------------
# NAME:    badURL
# PARMS:   N/A
# RETURNS: N/A
# PURPOSE: Prints message and command-line usage.
# ----------------------------------------------------------------------
function badURL ()
{
    printf "ERROR: Not a valid URL string.\nUsage: $USAGE\n"
}

# ----------------------------------------------------------------------
# NAME:    usage
# PARMS:   N/A
# RETURNS: N/A
# PURPOSE: Prints shell script description and command-line usage.
# ----------------------------------------------------------------------
function usage ()
{
    printf "$APPDESC ($VERSION).\nUsage: $USAGE\n"
}

# ----------------------------------------------------------------------
# NAME:    version
# PARMS:   N/A
# RETURNS: N/A
# PURPOSE: Prints shell script version in MAJOR.MINOR.PATCH format.
# ----------------------------------------------------------------------
function version ()
{
    printf "Version: $VERSION\n"
}

# ----------------------------------------------------------------------
# NAME:    is_local_git_repo
# PARMS:   $1: (string), name of a filesystem directory
# RETURNS: $SUCCESS if $1 is a git repo
# PURPOSE: Tests whether a target directory, $1, is a git repo
# ----------------------------------------------------------------------
function is_local_git_repo ()
{
    [ -d $(readlink -f "$1")/.git ]
}

# ----------------------------------------------------------------------
# NAME:    is_valid_url_string
# PARMS:   $1: (string, English-only), URL
# RETURNS: $SUCCESS if $1 is a valid URL string
# PURPOSE: Tests whether a target string, $1, represents a valid URL
# ----------------------------------------------------------------------
function is_valid_url_string ()
{
    regex='(file|https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*'\
'[-A-Za-z0-9\+&@#/%=~_|]'
    [[ "$1" =~ $regex ]]
}

# Application-specific -------------------------------------------------

# ----------------------------------------------------------------------
# NAME:    main
# PARMS:   $1: (string), local git repository name
#          $2: (string), remote git repository URL
# RETURNS: $SUCCESS if all operations complete correctly
# PURPOSE: Application entry point function, performs the following:
#          - Adjusts repo path and URL
#          -
#          -
# ----------------------------------------------------------------------
function main ()
{
    # Require a fully-qualified path
    SOURCE_REPO=$(readlink -f "$1")

    # Require an URL, whether local or remote
    if [ -n "$2" ] ; then
        TARGET_REPO_URL="$2"
    else
        TARGET_REPO_URL="file://${SOURCE_REPO}"
    fi

    printf "Source repo: ${SOURCE_REPO}\n"
    printf "Target repo URL: ${TARGET_REPO_URL}\n"
}

# Entry Point ==========================================================

# Check command-line arguments (expecting 1 or 2)
if [ $# -eq 1 ] ; then
    # One argument, expecting a command option, or a local git
    # repository name
    case $1 in
        --version|-[vV]) version ;;
        --help|-[hH])    usage ;;
        *)               is_local_git_repo "$1" \
                             || { badrepo ; exit $FAILURE ; }

                         main "$1" ;;
    esac

elif [ $# -eq 2 ] ; then
    # Two arguments expected:
    # - Local git repository name
    # - Remote git repository URL
    is_local_git_repo "$1" \
        || { badrepo ; exit $FAILURE ; }

    is_valid_url_string "$2" \
        || { badURL ; exit $FAILURE ; }

    main "$1" "$2"

else
    # No arguments or incorrect number of arguments
    badargs ; exit $FAILURE
fi

