NAME = main

bin/$(NAME): bin/$(NAME).o
	gcc -o bin/$(NAME) bin/$(NAME).o -no-pie

bin/$(NAME).o: src/$(NAME).asm bin/
	nasm -f elf64 -o bin/$(NAME).o src/$(NAME).asm

bin/:
	mkdir bin

run: bin/$(NAME)
	./bin/$(NAME)

.PHONY: clean

clean:
	rm -rf bin

all: clean bin/$(NAME)
