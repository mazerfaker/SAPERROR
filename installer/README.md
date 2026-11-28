# SAPERROR Setup — Retro Windows 98

The selected release installer is the single Retro98 frontend, using the unchanged approved artwork and red glitch gear icon. CRT setup is no longer packaged. Gray classic controls, navy header, inset artwork and status, localized EN/UK interface. Shared Inno payload, per-user install, optional desktop shortcut, launch, and uninstall. No game save deletion. File name SAPERROR_Setup.exe; ZIP SAPERROR_v<version>_Setup.zip.

## Privacy choice

Optional analytics checkbox starts unchecked on every setup. The frontend saves the explicit choice after successful installation to the current user's Godot app data folder, analytics_consent.txt (v1:allow or v1:deny). Game Settings > Privacy reads and changes this same preference. Missing, unreadable or unrecognized data defaults to off. This build sends no telemetry and includes no analytics endpoint. A future implementation must describe actual fields, purpose, retention, and recipient, implement revocation and obtain informed consent appropriate to that implementation before sending anything. The local preference is not a blanket authorization for unspecified future data collection.

Approved artwork: installer/setup_art.png SHA-256 eff5e285bc85bb9b14a885af57db1c13c9b6257687f3a7598e735c6695f3a31f. Icon: installer/setup_icon.ico SHA-256 bad834b2b509d0e453a85da0edb4d67f6040540a85cefa63e8423246ea9fb1e6. Both are preserved. Build: installer/build.ps1 -Version 0.9.0-rc.6 -Smoke. CI verifies snapshot default opt-out, allow/deny persistence in an isolated file, installed payload hashes and uninstall. Signing and commercial licensing review remain pending.
