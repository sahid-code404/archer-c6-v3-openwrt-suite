# Contributing

Thank you for improving the Archer C6 V3 OpenWrt Suite.

## Before opening an issue

Include:

- Router model and hardware revision
- OpenWrt release and build type
- Output of `cat /tmp/sysinfo/board_name`
- Whether the issue occurred after a clean flash or keep-settings upgrade
- Relevant system or service logs with secrets removed
- Clear reproduction steps

## Pull requests

1. Keep the UI and behaviour stable unless the change explicitly targets the UI.
2. Do not add private credentials, WAN addresses, MAC addresses, or keys.
3. Run `sh -n firstboot.sh`.
4. Check that embedded shell, JavaScript, and JSON content remains valid.
5. Keep the script below the Firmware Selector first-boot size limit.
6. Update `CHANGELOG.md` and the README when behaviour changes.

## Design principles

- Prefer OpenWrt UCI and service interfaces over one-off state.
- Avoid overlapping queue managers or firewall frameworks.
- Preserve SQM, traffic accounting, and Device Control compatibility.
- Use atomic or validated firewall transactions.
- Keep background polling and flash writes conservative.
