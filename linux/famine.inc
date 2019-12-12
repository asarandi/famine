%define ELF_SYSV                                 0x00010102464c457f
%define ELF_GNU                                  0x03010102464c457f
%define ELF64_ET_DYN                             0x00000001003e0003
%define ELF64_ET_EXEC                            0x00000001003e0002

%define __NR_write                               1
%define __NR_exit                                60
%define __NR_open                                2
%define __NR_close                               3
%define __NR_fstat                               5
%define __NR_mmap                                9
%define __NR_munmap                              11
%define __NR_getdents                            78
%define __NR_chmod                               90

%define O_RDONLY                                 0o0000000
%define O_RDWR                                   0o0000002
%define O_DIRECTORY                              0o0200000

%define DT_REG                                   8

%define PROT_READ                                0x1
%define PROT_WRITE                               0x2
%define MAP_SHARED                               0x01

	struc	dirent
.d_ino:		resq	1
.d_off:		resq	1
.d_reclen	resw	1
.d_name		resb	1
	endstruc
