%define Darwin__NR_write                         0x2000004
%define Linux__NR_write                          1

bits 64
default rel
global _start
section .text
_start:
                push        rdi
                push        rsi
                push        rdx

                call .banana
                db 'BANANA!',10
.banana         pop         rsi

                mov         rdx, 8
                mov         rdi, 1

                mov         rax, Darwin__NR_write
                syscall

                pop         rdx
                pop         rsi
                pop         rdi

                lea         rax, [rel entry_point]
                jmp         [rax]

entry_point     dq          0x1122334455667788

