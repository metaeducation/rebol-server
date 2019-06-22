CDN="https://metaeducation.s3.amazonaws.com/travis-builds"

function fail { echo $1; exit 1; }

function download { # src target
  echo "DOWNLOADING $1 ..."
  curl -s -L $1 -o $2
}

[ `which curl` ] || fail "Please put curl in PATH"

cd assets-src/system
i="load-r3.js"
download $CDN/$i $i
rm -fr 0.16.1 0.16.2
mkdir -p 0.16.1
mkdir -p 0.16.2

cd 0.16.1
  download "$CDN/0.16.1/last-deploy.short-hash" last-deploy.short-hash
  hash=`cat last-deploy.short-hash`
  [ $hash ] || fail "$i not found"
  for ext in js wasm worker.js bytecode; do
    download $CDN/0.16.1/libr3-$hash.$ext libr3.$ext
  done

cd ../0.16.2
  download "$CDN/0.16.2/last-deploy.short-hash" last-deploy.short-hash
  hash=`cat last-deploy.short-hash`
  [ $hash ] || fail "$i not found"
  for ext in js wasm worker.js js.mem; do
    download $CDN/0.16.2/libr3-$hash.$ext libr3.$ext
  done

cd ../../..

# vim: set et sw=2:
