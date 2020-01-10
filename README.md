# famine

#### disclaimer
the code in this repository is provided for educational purposes only


#### intro
famine is the first of four vx projects at 42 school - the objective of the project is to create a program ("infection") which is able to replicate by copying itself into other 64 bit executables ("hosts"). once a host file has been infected, it becomes a "carrier" of infection - when launched, it will also infect other files. original host file behavior and functionality remains unchanged.


#### logic
famine is very straightforward; pseudo code:

```python
folders = ['/tmp/test', '/tmp/test2']

for folder in folders:
    for file in folder:
        if not is_executable(file):
            continue
        if is_infected(file):
            continue
        infect(file)
```

#### features
- three versions available:
    - linux only version, which only infects elf64 files (`ET_DYN`, `ET_EXEC`)
    - darwin only version, which only infects macho64 files (with `LC_MAIN`)
    - hybrid ("cross-platform") version which infects both elf64 and macho64 files

- famine is a "space filler" type infection - it does **not** increase host file size;

- does **not** set the writable bit to host binary `TEXT` segments

- relatively small: linux/darwin version < 800 bytes; hybrid version < 1200 bytes


#### drawbacks
- does not infect **all** elf64/macho64 binaries - victim binary must have enough "padding" space.
    - based on our experiments (infecting all files in `/bin` and `/usr/bin` folders) it successfully infects ~75% of all binaries

- changes the permissions of all regular files in target directories to 0777

- after infecting a file it does not restore last modification time


#### video
- https://www.youtube.com/watch?v=aCnkIUMxXAk


#### screenshots
[![intra/famine-screenshot1.png](intra/famine-screenshot1.png "intra/famine-screenshot1.png")](intra/famine-screenshot1.png "intra/famine-screenshot1.png")
