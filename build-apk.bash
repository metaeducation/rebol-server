# USER CONFIG

NAME=rebol-server.apk
KEY=rebol-server.ks
PASSWORD=rebol-server
CLASSPATH="" # e.g. "java:libs/<your-lib>.jar"

# END USER CONFIG

echo "CHECKING SYSTEM ..."

function error { echo $1; exit 1; }

function check_tool {
    which $1 || error "Please provide $1 in the PATH."
}

function check_file {
    [ -f $1 ] || error "Please provide $1."
}

function check_var {
    name=`eval echo "$""$1"`
    [ $name ] || error "Please set $1."
}

for n in NAME KEY ANDROID_JAR
do check_var $n; done

check_file $ANDROID_JAR

for n in javac ecj; do
    JAVAC=`which $n`
    [ $JAVAC ] && break
done
[ $JAVAC ] || error "Please provide javac or ecj in the PATH."

for n in aapt dx apksigner zipalign
do check_tool $n; done

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
    || error "FAILED MAKING R.java"

echo "COMPILING *.class ..."
$JAVAC -d obj \
    `find java/ gen/ -name \*.java` \
    $OPT_BOOTCLASSPATH \
    $OPT_CLASSPATH \
    -source 1.7 -target 1.7 \
    || error "FAILED COMPILING *.class"

echo "COMPILING classes.dex ..."
dx --dex --output=./bin/classes.dex \
    ./obj \
    $SPLIT_CLASSPATH \
    || error "FAILED COMPILING classes.dex"

# If you have the error UNEXPECTED TOP-LEVEL EXCEPTION, 
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
    || error "BUILDING unaligned.apk ..."

# "classes.dex" must be in current dir !!
cd ./bin
    aapt add unaligned.apk classes.dex \
    || error "ADDING classes.dex TO unaligned.apk"
cd ..

case $HOME in
    /data/data/com.termux*)
        echo "ALIGNING+SIGNING unaligned.apk ..."
        apksigner -p $PASSWORD $KEY ./bin/unaligned.apk ./bin/$NAME \
        || error "FAILED ALIGNING+SIGNING unaligned.apk ..."
    ;;
    *)
        echo "ALIGNING unaligned.apk ..."
        zipalign -f 4 \
            ./bin/unaligned.apk \
            ./bin/$NAME \
        || error "FAILED ALIGNING unaligned.apk ..."
        echo "SIGNING $NAME ..."
        apksigner sign --ks $KEY ./bin/$NAME \
        || error "FAILED SIGNING $NAME ..."
    ;;
esac

echo "BUILT APP ./bin/$NAME"
