[ $R3 ] || {
  echo "Please export R3=/path/to/r3-android-executable"
  exit 1
}

rm -rf assets
mkdir assets

cd assets-src
zip -r0 ../assets/install.zip \
  system/
cp install.sh ../assets
cp $R3 ../assets
cd
