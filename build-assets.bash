# CONFIG

function error { echo $1; exit 1; }

[ $R3 ] || error "Please export R3=/path/to/r3-android-executable"

i=`which zip`
[ $i ] || error "Please put zip in PATH"

rm -rf assets
mkdir assets
mkdir -p assets-src/system

#

cd assets-src

zip -r0 ../assets/install.zip \
  system/ \
  replpad-js/

cp install.sh ../assets
cp $R3 ../assets

cd .. # base dir

# vim: set et sw=2:
