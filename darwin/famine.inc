%define BUF_SIZE                                 1024
%define LOCAL_VARS                               1024
%define LC_SEGMENT_64                            0x19
%define LC_MAIN                                  0x80000028

%define Darwin__NR_write                         0x2000004
%define Darwin__NR_exit                          0x2000001
%define Darwin__NR_open                          0x2000005
%define Darwin__NR_close                         0x2000006
%define Darwin__NR_fstat                         0x20000bd
%define Darwin__NR_mmap                          0x20000c5
%define Darwin__NR_munmap                        0x2000049
%define Darwin__NR_getdents                      0x20000c4
%define Darwin__NR_chmod                         0x200000f

%define O_RDONLY                                 0o0000000
%define O_RDWR                                   0o0000002
%define O_DIRECTORY                              0o0200000

%define DT_REG                                   8

%define PROT_READ                                0x1
%define PROT_WRITE                               0x2
%define MAP_SHARED                               0x01
