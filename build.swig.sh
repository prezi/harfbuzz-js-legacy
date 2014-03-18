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
