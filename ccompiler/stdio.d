********************************************************************
* stdio.d - C runtime FILE stream definitions
*
* Assembler mirror of defs/stdio.h.  The C library buffers each open
* stream in a FILE record (struct _iobuf); the runtime reaches its
* fields as <offset>,u with U pointing at the record.  Every compiler
* module uses this one layout - the shared stdio routines are byte for
* byte identical across modules, which only holds because the field
* offsets match.  Historically each module named the fields after its
* own data-area globals (c.prep: ExpandPtr = flag, FileBufBase = base,
* ...; c.opt: Flags equ $06); these are the canonical names.
********************************************************************

* FILE record field offsets (sizeof FILE = 13, _iob holds _NFILE of them)
_ptr                equ       0         buffer pointer (current position)
_base               equ       2         buffer base address
_end                equ       4         buffer end address
_flag               equ       6         file status flags (see below)
_fd                 equ       8         open path number
_save               equ       10        ungetc save byte when unbuffered
_bufsiz             equ       11        size of the data buffer
_FILESZ             equ       13        size of one FILE record

* _flag status bits
_READ               equ       $01       stream open for reading
_WRITE              equ       $02       stream open for writing
_UNBUF              equ       $04       stream is unbuffered
_BIGBUF             equ       $08       buffer was allocated large
_EOF                equ       $10       end of file reached
_ERR                equ       $20       error on stream
_SCF                equ       $40       device is a character device
_RBF                equ       $80       device is a block device
_DEVMASK            equ       $C0       device class mask
_WRITTEN            equ       $0100      buffer written in update mode
_INIT               equ       $8000      _iob table initialised

* stream table
BUFSIZ              equ       256       default buffer size
_NFILE              equ       16        number of FILE slots in _iob
