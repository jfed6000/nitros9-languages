include $(NITROS9DIR)/rules.mak

# c3 (C-Cubed) builds in three stages, each feeding the next:
#   host    - the compiler as host executables (build/unix), the cross compiler
#   runtime - crt0, the helper library and the C library (lwbackend), built
#             with the host compiler, lwasm and lwar
#   os9     - the compiler cross-built to OS-9 modules (build/os9), so it can
#             run on NitrOS-9 and rebuild itself there
# Everything uses the in-tree tools; nothing needs to be installed first.

HOSTDIR		= $(CURDIR)/build/unix
OS9DIR		= $(CURDIR)/build/os9
LWDIR		= $(CURDIR)/lwbackend

# The host driver looks for its headers under $(C3BASE_DEFAULT)/defs.
HOSTFLAGS	= C3BASE_DEFAULT=$(CURDIR)
# Point the cross-build at the host stages and runtime built here, instead of
# an installed toolchain on the PATH.
OS9FLAGS	= C3BASE=$(CURDIR) C3LIBDIR=$(LWDIR) \
		  PREP=$(HOSTDIR)/prep/c3prep COMP=$(HOSTDIR)/comp/c3comp \
		  OPTX=$(HOSTDIR)/optx/c3optx

# The distribution disk needs the Microware r-utils (rma rlink mold rdump)
# from a CoCo C checkout, which is not part of this repository.  Without
# COCOC the tools are still built, but the disk is skipped.  NFP09 (an nfp09
# checkout) optionally supplies the MC6839 floating-point module.
DSK		= c3.dsk
COCOC		?=
NFP09		?=

.PHONY: all banner host runtime os9 dsk clean

# Make all components
all:	banner os9
ifneq ($(COCOC),)
all:	$(DSK)
else
all:
	@$(ECHO) "c3: COCOC not set, skipping $(DSK) (see c3/Makefile)"
endif

banner:
	@$(ECHO) "**************************************************"
	@$(ECHO) "*                                                *"
	@$(ECHO) "*                  C-Cubed (c3)                  *"
	@$(ECHO) "*                                                *"
	@$(ECHO) "**************************************************"

host:
	$(MAKE) -C $(HOSTDIR) all $(HOSTFLAGS)

runtime: host
	cd $(LWDIR) && sh buildrt.sh && sh buildlibc.sh

os9: runtime
	$(MAKE) -C $(OS9DIR) all $(OS9FLAGS)

dsk:	$(DSK)

$(DSK): os9
	DSK="$(CURDIR)/$@" DSKNAME="C3" COCOC="$(COCOC)" NFP09="$(NFP09)" \
	    sh $(OS9DIR)/mkdsk.sh

# Clean all components
clean:
	$(MAKE) -C $(HOSTDIR) clean
	$(MAKE) -C $(OS9DIR) clean
	$(RM) -r $(LWDIR)/obj $(LWDIR)/libcobj
	$(RM) $(LWDIR)/crt0.o $(LWDIR)/fpdummy.o $(LWDIR)/fpinit.o \
	    $(LWDIR)/libc3.a $(LWDIR)/libc3lw.a $(DSK)
