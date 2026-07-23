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

all: cstart_check cstart_rev_check imul_check shift_check divide_check string_check flushbuffer_check writepath_check syscallerr_check pathops_check readpath_check createtail_check createheada_check createheadb_check statwrap_check seek_check fcloseflush_check

cstart_check: cstart_check.asm cstart.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

cstart_rev_check: cstart_rev_check.asm cstart_rev.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

imul_check: imul_check.asm imul.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

shift_check: shift_check.asm shift.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

divide_check: divide_check.asm divide.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

string_check: string_check.asm strcpy.asm strcat.asm strlen.asm strcmp.asm strncpy.asm strncmp.asm strncat.asm memcpy.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

flushbuffer_check: flushbuffer_check.asm flushbuffer.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

writepath_check: writepath_check.asm writepath.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

syscallerr_check: syscallerr_check.asm syscallerr.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

pathops_check: pathops_check.asm openpath.asm closepath.asm deletepath.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

readpath_check: readpath_check.asm readpath.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

createtail_check: createtail_check.asm createtail.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

createheada_check: createheada_check.asm createheada.asm createtail.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

createheadb_check: createheadb_check.asm createheadb.asm createtail.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

statwrap_check: statwrap_check.asm getstat.asm setstat.asm access.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

seek_check: seek_check.asm seek.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

fcloseflush_check: fcloseflush_check.asm fclose.asm fflush.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

clean:
	$(RM) cstart_check cstart_rev_check imul_check shift_check divide_check string_check flushbuffer_check writepath_check syscallerr_check pathops_check readpath_check createtail_check createheada_check createheadb_check statwrap_check seek_check fcloseflush_check *.lst

.PHONY: all clean
