include $(NITROS9DIR)/rules.mak

DSK		= CCompiler.dsk
CMDS		= cc1 cc2 c.prep c.pass1 c.pass2 c.comp c.opt c.asm c_asm c.link make
HEADERS		= $(wildcard defs/*.h)
LIBRARIES	= $(wildcard lib/*.l lib/*.r)
C_SOURCES	= $(wildcard sources/*.c)
ASM_SOURCES	= $(wildcard sources/*.a)
SYS_SOURCES	= $(wildcard sources/*.sys)

# Most compiler modules share the C runtime startup, which lives in lib/ and
# is pulled into each with "use lib/cstart.asm" (make keeps its own variant
# via cstart_rev.asm; c.asm is a copy of c_asm).  Validate the lib first, and
# rebuild the sharing modules when cstart.asm changes.
CSTARTMODS	= cc1 cc2 c.prep c.pass1 c.pass2 c.comp c.opt c_asm c.link

# Modules that share the full-width runtime multiply from lib/imul.asm
# (all of them carry the same MulFull the C runtime falls into).
IMULMODS	= cc1 cc2 c.prep c.pass1 c.pass2 c.comp c.opt c_asm c.link make

# Modules that share the word shift runtime from lib/shift.asm.
SHIFTMODS	= cc1 cc2 c.prep c.pass1 c.pass2 c.comp c.opt c_asm c.link make

.PHONY: all banner clean lib

# Make all components
all:	banner lib $(CMDS) $(DSK)

banner:
	@$(ECHO) "**************************************************"
	@$(ECHO) "*                                                *"
	@$(ECHO) "*                    C Compiler                  *"
	@$(ECHO) "*                                                *"
	@$(ECHO) "**************************************************"

lib:
	$(MAKE) -C lib

$(CSTARTMODS): lib/cstart.asm
$(IMULMODS): lib/imul.asm
$(SHIFTMODS): lib/shift.asm
make: lib/cstart_rev.asm

# Clean all components
clean:
	$(MAKE) -C lib clean
	$(RM) $(CMDS) $(DSK) *.list *.map

c.asm: c_asm
	$(CP) $< $@

# cc2 is cc1 built for the single-pass c.comp front end (it invokes c.comp
# instead of c.pass1 + c.pass2); selected in cc1.asm with -DCC2=1.
cc2: cc1.asm
	$(AS) $(AFLAGS) -DCC2=1 $< $(ASOUT)$@

$(DSK): Makefile $(CMDS) $(HEADERS) $(LIBRARIES) $(C_SOURCES) \
	$(ASM_SOURCES) $(SYS_SOURCES)
	$(RM) $@
	$(OS9FORMAT_DS40) -q $@ -n"C Compiler"
	$(MAKDIR) $@,CMDS
	$(MAKDIR) $@,LIB
	$(MAKDIR) $@,DEFS
	$(MAKDIR) $@,SOURCES
	$(MAKDIR) $@,SOURCES/SYS
	$(OS9COPY) $(CMDS) $@,CMDS
	$(OS9ATTR_EXEC) $(foreach file,$(CMDS),$@,CMDS/$(file))
	$(CPL) $(HEADERS) $@,DEFS
	$(OS9COPY) $(LIBRARIES) $@,LIB
	$(CPL) $(C_SOURCES) $@,SOURCES
	$(CPL) $(ASM_SOURCES) $(SYS_SOURCES) $@,SOURCES/SYS
