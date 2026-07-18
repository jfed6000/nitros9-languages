# Shared C runtime for the C compiler.
#
# These are source includes factored out of the compiler modules: each
# module pulls one in with a "use lib/<file>.asm" where it needs it.
#
# cstart.asm is the Microware C startup; each module supplies its own
# RTBASE/DATAEND/HDRADV parameters and main/exit/_exit/WorkBlockImage
# symbols.  imul.asm is the full-width runtime multiply and is entirely
# self-contained.  None of them assemble on their own, so this makefile
# validates each through a <name>_check.asm harness that wraps it in a
# throwaway module.  Assembling a harness proves the include stays valid
# and self-consistent.

include $(NITROS9DIR)/rules.mak

all: cstart_check cstart_rev_check imul_check shift_check

cstart_check: cstart_check.asm cstart.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

cstart_rev_check: cstart_rev_check.asm cstart_rev.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

imul_check: imul_check.asm imul.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

shift_check: shift_check.asm shift.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

clean:
	$(RM) cstart_check cstart_rev_check imul_check shift_check *.lst

.PHONY: all clean
