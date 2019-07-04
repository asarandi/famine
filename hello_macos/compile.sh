#!/bin/bash

rm -f a.out hello_macos_dynamic hello_macos_nopie hello_macos_static hello_macos.o

nasm -f macho64 hello_macos.asm

ld         -macosx_version_min 10.7 -arch x86_64 -e _start hello_macos.o -o hello_macos_dynamic
ld -no_pie -macosx_version_min 10.7 -arch x86_64 -e _start hello_macos.o -o hello_macos_nopie
ld -static -macosx_version_min 10.7 -arch x86_64 -e _start hello_macos.o -o hello_macos_static

#strip hello_macos_dynamic
#strip hello_macos_nopie
#strip hello_macos_static
