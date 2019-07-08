%define Darwin__NR_write                         0x2000004
%define Darwin__NR_exit                          0x2000001

%define __NR_write                               1
%define __NR_exit                                60

bits 64
default rel
global _start
section .text
_start:
                
                lea         rsi, [rel hello]
                mov         rdx, 13                
                mov         rdi, 1

%ifidn __OUTPUT_FORMAT__, elf64
                mov         rax, __NR_write
%elifidn __OUTPUT_FORMAT__, macho64
                mov         rax, Darwin__NR_write
%endif 
                syscall


                xor         rdi, rdi

%ifidn __OUTPUT_FORMAT__, elf64
                mov         rax, __NR_exit
%elifidn __OUTPUT_FORMAT__, macho64
                mov         rax, Darwin__NR_exit
%endif                

                syscall

hello           db          "hello world",33,10,0

