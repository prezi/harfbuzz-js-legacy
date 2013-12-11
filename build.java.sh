#!/bin/bash

if [ ! -d "swig/build/cpp/lib" ]; then
    mkdir -p swig/build/cpp/lib
fi

if [ ! -d "swig/build/java/com/prezi/harfbuzz" ]; then
    mkdir -p swig/build/java/com/prezi/harfbuzz
fi

if [ ! -d "build" ]; then
    mkdir build
fi

rm build/libharfbuzz*
rm swig/build/cpp/*.c
rm swig/build/cpp/*.h
rm swig/build/cpp/lib/*


echo "Generating JNI code with SWIG"
swig -cpperraswarn -java -package com.prezi.harfbuzz -outdir swig/build/java/com/prezi/harfbuzz -o swig/build/cpp/harfbuzz_wrap.c -oh swig/build/cpp/harfbuzz_wrap.h src/harfbuzz.i

cd swig/build/java
find . -name "*.java" | xargs javac
cd -

if [ ! -x "./configure" ]; then
    ./autogen.sh
fi

export LDFLAGS="-pipe -Os -no-cpp-precomp -fPIC -fno-strict-aliasing"
export CFLAGS=${LDFLAGS}
export CXXFLAGS=${LDFLAGS}


export INSTALL_DIR=$(pwd)/build

#ugly way to find jni.h automatically (with a chance that it will be int the sdk7)
JNIHEADERS=/System/Library/Frameworks/JavaVM.framework/Headers
#`locate jni_md.h | grep 7 | head -n 1 | xargs dirname`


#if [ $? -ne 0 ]; then
#    JNIHEADERS=/System/Library/Frameworks/JavaVM.framework/Headers
#    echo "Unable to find jni.h with locate using default"
#fi
echo "JNIHEADERS=${JNIHEADERS}"

./configure --prefix=$INSTALL_DIR --disable-shared --enable-static && make clean >/dev/null && make -j && cp src/.libs/libharfbuzz.a build/harfbuzz.a

echo "### compile wrapper"
CFLAGS="${CFLAGS} $(pkg-config --cflags --libs glib-2.0)"
gcc ${CFLAGS} -I ./src -I $JNIHEADERS  -I/usr/local/Cellar/glib/2.38.2/include/glib-2.0 -I/usr/local/Cellar/glib/2.38.2/lib/glib-2.0/include -pipe -Os -no-cpp-precomp -shared -o swig/build/cpp/lib/harfbuzz_wrap.so swig/build/cpp/harfbuzz_wrap.c  build/harfbuzz.a -Bstatic
