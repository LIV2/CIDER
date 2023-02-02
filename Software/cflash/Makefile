PROJECT=cflash
CC=m68k-amigaos-gcc
CFLAGS=-lamiga -mcrt=nix13 -mcpu=68000 -Wall -Wno-pointer-sign -Os -fomit-frame-pointer
.PHONY:	clean all
all:	$(PROJECT)

OBJ = kick_flash.o \
	ide_flash.o \
	config.o \
	main.o

SRCS = $(OBJ:%.o=%.c)

cflash: $(SRCS)	*.h
	${CC} -o $@ $(CFLAGS) $(SRCS)

clean:
	-rm $(PROJECT)
