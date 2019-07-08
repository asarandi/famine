UNAME := $(shell uname -s)

SRC := famine.asm
OBJ := famine.o
ASMFLAGS := -f elf64
LDFLAGS :=

ifeq ($(UNAME), Darwin)
	SRC := famine.asm
	OBJ := famine.o
	ASMFLAGS := -f macho64
	LDFLAGS := -no_pie -macosx_version_min 10.7 -arch x86_64 -e _start
endif


famine: $(OBJ)
	ld $(LDFLAGS) $^ -o famine_exec

$(OBJ):
	nasm $(ASMFLAGS) $(SRC)

clean:
	rm -f famine_exec $(OBJ)

re: clean famine
