obj-m += battleship.o

CC = gcc

CFLAGS = -Wall -Wextra -Wpedantic

.PHONY: default build clean load unload

default: build

build:
	make -C /lib/modules/$(shell uname -r)/build modules M=$(PWD)
clean:
	make -C /lib/modules/$(shell uname -r)/build clean M=$(PWD)
load:
	sudo insmod battleship.ko
unload:
	-sudo rmmod battleship
