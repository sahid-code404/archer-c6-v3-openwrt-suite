# Security policy

## Supported version

Security fixes are applied to the latest repository release.

## Reporting a vulnerability

Do not publish sensitive router data in a public issue. Remove or redact:

- Public or static WAN addresses
- ISP credentials
- PPPoE usernames and passwords
- Wi-Fi passwords
- Root passwords or SSH keys
- MAC addresses when privacy matters
- Configuration backups

Open a private security advisory in GitHub when available, or contact the maintainer privately.

## Deployment warnings

- The included Wi-Fi passwords are public placeholders and must be changed.
- Set a strong OpenWrt root password immediately.
- LuCI is HTTP-only in this project. Keep management on a trusted LAN and never expose port 80 or SSH to the WAN.
- The script is restricted to `tplink,archer-c6-v3`, but users must still verify the exact device and hardware revision before flashing.
- Back up the router before installation or upgrade.
