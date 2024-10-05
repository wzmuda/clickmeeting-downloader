#!/bin/bash
#
# Clickmeeting Downloader
#
# Copyright (c) 2024 Wojciech Żmuda
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Print legal information about the program.
legal_stuff() {
    echo "
Clickmeeting Downloader

DISCLAIMER:
    The name 'Clickmeeting' is used solely for informational and descriptive
    purposes to refer to the service provided by ClickMeeting Sp. z o. o.
    This program is not affiliated, associated, authorized, endorsed by, or in
    any way officially connected with ClickMeeting Sp. z o. o., or any of its
    subsidiaries or affiliates. All rights in the 'Clickmeeting' name are the
    property of ClickMeeting Sp. z o. o.

    This program is designed to operate in a manner similar to a standard web
    browser. It does not engage in any activities that bypass or compromise
    security protocols. The program merely automates actions that a typical
    user would perform manually through a web browser interface, adhering to
    the same security restrictions and permissions.

    Users are reminded to utilize this program responsibly and in compliance
    with all applicable terms of service and laws.
    "

    read -r -p "Press <enter> to confirm or 'q' to exit: " input
    if [ "${input}" == "q" ]; then
        exit 1
    fi
    echo
}

# Check if the system contains all required commands.
check_required_commands() {
    local required_commands=("curl" "sed" "awk" "grep" "mktemp")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed."
            exit 1
        fi
    done
}

# Check input parameters and print help if the script was not called properly.
check_usage() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: ${0} <page_url>"
        exit 1
    fi
}

# Fetch the HTML content of the page.
get_website() {
    local page_url="$1"
    local html=$(curl -s "${page_url}")
    echo "${html}"
}

# Extract recording title from the website contents.
get_video_title() {
    local html_content="$1"
    local title=$(echo "${html_content}" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' | sed 's/[[:space:]]/_/g')
    echo "${title}"
}

# Extract base URL of video segments from the website.
get_video_url() {
    local html_content="$1"

    local video_url=$(echo "${html_content}" | sed -n 's/.*url="\([^"]*\.mp4\)".*/\1/p')

    if [ -z "${video_url}" ]; then
        echo "Error: No recording URL found in the page."
        exit 1
    fi

    # Extract the list of CDN servers where the video is hosted and pick the first one.
    # TODO:
    # I guess I should take advantage of this redundancy and loop until I find the working one,
    # but so far the first one was always alive so I leave this as is.
    local servers_list=$(echo "${html_content}" | grep 'publishedRecording\.nginxList' | sed -E 's/.*publishedRecording\.nginxList\s*=\s*\[([^]]*)\].*/\1/')
    servers_list=$(echo "${servers_list}" | tr -d '[]" ' | tr ',' '\n' | sed 's/\\//g')
    if [ -z "${servers_list}" ]; then
        echo "Error: No servers list found in the page. Are you sure the link is valid?"
        exit 1
    fi
    local base_server_url=$(echo "${servers_list}" | head -n 1 | cut -d= -f2)
    
    echo "${base_server_url}/storage/files/${video_url}"
}

# Downloads video segments from the base URL starting at 1 to the given directory.
# Since the number of segments is unknown, the download stops at first HTTP error.
download_segments() {
    local base_url="${1}"
    local download_dir="${2}"

    local segment=1
    while true; do
        local url="${base_url}/seg-${segment}-v1-a1.ts"
        
        # Check if the segment exists by making a HEAD request
        local http_status=$(curl -s -o /dev/null -w "%{http_code}" "${url}")
        if [ "${http_status}" -ne 200 ]; then
            echo "No more segments found. Download finished."
            break
        fi

        echo "Downloading segment ${segment}..."
        curl -s -o "${download_dir}/seg-${segment}-v1-a1.ts" "${url}"

        segment=$(( segment + 1 ))
    done
}

# Combines dowloaded video segments from the given directory into one file in the given path.
combine_segments() {
    local output_file="${1}"
    local input_dir="${2}"

    # Remove the output file if it exists
    if [ -f "${output_file}" ]; then
        rm "${output_file}"
    fi

    # Create a temporary file to hold segment filenames and their indices
    local tmp_file=$(mktemp)

    # Read the segments and store them in the temporary file
    for segment in ${input_dir}/seg-*-v1-a1.ts; do
        num=$(echo "${segment}" | sed -E 's/.*seg-([0-9]+)-v1-a1\.ts/\1/')
        echo "${num} ${segment}" >> "${tmp_file}"
    done

    # Sort the temporary file by the segment numbers and concatenate the segments into the output file
    sort -n "${tmp_file}" | while read -r num segment; do
        cat "${segment}" >> "${output_file}"
    done

    # Clean up the temporary file
    rm "${tmp_file}"
}

main() {
    legal_stuff
    check_required_commands
    check_usage "${@}"

    local page_url="${1}"
    local html_content=$(get_website "${page_url}")
    local title=$(get_video_title "${html_content}")
    echo -e "Video title: ${title}\n"
    local base_url=$(get_video_url "${html_content}")

    # Create a directory for downloaded files
    local download_dir=$(mktemp -d)

    download_segments "${base_url}" "${download_dir}"

    # Output file name
    local output_file="${title}.ts"
    combine_segments "${output_file}" "${download_dir}"
    echo -e "\nVideo saved to ${output_file}"

    rm -r "${download_dir}"
}

main "${@}"
