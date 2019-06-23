%include "famine.inc"

BUF_SIZE    equ 1024
LOCAL_VARS  equ 1024

bits 64
default rel
global _start
section .text

strlen:         xor     rax, rax
.loop:          cmp     byte [rax + rdi], 0
                jz      .done
                inc     rax
                jmp     .loop
.done:          ret


puts:           call    strlen
                mov     rdx, rax
                mov     rsi, rdi
                mov     rdi, 1
                mov     rax, __NR_write
                syscall
                ret

patsy_host:     lea     rdi, [rel hello]
                call    puts

                xor     rdi, rdi
                mov     rax, __NR_exit
                syscall
hello           db "hello world",33,10,0


_start:
                lea     rdi, [rel slash_tmp]
                mov     rsi, O_RDONLY | O_DIRECTORY
                mov     rax, __NR_open
                syscall
                test    rax, rax
                jl      finish

                mov     r15, rax                            ; save directory fd in r15

                mov     rdi, r15
                mov     rax, __NR_fchdir
                syscall
                test    rax, rax
                jl      finish

                mov     r14, rsp
                sub     r14, BUF_SIZE + LOCAL_VARS          ; save buf ptr in r14

scandir:        mov     rdx, BUF_SIZE
                mov     rdi, r15
                mov     rsi, r14
                mov     rax, __NR_getdents64
                syscall
                test    rax, rax
                jle     scandir_done

                mov     r13, rax                            ; nread from getdents64
                xor     r12, r12

scandir_file:   lea     rdi, [r14 + r12]                    ; rdi = struct linux_dirent64*
                cmp     byte [rdi + 18], DT_REG
                jne     scandir_next

                add     rdi, 19                             ; d_name[]
                call    puts

scandir_next:
                lea     rdi, [r14 + r12]
                movzx   rax, word [rdi + 16]                ; d_reclen
                add     r12, rax
                cmp     r12, r13
                jl      scandir_file
                jmp     scandir

scandir_done:   mov     rdi, r15
                mov     rax, __NR_close
                syscall
finish:
                jmp     [rel entry]

slash_tmp   db "/tmp",0
entry       dq patsy_host
