********************************************************************
* createheada - create-file prologue, fixed-attribute variant
*
* One of the create-file prologues (see lib/createtail.asm for the
* shared remainder).  This variant ignores the requested mode for the
* attribute byte and creates with a fixed set of base access
* permissions.  On a create failure it drops into CreateExists (from
* createtail); on success it falls straight through into CreateOk.
*
* Used by the modules whose create entry uses a fixed attribute byte;
* each aliases its own entry name onto CreateFile.
*
* C prototype:  int   creat(char *path, int mode)   [fixed-attribute prologue]
********************************************************************

creat               ldx       2,s       load pathname pointer
                    lda       5,s       load requested mode
                    ldb       #11       fixed base access permissions
                    os9       I$Create  create the file
                    bcs       CreateExists handle create failure
