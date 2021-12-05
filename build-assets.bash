# CONFIG

LOAD_R3_URL="https://metaeducation.s3.amazonaws.com/travis-builds/load-r3.js"

function fail { echo "$1"; exit 1; }

function warn { failed=y; echo "$1"; }

function check_tools { # tools ...
    while [ "$1" ]; do
        [ `which $1` ] || warn "* Please install $1"
        shift
    done
}

check_tools find zip

if [ $failed ]; then exit 1; fi

# CLEAN

echo "CLEANING ..."

rm -rf assets
mkdir assets
find assets-src -name \*~ -exec rm \{\} \;

# BUILD

echo "BUILDING ASSETS ..."

mkdir -p assets-src/system
cp rebol-httpd/httpd.reb assets-src/system/
cp rebol-httpd/webserver.reb assets-src/system/
cp -r r3-console assets-src/apps
sed -i "s=$LOAD_R3_URL=/system/load-r3.js=" assets-src/apps/r3-console/index.html

cd assets-src

zip -r0 ../assets/install.zip *
cp install.sh ../assets
cp ../r3 ../assets

cd .. # base dir

# vim: set et sw=2:
