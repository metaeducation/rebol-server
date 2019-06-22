CDN="https://metaeducation.s3.amazonaws.com/travis-builds"

function fail { echo $1; exit 1; }

[ `which curl` ] || fail "Please put curl in PATH"

function download { # src target
  echo "DOWNLOADING $1"
  curl -s $1 > $2
}

download "$CDN/0.13.2/last-deploy.short-hash" last-deploy.short-hash
hash=`cat last-deploy.short-hash`
[ $hash ] || fail "$i not found"
download $CDN/0.13.2/r3-$hash r3
rm last-deploy.short-hash

# vim: set et sw=2:
