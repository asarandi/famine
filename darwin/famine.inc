%define BUF_SIZE                                 1024
%define LOCAL_VARS                               1024
%define LC_SEGMENT_64                            0x19
%define LC_MAIN                                  0x80000028

%define Darwin__NR_write                         0x04
%define Darwin__NR_exit                          0x01
%define Darwin__NR_open                          0x05
%define Darwin__NR_close                         0x06
%define Darwin__NR_fstat                         0xbd
%define Darwin__NR_mmap                          0xc5 
%define Darwin__NR_munmap                        0x49
%define Darwin__NR_getdents                      0xc4
%define Darwin__NR_chmod                         0x0f

%define O_RDONLY                                 0o0000000
%define O_RDWR                                   0o0000002
%define O_DIRECTORY                              0o0200000

%define DT_REG                                   8

%define PROT_READ                                0x1
%define PROT_WRITE                               0x2
%define MAP_SHARED                               0x01
