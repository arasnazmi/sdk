#!/bin/bash

set -euo pipefail

BOLD="$(tput bold 2>/dev/null || echo '')"
GREY="$(tput setaf 8 2>/dev/null || echo '')"
UNDERLINE="$(tput smul 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
MAGENTA="$(tput setaf 5 2>/dev/null || echo '')"
CYAN="$(tput setaf 6 2>/dev/null || echo '')"
NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"
CLEAR_LAST_MSG="\033[1F\033[0K"

readonly BOLD GREY UNDERLINE RED GREEN YELLOW BLUE MAGENTA CYAN NO_COLOR CLEAR_LAST_MSG

print_err()
{
    local msg=$1

    echo -e "${BOLD}${RED}"'[ERR]'"${NO_COLOR} $msg"
}

print_progress()
{
    local msg=$1

    echo -e "${BOLD}${GREY}"'[...]'"${NO_COLOR} $msg"
}

print_ok()
{
    local msg=$1

    echo -e "${BOLD}${GREEN}"'[OK]'"${NO_COLOR} $msg"
}

upload_debs()
{
    local deb_folder deb_files resp code

    deb_folder=$1

    deb_files=$(find "$deb_folder" -mindepth 1 -maxdepth 1 -name '*.deb') || true

    if [ -z "$deb_files" ]; then
        print_err "No DEB file found in specified directory ($$deb_folder)"
        return 1
    fi

    for deb_file in $deb_files; do
        resp=$(curl -i -s --show-error \
            -X POST -F file=@"$deb_file" \
            -u "$API_AUTH" \
            "$SERVER_URL/api/files/pkgs" 2>&1) || true

        ret=$?
        code=$(echo "$resp" | head -n 1 | cut -d ' ' -f 2) || true

        if [ "$ret" != "0" ] || [ "$code" != "200" ]; then
            print_err "Upload failed! Status code: $code, DEB file: $deb_file"
            echo -e "\n\n$resp\n"
            return 1
        fi
    done

    return 0
}

import_debs_to_repo()
{
    local repo resp ret code

    repo=$1

    resp=$(curl -i -s --show-error \
        -X POST -u "$API_AUTH" \
        "$SERVER_URL/api/repos/$repo/file/pkgs" 2>&1) || true

    ret=$?
    code=$(echo "$resp" | head -n 1 | cut -d ' ' -f 2) || true

    if [ "$ret" != "0" ] || [ "$code" != "200" ]
    then
        print_err "Failed to import debs into repo. Status code: $code"
        echo -e "\n\n$resp\n"
        return 1
    fi

    json=$(echo "$resp" | sed -n '/^{/,${p}')
    added_count=$(echo "$json" | jq '.Report.Added | length')
    failed_count=$(echo "$json" | jq '.FailedFiles | length')
    warning_count=$(echo "$json" | jq '.Report.Warnings | length')

    echo -e '\n'
    echo "Number of added files: $added_count"
    echo "Number of failed files: $failed_count"

    if [ "$warning_count" -gt 0 ]; then
        echo ""
        echo "Warnings:"
        echo "$json" | jq -r '.Report.Warnings[]'
    fi

    echo -e '\n'

    return 0
}

create_snapshot()
{
    local repo distro ts resp ret code

    repo=$1
    distro=$2

    ts=$(date --utc +'%Y%m%d-%H%M')
    snapshot_name="$repo-$distro-$ts"

    resp=$(curl -i -s --show-error \
        -X POST -u "$API_AUTH" \
        -H "Content-Type: application/json" \
        -d '{"Name": "'"$snapshot_name"'"}' \
        "$SERVER_URL/api/repos/$repo/snapshots") || true

    ret=$?
    code=$(echo "$resp" | head -n 1 | cut -d ' ' -f 2) || true

    if [ "$ret" != "0" ] || [ "$code" != "201" ]
    then
        print_err "Failed to create snapshot. Status code: $code"
        echo -e "\n\n$resp\n"
        return 1
    fi
}

publish_snapshot()
{
    local repo snapshot resp ret code distribution

    repo=$1
    snapshot=$2
    distribution=$3

    json_str=$(
    cat <<EOF
{
    "SourceKind": "snapshot",
    "Sources": [
        {"Name": "$snapshot", "Component": "main"}
    ],
    "Distribution": "$distribution",
    "Signing": {
        "Passphrase": "$APTLY_GPG_PASS"
    }
}
EOF
)

    if [ "$repo" = "gemstone" ]; then
        json_str=$(echo "$json_str" | jq '.Architectures = ["amd64", "arm64"]')
    fi

    resp=$(curl -i -s --show-error \
        -X POST -u "$API_AUTH" \
        -H "Content-Type: application/json" \
        -d "$json_str" \
        "$SERVER_URL/api/publish/$repo") || true

    ret=$?
    code=$(echo "$resp" | head -n 1 | cut -d ' ' -f 2) || true

    if [ "$ret" != "0" ] || [ "$code" != "201" ]
    then
        print_err "Failed to publish snapshot. Status code: $code"
        echo -e "\n\n$resp\n"
        return 1
    fi
}

unpublish_repo()
{
    local repo distro resp ret code

    repo=$1
    distro=$2

    resp=$(curl -i -s --show-error \
        -X DELETE -u "$API_AUTH" \
        "$SERVER_URL/api/publish/$repo/$distro") || true

    ret=$?
    code=$(echo "$resp" | head -n 1 | cut -d ' ' -f 2) || true

    if [ "$ret" != "0" ] || [ "$code" != "200" ]
    then
        print_err "Failed to unpublish repo. Status code: $code"
        echo -e "\n\n$resp\n"
        return 1
    fi
}

DEB_DIR=$1
REPO_NAME=$2
DISTRO=$3

for cmd in curl jq sed; do
    if ! command -v "$cmd" &> /dev/null; then
        print_err "'$cmd' is not installed or not in PATH"
        exit 1
    fi
done

if [ ! -d "$DEB_DIR" ]; then
    print_err "Specified DEB_DIR ('$DEB_DIR') is not a folder or doesn't exist."
    exit 1
fi

if [ "$REPO_NAME" = "gemstone" ] && [ "$DISTRO" = "bsp" ]; then
    print_err "You can't set REPO_NAME to 'gemstone' if you are uploading 'bsp' DEB packages."
    exit 1
fi

if [ "$DISTRO" != "bsp" ] && [ "$REPO_NAME" != "gemstone" ]; then
    print_err "You have to set REPO_NAME to 'gemstone' if you are not uploading 'bsp' DEB packages."
    exit 1
fi

DESCRIPTION=$(
    cat <<EOF
  ${BOLD}Server: ${GREEN}${SERVER_URL}${NO_COLOR}
  ${BOLD}DEB Folder: ${GREEN}${DEB_DIR}${NO_COLOR}
  ${BOLD}Repository Name: ${GREEN}${REPO_NAME}${NO_COLOR}
  ${BOLD}Distribution: ${GREEN}${DISTRO}${NO_COLOR}

  This script will publish DEB packages under '$DEB_DIR' to '$SERVER_URL/$REPO_NAME'.
  Check if configuration above is correct.
EOF
)

printf "%s\n\n" "$DESCRIPTION"

while true; do
    read -r -p "Do you want to continue? (y/n): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done

printf "\n"

print_progress "Uploading DEB files"
upload_debs "$DEB_DIR" && print_ok "Uploaded DEB files to server" || exit 1

print_progress "Importing DEB files"
import_debs_to_repo "$REPO_NAME" && print_ok "Imported DEBs to '$REPO_NAME' repo" || exit 1

print_progress "Creating snapshot"
create_snapshot "$REPO_NAME" "$DISTRO" && print_ok "Created repo snapshot" || exit 1

print_progress "Unpublishing old snapshot"
unpublish_repo "$REPO_NAME" "$DISTRO" && print_ok "Unpublished old snapshot" || exit 1

print_progress "Publishing new snapshot"
publish_snapshot "$REPO_NAME" "$snapshot_name" "$DISTRO" && print_ok "Published newly created snapshot" || exit 1

echo -e "\nCheck new content from: ${SERVER_URL}/${REPO_NAME}"

exit 0
