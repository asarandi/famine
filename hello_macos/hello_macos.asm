__NR_write                          equ 0x2000004
__NR_exit                           equ 0x2000001

bits 64
default rel
global _start
section .text
_start:

;                xor         eax, eax
;                sub         rax, 16
;                and         rsp, rax
                
                lea         rsi, [rel hello]
                mov         rdx, 13                
                mov         rdi, 1
                mov         rax, __NR_write
                syscall

                xor         rdi, rdi
                mov         rax, __NR_exit
                syscall

;                xor         rax, rax
;                ret

hello           db          "hello world",33,10,0

