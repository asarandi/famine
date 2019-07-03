ELF_SYSV                            equ 0x00010102464c457f
ELF_GNU                             equ 0x03010102464c457f
ELF64_ET_DYN                        equ 0x00000001003e0003
ELF64_ET_EXEC                       equ 0x00000001003e0002

; https://opensource.apple.com/source/xnu/xnu-4903.221.2/bsd/kern/syscalls.master.auto.html
; 196	AUE_GETDIRENTRIES	ALL	{ int getdirentries(int fd, char *buf, u_int count, long *basep); } 

__NR_write                          equ 0x2000004
__NR_exit                           equ 0x2000001
__NR_fchdir                         equ 0x200000d
__NR_getdents64                     equ 0x20000c4
__NR_close                          equ 0x2000006
__NR_open                           equ 0x2000005
__NR_fstat                          equ 0x20000bd
__NR_mmap                           equ 0x20000c5 
__NR_munmap                         equ 0x2000049


O_RDONLY                            equ 0o0000000
O_WRONLY                            equ 0o0000001
O_RDWR                              equ 0o0000002
O_CREAT                             equ 0o0000100
O_EXCL                              equ 0o0000200
O_NOCTTY                            equ 0o0000400
O_TRUNC                             equ 0o0001000
O_APPEND                            equ 0o0002000
O_NONBLOCK                          equ 0o0004000
O_DSYNC                             equ 0o0010000
O_DIRECT                            equ 0o0040000
O_LARGEFILE                         equ 0o0100000
O_DIRECTORY                         equ 0o0200000
O_NOFOLLOW                          equ 0o0400000
O_NOATIME                           equ 0o1000000
O_CLOEXEC                           equ 0o2000000
O_PATH                              equ 0o10000000

DT_REG                              equ 8

PROT_READ                           equ 0x1
PROT_WRITE                          equ 0x2
MAP_SHARED                          equ 0x01

