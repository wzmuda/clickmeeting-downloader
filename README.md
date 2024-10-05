# ClickMeeting Downloader

ClickMeeting Downloader is a Bash script to for downloading recorded webinars from ClickMeeting.
Given the recording website URL, it will find the necessary information and download the video to a single file.

## Disclaimer

The name 'Clickmeeting' is used solely for informational and descriptive purposes to refer to the service provided by
ClickMeeting Sp. z o. o. This program is not affiliated, associated, authorized, endorsed by, or in any way officially
connected with ClickMeeting Sp. z o. o., or any of its subsidiaries or affiliates. All rights in the 'Clickmeeting'
name are the property of ClickMeeting Sp. z o. o.

This program is designed to operate in a manner similar to a standard web browser. It does not engage in any activities
that bypass or compromise security protocols. The program merely automates actions that a typical user would perform
manually through a web browser interface, adhering to the same security restrictions and permissions.

Users are reminded to utilize this program responsibly and in compliance with all applicable terms of service and laws.

## Requirements

The script was tested on macOS Sonoma and Sequoia with GNU bash, version 3.2.57(1)-release.
It is likely to work everywhere else, but it has never been tested on other systems.

- `curl`
- `sed`
- `awk`
- `grep`
- `mktemp`

## Usage

To use ClickMeeting Downloader, simply provide the URL of the webpage containing the recording.

```bash
$ ./clickmeeting_downloader.sh https://example.clickmeeting.com/webinar-recording/somethingsomething/someVeryLongId

<legal warning>

Video title: The_Best_Bober_Videos...
Downloading segment 1...
Downloading segment 2...
Downloading segment 3...
No more segments found. Download finished.
Video saved to The_Best_Bober_Videos.ts.
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
