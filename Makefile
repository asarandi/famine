famine: famine.o
	ld famine.o -o famine

famine.o:
	nasm -f elf64 famine.s

clean:
	rm -f famine famine.o

re: clean famine
