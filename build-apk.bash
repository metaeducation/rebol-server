# USER CONFIG

NAME=rebol-server.apk
KEY=rebol-server.ks
PASSWORD=rebol-server
ANDROID_JAR=./android.jar
CLASSPATH="" # e.g. "java:libs/<your-lib>.jar"
ANDROID_JAR_URL="https://github.com/giuliolunati/android-devel/raw/master/android-23/android.jar"

# END USER CONFIG

echo "CHECKING SYSTEM ..."

function fail { echo "$1"; exit 1; }

function warn { failed=y; echo "$1"; }

function check_tools { # tools ...
    while [ "$1" ]; do
        [ `which $1` ] || warn "* Please install $1"
        shift
    done
}

function check_vars { # vars ...
    for i in "$@"; do
        name=`eval echo "$""$i"`
        [ $name ] || warn "* Please set $i"
    done
}

function download { # src target
  echo "DOWNLOADING $1 ..."
  curl -s -L $1 -o $2
}

check_vars NAME KEY ANDROID_JAR

check_tools aapt dx apksigner zipalign curl

for n in javac ecj; do
    JAVAC=`which $n`
    [ $JAVAC ] && break
done
[ $JAVAC ] || warn "* Please install javac or ecj"

[ -f $ANDROID_JAR ] \
|| download $ANDROID_JAR_URL $ANDROID_JAR \
|| check_file $ANDROID_JAR

if [ $failed ]; then exit 1; fi

I_BOOTCLASSPATH="-I $ANDROID_JAR"
OPT_BOOTCLASSPATH="-bootclasspath $ANDROID_JAR"

if [ $CLASSPATH ]; then
    SPLIT_CLASSPATH="`echo $CLASSPATH | sed 's/:/ /g'`"
    OPT_CLASSPATH="-classpath $CLASSPATH"
fi

echo "CHECKING FOLDERS ..."
for i in assets bin gen obj res; do 
    if [[ ! -e "$i" ]]
    then mkdir -p "$i"
    fi
done
rm -rf gen/* bin/* obj/*

echo "SYSTEM OK."

echo "MAKING R.java ..."
aapt package -f -m -J ./gen \
    -M ./AndroidManifest.xml \
    -S ./res \
    $I_BOOTCLASSPATH \
    || fail "FAILED MAKING R.java"

echo "COMPILING *.class ..."
$JAVAC -d obj \
    `find java/ gen/ -name \*.java` \
    $OPT_BOOTCLASSPATH \
    $OPT_CLASSPATH \
    -source 1.7 -target 1.7 \
    || fail "FAILED COMPILING *.class"

echo "COMPILING classes.dex ..."
dx --dex --output=./bin/classes.dex \
    ./obj \
    $SPLIT_CLASSPATH \
    || fail "FAILED COMPILING classes.dex"

# If you have the fail UNEXPECTED TOP-LEVEL EXCEPTION, 
# it can be because you use old build tools
# and DX try to translate java 1.7 rather than 1.8.
# To solve the problem, you have to specify 1.7 java version in the previous javac command

echo "BUILDING unaligned.apk ..."
aapt package -f -m \
    -F ./bin/unaligned.apk \
    -M ./AndroidManifest.xml \
    -A ./assets \
    -S ./res \
    $I_BOOTCLASSPATH \
    || fail "BUILDING unaligned.apk ..."

# "classes.dex" must be in current dir !!
cd ./bin
    aapt add unaligned.apk classes.dex \
    || fail "ADDING classes.dex TO unaligned.apk"
cd ..

case $HOME in
    /data/data/com.termux*)
        echo "ALIGNING+SIGNING unaligned.apk ..."
        apksigner -p $PASSWORD $KEY ./bin/unaligned.apk ./bin/$NAME \
        || fail "FAILED ALIGNING+SIGNING unaligned.apk ..."
    ;;
    *)
        echo "ALIGNING unaligned.apk ..."
        zipalign -f 4 \
            ./bin/unaligned.apk \
            ./bin/$NAME \
        || fail "FAILED ALIGNING unaligned.apk ..."
        echo "SIGNING $NAME ..."
        apksigner sign --ks $KEY ./bin/$NAME \
        || fail "FAILED SIGNING $NAME ..."
    ;;
esac

echo "BUILT APP ./bin/$NAME"
