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
# NAME:    gen_log_entries
# PARMS:   $1: (hex string), first commit in range
#          $2: (hex string), last commit in range
# RETURNS: N/A
# PURPOSE: Emits commit metadata for commits in specified range
# ----------------------------------------------------------------------
function gen_log_entries()
{
    start_tag=${1} ; end_tag=${2}

    if [ ${start_tag} == ${end_tag} ] ; then
        git log ${start_tag} --format="%s|%h|%H" -1 \
            | sed 's/ /+=+/g'
        printf "\n"
    else
        git log ${start_tag}...${end_tag} --format="%s|%h|%H" \
            | sed 's/ /+=+/g'
        printf "\n"
    fi
}

# ----------------------------------------------------------------------
# NAME:    print_log_entries
# PARMS:   $1: (hex string), first commit in range
#          $2: (hex string), last commit in range
# RETURNS: N/A
# PURPOSE: Prints commit metadata for commits in specified range.
#
# Commit messages follow the Conventional Commit format, and are
# expected to have the following structure:
#
#     type(category): subject
#
# where:
#
#     type: feat|refactor|fix|docs|chore|other|perf|test|style|revert
#     category: zero or one word|*
#     subject: commit subject (free format, <= ~50 characters)
#
# Examples:
#
#     Initial commit - add .gitignore, README
#     feat(main): add command-line argument parsing
#     refactor: rename all functions
#     docs(*): change section header fonts
#     style(): alter commentary for PEP 57 conformance
#
# ----------------------------------------------------------------------
function print_log_entries()
{
    start_tag=${1} ; end_tag=${2}

    while read -r line ; do
        read -r type category message short long \
            <<< $(printf "${line}\n" | \
                    awk 'BEGIN { FPAT = "[a-z]+|(.)|[^:()|]+" } \
                        {
                            # subject
                            if (NF == 5)
                            {
                                print("EMPTY", "EMPTY", $1, $3, $5)
                            }
                            # type: subject
                            else if (NF == 7)
                            {
                                print($1, "GLOBAL", $3, $5, $7)
                            }
                            # type(): subject
                            else if (NF == 9)
                            {
                                print($1, "GLOBAL", $5, $7, $9)
                            }
                            # type(category|*): subject
                            else if (NF == 10)
                            {
                                category = ($3 == "*") \
                                    ? "GLOBAL" \
                                    : $3;
                                print($1, category, $6, $8, $10)
                            }
                            # Non-conforming format
                            else
                            {
                                desc = "UNKNOWN";
                                data = (length($0) > 0) \
                                    ? $0 \
                                    : "EMPTY";
                                print(desc, desc, data, desc, desc)
                            }
                        }')
        printf "${type} ${category} ${message} ${short} ${long}\n"
    done <<< $(gen_log_entries ${start_tag} ${end_tag})
}

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

    # Must switch directory context to source repository
    pushd ${SOURCE_REPO} > /dev/null

    # For each consecutive tag pair, print commit metadata in that range
    prev_tag=
    for curr_tag in $(git tag --sort=-taggerdate) ; do
        if [ -n "${prev_tag}" ] ; then
            tag_date=$(git log -1 --format="%ad" \
                                  --date=short ${prev_tag})
            printf "## ${prev_tag} (${tag_date})\n\n"
            print_log_entries ${curr_tag} ${prev_tag}
            printf "\n\n"
        fi
        prev_tag=${curr_tag}
    done

    # Print remaining items, and cater for possibility
    # that INITIAL COMMIT is tagged
    tag_commit_list=( $(git log --tags --simplify-by-decoration \
                            --format="%H" --reverse) )
    INITIAL_TAG_COMMIT=${tag_commit_list[0]}
    INITIAL_COMMIT=$(git rev-list --max-parents=0 HEAD)

    tag_date=$(git log -1 --format="%ad" --date=short ${prev_tag})
    printf "## ${prev_tag} (${tag_date})\n\n"
    if [ ${INITIAL_TAG_COMMIT} == ${INITIAL_COMMIT} ] ; then
        print_log_entries ${INITIAL_TAG_COMMIT} ${INITIAL_TAG_COMMIT}
    else
        print_log_entries ${INITIAL_TAG_COMMIT} ${prev_tag}
    fi
    printf "\n\n"

    # Restore directory context
    popd > /dev/null
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

