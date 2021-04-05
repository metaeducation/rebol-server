# %build.bash

# Make it so that errors exit the script (use
# `source` instead of `bash` to inherit this
# script's modes when running subscripts)
#
set -e

if [ ! -e r3 ]; then
  echo "r3 binary not found"
  echo "fetching prebuilt" 
  source update-r3.bash
fi

if [ ! -e assets-src/system/load-r3.js ]; then
  echo "Wasm build not found in assets-src/system/"
  echo "fetching Wasm build from Amazon S3" 
  source update-libr3-js.bash
fi

source build-assets.bash

source build-apk.bash

# vim: set et sw=2:
