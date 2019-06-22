REPLPAD_JS_ZIP_URL="https://github.com/hostilefork/replpad-js/archive/master.zip"
LOAD_R3_URL="https://metaeducation.s3.amazonaws.com/travis-builds/load-r3.js"

function warn { failed=y; echo "$1"; }

function check_tools { # tools ...
    while [ "$1" ]; do
        [ `which $1` ] || warn "* Please install $1"
        shift
    done
}

check_tools curl unzip sed

if [ $failed ]; then exit 1; fi

curl -s -L $REPLPAD_JS_ZIP_URL > replpad-js-master.zip
unzip replpad-js-master.zip
rm -rf assets-src/apps/r3-console
mv replpad-js-master assets-src/apps/r3-console
rm -f replpad-js-master.zip

sed -i "s=$LOAD_R3_URL=/system/load-r3.js=" assets-src/apps/r3-console/index.html
