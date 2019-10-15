[ -e r3 ] \
|| bash update-r3.bash

[ -e assets-src/system/load-r3.js ] \
|| bash update-libr3-js.bash

bash build-assets.bash

bash build-apk.bash

# vim: set et sw=2:
