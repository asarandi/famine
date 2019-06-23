%include "unistd_64.inc"

global _start

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

            xor     rdi, rdi
            mov     rax, __NR_exit
            syscall

msg         db "hello world",33,10,0
