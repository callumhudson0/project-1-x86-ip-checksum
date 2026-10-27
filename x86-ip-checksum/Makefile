ipcheck: ipcheck.o
	ld ipcheck.o -o ipcheck

ipcheck.o: ipcheck.asm
	nasm -gstabs -felf64 -l ipcheck.lst ipcheck.asm

test: ipcheck
	bash tests/run_tests.sh ./ipcheck

clean:
	rm -f ipcheck ipcheck.o ipcheck.lst

.PHONY: test clean
