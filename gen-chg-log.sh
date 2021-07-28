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

declare -A TYPES
TYPES=( [chore]="Chores" [docs]="Documentation Changes" \
        [feat]="New Features" [fix]="Bug Fixes" \
        [other]="Miscellaneous Tasks" [perf]="Performance Enhancements" \
        [refactor]="Code Improvements" [revert]="Revert a Change" \
        [style]="Stylistic Enhancements" [test]="Tests" )

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

    # Field, and record, separators respectively. Require characters
    # that will not appear in commit subject
    FSEP=035 ; RSEP=036

    # 'entries' is an associative array i.e. hash table
    declare -A entries

    while read -r line ; do
        # Extract fields from current git log line
        read -r type category message short long \
            <<< $(printf "${line}\n" | \
                    awk 'BEGIN { FPAT = "[a-z]+|(.)|[^:()|]+" } \
                        {
                            # Short and long commit hash are always
                            # the final two fields, respectively
                            fld_h = $(NF-2) ; fld_H = $(NF);

                            # subject
                            if (NF == 5)
                            {
                                print("EMPTY", "EMPTY", $1, fld_h, fld_H)
                            }
                            # type: subject
                            else if (NF == 7)
                            {
                                print($1, "GLOBAL", $3, fld_h, fld_H)
                            }
                            # type(): subject
                            else if (NF == 9)
                            {
                                print($1, "GLOBAL", $5, fld_h, fld_H)
                            }
                            # type(category|*): subject
                            else if (NF == 10)
                            {
                                category = ($3 == "*") \
                                    ? "GLOBAL" \
                                    : $3;
                                print($1, category, $6, fld_h, fld_H)
                            }
                            # Non-conforming format - needs special handling
                            else
                            {
                                # Exclude commit hashes from extracted data
                                record = \
                                    substr($0, 0, \
                                        length($0) - \
                                        (length(fld_h) + length(fld_H) + 2));

                                # Split into PREFACE : SUBJECT segments
                                num_segments = \
                                    split(record, segments, ":", seps);

                                # No split occurred because ":" not present
                                # so assume whole record is a SUBJECT
                                if (num_segments == 1)
                                {
                                    print("EMPTY", "EMPTY", \
                                          segments[1], fld_h, fld_H);
                                }
                                # A split occured, we have PREFACE and
                                # SUBJECT, so further process
                                else
                                {
                                    # Concatenate all SUBJECT-related
                                    # segments into a single SUBJECT
                                    subject = ""
                                    for (i = 2; i <= length(segments); ++i)
                                    {
                                        subject = \
                                            subject""segments[i]""seps[i];
                                    }

                                    # Attempt a split of PREFACE further
                                    # into TYPE(CATEGORY)
                                    num_type_segments = \
                                        split(segments[1], \
                                              type_segments, \
                                              "(", type_seps);

                                    # Split failed, so assume it was
                                    # of the form: TYPE: ...
                                    if (num_type_segments == 1)
                                    {
                                        print(type_segments[1], "GLOBAL", \
                                              subject, fld_h, fld_H);
                                    }
                                    # Split occurred, we have TYPE(CATEGORY)
                                    # so extract and adjust CATEGORY
                                    else
                                    {
                                        num_category_segments = \
                                            split(type_segments[2], \
                                                  category_segments, ")", \
                                                  category_seps);

                                        # We either have "*" or a category
                                        category = \
                                            (category_segments[1] == "*" \
                                                ? "GLOBAL" \
                                                : category_segments[1]);

                                        print(type_segments[1], category, \
                                              subject, fld_h, fld_H);
                                    }
                                }
                            }
                        }')

        # Assemble fields into record form for storage as an
        # associative array entry
        entry="${type}"${FSEP}"${category}"${FSEP}"${message}"${FSEP}"\
${short}"${FSEP}"${long}"

        # New associative array entries are APPENDED to existing
        # entries. Simulates an array of lists or records
        if [ ${entries[${type}]+_} ] ; then
            entries[${type}]=${entries[${type}]}${RSEP}${entry}
        else
            entries[${type}]=${entry}
        fi

    done <<< $(gen_log_entries ${start_tag} ${end_tag})

    # Ensure entries always printed in same order
    sorted_entries_keys=$(sort \
        <<< $(for key in "${!entries[@]}" ; do echo ${key} ; done))

    for entry_key in ${sorted_entries_keys} ; do
        # Lookup and print type description (or default)
        if [ ${TYPES[${entry_key}]+_} ] ; then
            printf "\n### ${TYPES[${entry_key}]}\n"
        else
            printf "\n### Other\n"
        fi

        # Extract and print fields from current entry
        entry_values=${entries[${entry_key}]}
        for entry in $(sed 's/'${RSEP}'/\n/g' <<< ${entry_values}) ; do
            read -r type category message short long \
                <<< $(sed 's/'${FSEP}'/ /g' <<< ${entry})
            message=$(sed 's/+=+/ /g' <<< ${message})
            # Cater for non-typed message
            if [ ${category} == 'EMPTY' ] ; then
                printf "* ${message} [${short}](${REPO}/${long})\n"
            else
                printf "* **${category}**:${message} [${short}](${REPO}\
/${long})\n"
            fi
        done
    done
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
            printf "## ${prev_tag} (${tag_date})\n"
            print_log_entries ${curr_tag} ${prev_tag}
            printf "\n"
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
    printf "## ${prev_tag} (${tag_date})\n"
    if [ ${INITIAL_TAG_COMMIT} == ${INITIAL_COMMIT} ] ; then
        print_log_entries ${INITIAL_TAG_COMMIT} ${INITIAL_TAG_COMMIT}
    else
        print_log_entries ${INITIAL_TAG_COMMIT} ${prev_tag}
    fi
    printf "\n"

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

