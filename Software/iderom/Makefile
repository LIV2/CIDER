PROGRAM=cider.rom
INCLUDE=/opt/amiga/m68k-amigaos/ndk-include
AS=vasmm68k_mot
ASFLAGS=-Fhunk -I$(INCLUDE) -quiet -align
LINKER=vlink
LINKFLAGS=-brawbin1 -s -sc -sd -mrel
OBJDIR=obj

.PHONY: all clean rom

SRCS = bootldr.S
OBJS = $(SRCS:%.S=$(OBJDIR)/%.o)

all:	$(PROGRAM)

$(OBJDIR)/mungerom: mungerom.c
	@mkdir -p $(OBJDIR)
	$(CC) $< -Wall -o $@

$(OBJDIR)/%.o: %.S
	@mkdir -p $(OBJDIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/bootldr:	$(OBJDIR)/bootldr.o
	$(LINKER) $(LINKFLAGS) -o $@ $<

$(OBJDIR)/bootnibbles: $(OBJDIR)/bootldr $(OBJDIR)/mungerom
	@mkdir -p $(OBJDIR)
	./obj/mungerom

$(PROGRAM): $(OBJDIR)/bootnibbles $(OBJDIR)/assets.o
	$(LINKER) $(LINKFLAGS) -Trom.ld -o $@ $(OBJDIR)/assets.o

clean:
	rm -f $(OBJDIR)/*
	rm -f $(PROGRAM)
	rm -f mungerom
