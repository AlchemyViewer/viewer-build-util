## sign-pkg-windows

Retrieve and unpack the `Windows-app` artifact from the preceding viewer build. Sign each of the embedded executables using the specified certificate, then run Innosetup ISCC to package an installer (using files previously bundled into the `Windows-app` artifact). Sign the installer, then post it as a new artifact.

| Input | Description |
| ----- | ----------- |
| certificate | path to certificate file |
