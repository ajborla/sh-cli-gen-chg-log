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
# Assumptions:
#
# * *NIX environment, native or emulated (WSL or msys)
# * Local git repository exists
#
# ---
# USAGE:
#
#    ...
#
#    <scriptname>.sh --[help|version] | ...
#
# Examples:
#
#    ./<scriptname>.sh --help
#    ./<scriptname>.sh --version
#    ./<scriptname>.sh ...
#
# ----------------------------------------------------------------------

# Global Constants =====================================================

# Generic --------------------------------------------------------------

SUCCESS=0
FAILURE=1

# Application-specific -------------------------------------------------

USAGE="$0 --[help|version] | ..."
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

# Application-specific -------------------------------------------------

# ----------------------------------------------------------------------
# NAME:    main
# PARMS:   $1: ...
# RETURNS: ...
# PURPOSE: ...
# ----------------------------------------------------------------------
function main ()
{
    :
}

# Entry Point ==========================================================

main

