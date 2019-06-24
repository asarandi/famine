famine: famine.o
	ld -s -N famine.o -o famine_exec
	ld -s -pie -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2 famine.o -o famine_dyn
	/usr/bin/printf '\x7' | dd conv=notrunc of=famine_dyn bs=1 count=1 seek=180

famine.o:
	nasm -f elf64 famine.s

clean:
	rm -f famine_dyn famine_exec famine.o

re: clean famine
