# MobiMenu

MobiMenu is an open-source portal for multimedia display units. It's niche functionality is remarkably simple and designed for quick deployment and ease of use across multiple levels of technical aptitude.

## Installation Notes

* MobiMenu **only** operates for unix-based/like operating system due to its use of `fork`, a feature not supported on Windows. It is designed to operate on the Raspberry Pi 4 Model B.
* Users must enter framebuffer devices (devices labeled `fb*` in `ls /dev/`) and their aspect ratios in the `display.csv` file for them to be acknowledged by MobiMenu.
  * Columns are as follows: `framebuffer device`, `aspect ratio`, `human name`, `image name`
  * Example row: `fb0,16:9,Default Monitor,default.jpg`
* In addition to the framebuffer device, users are recommended to change the default password and session secret in their `.env` file so to prevent potentially unwanted changes.