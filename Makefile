UNAME := $(shell uname -s)

NAME := famine_exec
SRC := famine.asm
OBJ := famine.o
ASMFLAGS := -f elf64

ifeq ($(UNAME), Darwin)
	SRC := famine.asm
	OBJ := famine.o
	ASMFLAGS := -f macho64
	LDFLAGS := -macosx_version_min 10.7 -arch x86_64 -e _start
endif


all: $(NAME)

$(NAME): $(OBJ)
	ld $(LDFLAGS) $^ -o $(NAME)

$(OBJ):
	nasm $(ASMFLAGS) $(SRC)

clean:
	rm -f $(OBJ)

fclean: clean
	rm -f $(NAME)

re: fclean $(NAME)
