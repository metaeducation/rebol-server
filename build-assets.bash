# CONFIG

LOAD_R3_URL="https://metaeducation.s3.amazonaws.com/travis-builds/load-r3.js"

function error { echo $1; exit 1; }

[ $R3 ] || error "Please export R3=/path/to/r3-android-executable"

i=`which zip`
[ $i ] || error "Please put zip in PATH"

rm -rf assets
mkdir assets
mkdir -p assets-src/system

# BUILD

cd assets-src

zip -r0 ../assets/install.zip system/

mv apps/r3-console/index.html .tmp
grep $LOAD_R3_URL .tmp || error "Can't find $LOAD_R3_URL in r3-console/index.html"
sed "s@$LOAD_R3_URL@/system/load-r3.js@" .tmp > apps/r3-console/index.html
zip -r0 ../assets/install.zip apps/r3-console/
mv .tmp apps/r3-console/index.html

cp install.sh ../assets
cp $R3 ../assets

cd .. # base dir

# vim: set et sw=2:
