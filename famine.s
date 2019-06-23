%include "unistd_64.inc"
%include "fcntl.inc"

bits 64
default rel
global _start
section .text

strlen:     xor     rax, rax           
.loop:      cmp     byte [rax + rdi], 0
            jz      .done
            inc     rax
            jmp     .loop
.done:      ret


puts:       call    strlen
            mov     rdx, rax
            mov     rsi, rdi
            mov     rdi, 1
            mov     rax, __NR_write
            syscall
            ret

_start:
            lea     rdi, [rel msg]
            call    puts

            lea     rdi, [rel slash_tmp]
            mov     rsi, O_RDONLY | O_DIRECTORY
            mov     rax, __NR_open
            syscall

            mov     r15, rax
            mov     rdi, rax
            lea     rsi, [rel ptr]
            mov     rdx, 32768
            mov     rax, __NR_getdents64
            syscall

            mov     rdi, r15
            mov     rax, __NR_close
            syscall


            xor     rdi, rdi
            mov     rax, __NR_exit
            syscall
msg         db "hello world",33,10,0
slash_tmp   db ".",0
ptr         times 0x1000 db 0
