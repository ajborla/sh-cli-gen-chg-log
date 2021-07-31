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
# Generates a changelog, in Markdown format, from git commits.
#
# Effective changelog generation relies on the repository meeting
# several requirements:
#
# * Repository MUST BE tagged, but no tag format requirements
# * Commit subject line should follow Conventional Commit format, but
#   this is not mandatory; it facilitates commit categorisation
#
# Tags provide the grouping criterion for commits. They are used to
# create tag ranges. For example, tags v1.0.0 and v2.0.0 form a tag
# range. Commits dated between those two tags will appear together.
# Semantically, tags represent milestones in the evolution of the
# repository, most often, releases. It makes little sense to create
# a changelog if there are no milestones !
#
# The Conventional Commit format for subject lines provides metadata
# that may be parsed, and used to categorise commits. This enhances
# the utility of the generated changelog. It is, not, however,
# essential that it be followed. Non-conforming commits will appear
# unardorned under the "Other" section.
#
# Commit subject lines following the Conventional Commit format have
# the following structure:
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
# ---
# REQUIREMENTS:
#
# * *NIX environment, native or emulated (WSL or msys)
# * Recent versions of bash, gawk, and git installed
# * Target repository exists, and is filesystem-based i.e. local repo
#
# ---
# USAGE:
#
# Script may be located in the current directory, or the <REPO>
# directory, or in the PATH. Requirements:
# * <REPO> must exist (can, optionally, be the current directory)
# * <URL> must be a well-formed; no checks made for its existence
#
# Invocation as follows:
#
#    gen-chg-log.sh --[help|version] | -[hHvV] | <REPO> | <REPO> <URL>
#
# Options for help, and version display, are available.
#
# Invoking with <REPO> expands <REPO> to a full path, <FQP_REPO>,
# and traverses this path to generate the changelog. For each
# commit, a link to the long commit hash appears as:
#
#     file:///<FQP_REPO>/...long commit hash...
#
# Use case for this invocation is if generating a changelog meant to
# locally hosted, usually for testing purposes.
#
# Invoking with <REPO> <URL> performs identically except that the long
# commit hash links appear as:
#
#     <URL>/...long commit hash...
#
# This type of invocation is for the more typical use case, for
# generating a changelog meant to be remotely hosted.
#
# Examples of possible command-line invocations:
#
#    # Print usage information
#    gen-chg-log.sh --help
#    ./gen-chg-log.sh -h
#
#    # Print application version number
#    ./gen-chg-log.sh --version
#    gen-chg-log.sh -v
#
#    # Prints changelog of current directory
#    ./gen-chg-log.sh .
#
#    # Prints changelog of ~/local_repo redirected to CHANGELOG.md
#    # with file:///-prefaced long hash links
#    ./gen-chg-log.sh ~/local_repo > CHANGELOG.md
#
#    # Prints changelog of ~/local_repo redirected to CHANGELOG.md
#    # with https://-prefaced long hash links
#    ./gen-chg-log.sh ~/local_repo \
#                     https://github.com/user/reponame > CHANGELOG.md
#
# ----------------------------------------------------------------------

# Global Constants =====================================================

# Generic --------------------------------------------------------------

SUCCESS=0
FAILURE=1

# Application-specific -------------------------------------------------

USAGE="$0 --[help|version] | -[hHvV] | <REPO> | <REPO> <URL>"
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
#          $3: (string), filesystem directory|URL
# RETURNS: N/A
# PURPOSE: Prints commit metadata for commits in specified range.
# ----------------------------------------------------------------------
function print_log_entries()
{
    start_tag=${1} ; end_tag=${2} ; REPO=${3}

    # Generate one or more log entries
    gen_log_entries ${start_tag} ${end_tag} | \
        awk -v REPO=${REPO} 'BEGIN {
                FPAT = "[a-z]+|(.)|[^:()|]+";
            }
            NF > 0 {
                # Short and long commit hash are always
                # the final two fields, respectively
                short_hash = $(NF-2) ; long_hash = $(NF);

                # subject
                if (NF == 5)
                {
                    entries["EMPTY"]["EMPTY"][short_hash] = \
                        long_hash SUBSEP $1
                }
                # type: subject
                else if (NF == 7)
                {
                    entries[$1]["GLOBAL"][short_hash] = \
                        long_hash SUBSEP $3
                }
                # type(): subject
                else if (NF == 9)
                {
                    entries[$1]["GLOBAL"][short_hash] = \
                        long_hash SUBSEP $5
                }
                # type(category|*): subject
                else if (NF == 10)
                {
                    category = ($3 == "*") \
                        ? "GLOBAL" \
                        : $3;
                    entries[$1][category][short_hash] = \
                        long_hash SUBSEP $6
                }
                # Non-conforming format - needs special handling
                else
                {
                    # Exclude commit hashes from extracted data
                    record = \
                        substr($0, 0, \
                            length($0) - \
                            (length(short_hash) + length(long_hash) + 2));

                    # Split into PREFACE : SUBJECT segments
                    num_segments = \
                        split(record, segments, ":", seps);

                    # No split occurred because ":" not present
                    # so assume whole record is a SUBJECT
                    if (num_segments == 1)
                    {
                        entries["EMPTY"]["EMPTY"][short_hash] = \
                            long_hash SUBSEP segments[1]
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
                            TS1 = type_segments[1]
                            entries[TS1]["GLOBAL"][short_hash] = \
                                long_hash SUBSEP subject
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

                            TS1 = type_segments[1];
                            entries[TS1][category][short_hash] = \
                                long_hash SUBSEP subject;
                        }
                    }
                }
            }
            END {

# Type description strings
TDV = "chore;Chores,docs;Documentation Changes,feat;New Features,"\
"fix;Bug Fixes,other;Miscellaneous Tasks,perf;Performance Enhancements,"\
"refactor;Code Improvements,revert;Revert a Change,test;Tests,"\
"style;Stylistic Enhancements";

                # Initialise type description array
                split(TDV, KVP, ",");
                for (i in KVP)
                {
                    split(KVP[i], kvp, ";"); TYPE_DESC[kvp[1]] = kvp[2];
                }

                # Array traversal is ascending order by key
                PROCINFO["sorted_in"] = "@ind_str_asc";

                #
                # Process previously built associative array using:
                #
                # entries[type][category][short_hash] = \
                #     long_hash SUBSEP subject
                #
                for (type in entries)
                {
                    # Use type header description if known
                    if (type in TYPE_DESC)
                    {
                        printf("\n### %s\n", TYPE_DESC[type]);
                    }
                    else
                    {
                        printf("\n### Other\n");
                    }

                    for (category in entries[type])
                    {
                        for (short_hash in entries[type][category])
                        {
                            entry = entries[type][category][short_hash];
                            split(entry, values, SUBSEP);
                            long_hash = values[1];
                            # Restore subject whitespace
                            subject = gensub(/\+=\+/, " ", "g", values[2]);

                            # Cater for non-typed subject line
                            if (category == "EMPTY")
                            {
                                printf("* %s [%s](%s/%s)\n", \
                                       subject, short_hash, \
                                       REPO, long_hash);
                            }
                            else
                            {
                                printf("* **%s**:%s [%s](%s/%s)\n", \
                                       category, subject, short_hash, \
                                       REPO, long_hash);
                            }
                        }
                    }
                }
            }'
}

# ----------------------------------------------------------------------
# NAME:    main
# PARMS:   $1: (string), local git repository name
#          $2: (string), remote git repository URL
# RETURNS: $SUCCESS if all operations complete correctly
# PURPOSE: Application entry point function, performs the following:
# - Adjusts repo path and URL
# - Makes $1 the current directory
# - Traverse the git repository tree via `git log` invocations,
#   extracting commit metadata, and printing decorated metadata grouped
#   by tag in reverse tag date order i.e. most recent at the top
# - Restores previous directory context
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
            print_log_entries ${curr_tag} ${prev_tag} ${TARGET_REPO_URL}
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
        print_log_entries ${INITIAL_TAG_COMMIT} ${INITIAL_TAG_COMMIT} \
                          ${TARGET_REPO_URL}
    else
        print_log_entries ${INITIAL_TAG_COMMIT} ${prev_tag} \
                          ${TARGET_REPO_URL}
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

