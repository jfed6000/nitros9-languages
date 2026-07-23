********************************************************************
* createheadb - create-file prologue, attribute-computing variant
*
* One of the create-file prologues (see lib/createtail.asm for the
* shared remainder).  This variant derives the create attributes from
* the requested mode: mask to the attribute bits and force the base
* access permissions.  On a create failure it drops into CreateExists
* (from createtail); on success it falls straight through into CreateOk.
*
* Used by the modules whose create entry computes attributes this way;
* each aliases its own entry name onto CreateFile.
*
* C prototype:  int   creat(char *path, int mode)   [mode-derived-attribute prologue]
********************************************************************

creat               ldx       $02,s     load pathname pointer
                    lda       $05,s     load requested mode
                    tfr       a,b       copy mode to attribute byte
                    andb      #$24      mask attribute bits
                    orb       #$0b      set base access permissions
                    os9       I$Create  create the file
                    bcs       CreateExists handle create failure
