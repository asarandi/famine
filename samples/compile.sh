#!/bin/bash

PLATFORM=$(uname -s)

if [ "$PLATFORM" == "Darwin" ]; then

    rm -f hello_darwin_dynamic hello_darwin_nopie hello_darwin_static hello_darwin.o
#
#    nasm -f macho64 -o hello_darwin.o hello.asm
#
#    ld         -macosx_version_min 10.7 -arch x86_64 -e _start hello_darwin.o -o hello_darwin_dynamic
#    ld -no_pie -macosx_version_min 10.7 -arch x86_64 -e _start hello_darwin.o -o hello_darwin_nopie
#    ld -static -macosx_version_min 10.7 -arch x86_64 -e _start hello_darwin.o -o hello_darwin_static

    cc          hello.c -o hello_darwin_dynamic

fi


if [ "$PLATFORM" == "Linux" ]; then

    rm -f hello_linux_dynamic hello_linux_nopie hello_linux_static hello_linux.o
#
#    nasm -f elf64 -o hello_linux.o hello.asm
#
#    ld         -e _start hello_linux.o -o hello_linux_dynamic
#    ld -no_pie -e _start hello_linux.o -o hello_linux_nopie
#    ld -static -e _start hello_linux.o -o hello_linux_static

    cc          hello.c -o hello_linux_dynamic
    cc -no-pie  hello.c -o hello_linux_nopie
    cc -static  hello.c -o hello_linux_static

fi
    
