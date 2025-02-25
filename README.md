# viewer-build-util

This repository contains distinct composite actions referenced by
[AlchemyViewer/Alchemy](https://github.com/AlchemyViewer/Alchemy). Information about
each action is contained in its own README.

These are actions are separate from the main viewer repository so that if any
of these operations fails in a way that requires modifying the action to retry
it, we can make that modification and rerun the specific job that engages it.
If this code was resident in the viewer repository, any such modification
would require a full viewer rebuild before retrying the failing operation.

[post-bugsplat-mac](post-bugsplat-mac/README.md)

[post-bugsplat-windows](post-bugsplat-windows/README.md)

[release-artifacts](release-artifacts/README.md)

[sign-pkg-mac](sign-pkg-mac/README.md)

[sign-pkg-windows](sign-pkg-windows/README.md)

[which-branch](which-branch/README.md)
