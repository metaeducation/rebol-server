# USER CONFIG

NAME=rebol-server.apk
KEYSTORE=rebol-server.ks
PASSWORD=android
ANDROID_JAR=../android.jar
CLASSPATH="" # e.g. "java:libs/<your-lib>.jar"

# see https://androidsdkmanager.azurewebsites.net/SDKPlatform
ANDROID_JAR_URL="https://github.com/giuliolunati/android-devel/raw/master/android-28.6-9.0.jar"

# END USER CONFIG

function fail { echo "$1"; exit 1; }

function check_files { # files ...
    for i in "$@"; do
        name=`eval echo "$""$i"`
        [ -e $name ] || fail "* Please provide $i"
    done
}

function check_tools { # tools ...
    while [ "$1" ]; do
        [ `which $1` ] || fail "* Please install $1"
        shift
    done
}

function check_vars { # vars ...
    for i in "$@"; do
        name=`eval echo "$""$i"`
        [ $name ] || fail "* Please set $i"
    done
}

function download { # src target
  echo "DOWNLOADING $1 ..."
  curl -s -L $1 -o $2
}


echo "CHECKING SYSTEM ..."

check_vars NAME KEYSTORE PASSWORD ANDROID_JAR

if [[ $HOME =~ com.termux/files/ ]]
then TERMUX=yes; else TERMUX=""; fi

check_tools aapt apksigner zipalign curl

tmp=`apksigner -h 2>&1 | head -n 1`
if echo $tmp | grep password > /dev/null
then # old Termux apksigner
    APKSIGNER_CMD="apksigner -p $PASSWORD $KEYSTORE bin/unaligned.apk bin/$NAME"
elif echo $tmp | grep -i usage > /dev/null
then # standard apksigner
    APKSIGNER_CMD="apksigner sign --ks-pass env:PASSWORD --ks $KEYSTORE bin/$NAME"
else # unknown/broken apksigner
    fail "*** this version of apksigner is unsupported/broken\
    In Termux you can try old version:
    http://termux.net/dists/stable/main/binary-all/apksigner_0.7-2_all.deb"
fi

for n in dalvik-exchange dx; do
    DX=`which $n` || continue
    [ $DX ] && break
done
[ $DX ] || fail "* Please install dalvik-exchange or dx"
if [[ $DX =~ dx$ ]]
then
    if $DX -h 2>&1 |grep -- --dex >/dev/null;     then :
    else fail "* Please install dalvik-exchange"
    fi
fi

for n in javac ecj; do
    JAVAC=`which $n` || continue
    [ $JAVAC ] && break
done
[ $JAVAC ] || fail "* Please install javac or ecj"

[ -f $ANDROID_JAR ] \
|| download $ANDROID_JAR_URL $ANDROID_JAR \
|| check_files $ANDROID_JAR


I_BOOTCLASSPATH="-I $ANDROID_JAR"
OPT_BOOTCLASSPATH="-bootclasspath $ANDROID_JAR
"

if [ $CLASSPATH ]; then
    SPLIT_CLASSPATH="`echo $CLASSPATH | sed 's/:/ /g'`"
    OPT_CLASSPATH="-classpath $CLASSPATH"
fi

# CHECKING FOLDERS 

for i in assets bin gen obj res; do 
    if [[ ! -e "$i" ]]
    then mkdir -p "$i"
    fi
done
rm -rf gen/* bin/* obj/*

echo " OK." # System checked



echo "MAKING R.java ..."
aapt package -f -m -J ./gen \
    -M ./AndroidManifest.xml \
    -S ./res \
    $I_BOOTCLASSPATH \
    || fail "FAILED MAKING R.java"
echo " OK."


echo "COMPILING *.class ..."
$JAVAC -d obj \
    `find java/ gen/ -name \*.java` \
    $OPT_BOOTCLASSPATH \
    $OPT_CLASSPATH \
    -source 1.7 -target 1.7 \
    || fail "FAILED COMPILING *.class"
echo " OK."


echo "COMPILING classes.dex ..."
dalvik-exchange --dex --output=./bin/classes.dex \
    ./obj \
    $SPLIT_CLASSPATH \
    || fail "FAILED COMPILING classes.dex"
echo " OK."

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
    || fail "*** 'aapt package 'FAILED ***"

# "classes.dex" must be in current dir !!
cd ./bin
    aapt add unaligned.apk classes.dex > /dev/null\
    || fail "*** 'aapt add 'FAILED ***"
cd ..
echo " OK."

echo "ALIGNING unaligned.apk ..."
zipalign -f 4 \
    ./bin/unaligned.apk \
    ./bin/$NAME \
|| fail "zipalign FAILED"
echo " OK."

echo "SIGNING $NAME ..."
$APKSIGNER_CMD || fail "FAILED SIGNING $NAME"
echo " OK."

echo "BUILT APP ./bin/$NAME"

# vim: set et sw=4:
