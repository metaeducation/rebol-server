CDN="https://aquilone.stream/home/ren-c/build"

function fail { echo $1; exit 1; }

[ `which curl` ] || fail "Please put curl in PATH"

function download { # src target
  echo "DOWNLOADING $1"
  curl -s $1 > $2
}

download $CDN/0.13.2/r3 r3
chmod a+x r3

# vim: set et sw=2:
