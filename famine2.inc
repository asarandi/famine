%define ELF_SYSV                                 0x00010102464c457f
%define ELF_GNU                                  0x03010102464c457f
%define ELF64_ET_DYN                             0x00000001003e0003
%define ELF64_ET_EXEC                            0x00000001003e0002

; https://opensource.apple.com/source/xnu/xnu-4903.221.2/bsd/kern/syscalls.master.auto.html
; 196	AUE_GETDIRENTRIES	ALL	{ int getdirentries(int fd, char *buf, u_int count, long *basep); } 

%define __NR_write                               1
%define __NR_exit                                60
%define __NR_open                                2
%define __NR_close                               3
%define __NR_fstat                               5
%define __NR_mmap                                9
%define __NR_munmap                              11
%define __NR_getdents                            78
%define __NR_fchdir                              81

%define Darwin__NR_write                         0x04
%define Darwin__NR_exit                          0x01
%define Darwin__NR_open                          0x05
%define Darwin__NR_close                         0x06
%define Darwin__NR_fstat                         0xbd
%define Darwin__NR_mmap                          0xc5 
%define Darwin__NR_munmap                        0x49
%define Darwin__NR_getdents                      0xc4
%define Darwin__NR_fchdir                        0x0d

%define O_RDONLY                                 0o0000000
%define O_WRONLY                                 0o0000001
%define O_RDWR                                   0o0000002
%define O_CREAT                                  0o0000100
%define O_EXCL                                   0o0000200
%define O_NOCTTY                                 0o0000400
%define O_TRUNC                                  0o0001000
%define O_APPEND                                 0o0002000
%define O_NONBLOCK                               0o0004000
%define O_DSYNC                                  0o0010000
%define O_DIRECT                                 0o0040000
%define O_LARGEFILE                              0o0100000
%define O_DIRECTORY                              0o0200000
%define O_NOFOLLOW                               0o0400000
%define O_NOATIME                                0o1000000
%define O_CLOEXEC                                0o2000000
%define O_PATH                                   0o10000000

%define DT_REG                                   8

%define PROT_READ                                0x1
%define PROT_WRITE                               0x2
%define MAP_SHARED                               0x01
