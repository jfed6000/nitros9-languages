#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* rdump:  prints formatted dump of .r and .l files

     rdump [opts] <file>[ <file>] [opts]

     options:
          -g - add global definition info
          -r - add reference info
          -o - add reference and local offset info
          -a - all of the above

   Ported to a modern host: OS-9 ROF files are big-endian with a 16-bit
   int and packed structs, so the header and reference records are read
   field-by-field through getw()/getl() rather than fread()'d over a
   native struct (whose size and byte order do not match the file).
*/

/* symbol table types */

/* symbol definition/reference type/location */

/* type flags */
#define CODENT      0x04        /* data/code flag */
/* data type flags */
#define DIRENT      0x02        /* global/direct flag */
#define INIENT      0x01        /* clear/init. data flag */

/* location flags */
#define CODLOC      0x20        /* data/code flag */
#define DIRLOC      0x10        /* global/direct flag */
#define LOC1BYT     0x08        /* two/one byte size flag */
#define LOCMASK     (CODLOC|DIRLOC)

#define NEGMASK     0x40        /* negate on resolution */
#define RELATIVE    0x80        /* relative reference */

/* misc. constants */
#define ROFSYNC     0x62CD2387
#define SYMLEN      9         /* Length of symbols */
#define MAXNAME     16        /* length of module name */

/* definition/reference */
typedef struct {
     char r_flag; /* type/location */
     unsigned r_offset;
} def_ref;

/* rof header structure */
typedef struct {
     long h_sync;
     unsigned h_tylan;
     char h_valid;
     char h_date[5];
     char h_edit;
     char h_spare;
     unsigned h_glbl;
     unsigned h_dglbl;
     unsigned h_data;
     unsigned h_ddata;
     unsigned h_ocode;
     unsigned h_stack;
     unsigned h_entry;
} binhead;

#define MAXSOURCE 20
#define puts(s) fputs(s,stdout)
#define mc(c) ((c)&0xff)

#define DEF 1
#define REF 2

char *snames[MAXSOURCE],*fname;
int scount;
int gflag,rflag,oflag,bflag;

binhead hd;
FILE *in;

/* forward declarations */
void usage(void);
void pass1(void);
void showhead(void);
void showglobs(void);
void showbytes(char *name, long count);
void showrefs(void);
void showlcls(void);
void getname(char *s);
void ftext(char c, int ref);
void ferr(char *s);
void error(char *fmt, ...);
int  getw(FILE *fp);
long getl(FILE *fp);
int  readhead(void);

int
main(int argc, char *argv[])
{

     register char *p;

     while (--argc>0) {
          if(*(p=*++argv)=='-') {
               while(*++p) switch(*p) {
                    case 'g': gflag=1; break;
                    case 'r': rflag=1; break;
                    case 'o': oflag=1; break;
                    case 'a': gflag=rflag=oflag=1; break;
                    case 'b': bflag=1; break;
                    default:  usage();
               }
          }
          else {
               if(scount==MAXSOURCE) error("too many source files");
               snames[scount++]=*argv;
          }
     }
     if(scount == 0)
          usage();
     pass1();
     return 0;
}

void
usage(void)
{
     fprintf(stderr,"usage: rdump [-groab] file...\n");
     fprintf(stderr,"   dump the contents of OS-9 relocatable (.r) and library (.l) files\n");
     fprintf(stderr,"   -g  list global symbol definitions\n");
     fprintf(stderr,"   -r  list external references\n");
     fprintf(stderr,"   -o  list references with their local offsets\n");
     fprintf(stderr,"   -a  all of the above (-gro)\n");
     fprintf(stderr,"   -b  hex dump of each module's code and data sections\n");
     exit(1);
}

void
pass1(void)
{
     int count;

     if(scount == 0)
          return;

     for(count=0; count<scount; ++count) {
          fname = snames[count];
          if((in = fopen(fname,"r")) == NULL) {
               printf("can't open '%s'",fname);
               continue;
          }

          for(;;) {
               if(!readhead())
                    break;

               if(hd.h_sync != ROFSYNC) {
                    printf("'%s' is not a relocatable module",fname);
                    break;
               }

               showhead();
               showglobs();

/* dump, or skip past, the code and initialized data */
               if(bflag) {
                    showbytes("Code",(long)hd.h_ocode);
                    showbytes("Init DP data",(long)hd.h_ddata);
                    showbytes("Init data",(long)hd.h_data);
               }
               else
                    fseek(in,(long)(hd.h_ocode + hd.h_ddata + hd.h_data),SEEK_CUR);

               showrefs();
               showlcls();

          }
          fclose(in);
     }
}

void
showhead(void)
{
     int c;

     puts("\nModule name: ");
     while((c=getc(in)))
          putchar(c);
     if(ferror(in)) ferr(fname);

     printf("\nTyLa/RvAt:   %02x/%02x\n",mc(hd.h_tylan>>8),mc(hd.h_tylan));
     printf("Asm valid:   %s\n",hd.h_valid ? "No" : "Yes");
     printf("Create date: %.3s %2d, %4d %02d:%02d\n",
          &("JanFebMarAprMayJunJulAugSepOctNovDec"[(mc(hd.h_date[1])-1)*3]),
          mc(hd.h_date[2]),1900+mc(hd.h_date[0]),
          mc(hd.h_date[3]),mc(hd.h_date[4]));
     printf("Edition:     %2d\n",hd.h_edit);
       puts("  Section    Init Uninit\n");
     printf("   Code:     %04x\n",hd.h_ocode);
     printf("     DP:       %02x   %02x\n",hd.h_ddata,hd.h_dglbl);
     printf("   Data:     %04x %04x\n",hd.h_data,hd.h_glbl);
     printf("  Stack:     %04x\n",hd.h_stack);
     printf("Entry point: %04x\n",hd.h_entry);
}

void
showglobs(void)
{
     register unsigned count,offset;
     char sym[SYMLEN+1],flag;

     count=getw(in);          /* global def count */
     if(gflag)
          printf("\n%u global symbols defined:\n",count);

     while(count--) {
          getname(sym);
          flag=getc(in);
          offset=getw(in);
          if(gflag) {
               printf(" %9s %04x ",sym,offset);
               ftext(flag,DEF);
          }
     }
}

void
getname(char *s)
{
     int c,n;

     n = 0;
     while((c = getc(in)) != '\0' && c != EOF)
          if(n < SYMLEN)
               s[n++] = c;
     s[n] = '\0';
     if(ferror(in)) ferr(fname);
}

void
ftext(char c, int ref)
{

     printf("(%02x) ",mc(c));
     if(ref & REF) {
          if(c & CODLOC)
               puts("in code");
          else puts(c & DIRLOC ? "in dp data" : "in non-dp data");

          puts(c & LOC1BYT ? "/byte" : "/word");
          if(c & NEGMASK)
               puts("/neg");
          if(c & RELATIVE)
               puts("/pcr");
     }
     if(ref & DEF) {
          if(ref & REF)
               puts(" - ");
          if(c & CODENT)
               puts("to code");
          else {
               puts(c & DIRENT ? "to dp" : "to non-dp");
               puts(c & INIENT ? " data" : " bss");
          }
     }
     putchar('\n');
}

void
showbytes(char *name, long count)
{
     long addr;
     int i,n,c;
     unsigned char line[16];

     printf("\n%s (%04lx bytes):\n",name,count);
     for(addr=0; addr<count; ) {
          printf("%04lx  ",addr);
          n=0;
          for(i=0; i<16 && addr<count; ++i,++addr) {
               c=getc(in);
               line[n++]=c;
               printf("%02x ",mc(c));
          }
          for(; i<16; ++i)
               printf("   ");
          printf(" ");
          for(i=0; i<n; ++i) {
               c=line[i];
               putchar(c>=0x20 && c<0x7f ? c : '.');
          }
          putchar('\n');
     }
     if(ferror(in)) ferr(fname);
}

void
showrefs(void)
{
     register unsigned count,rcount;
     def_ref ref;
     char sym[SYMLEN+1];
     int fflag;

     count=getw(in);
     if(rflag)
          printf("\n%u external references:\n",count);

     while(count--) {
          getname(sym);
          rcount=getw(in);
          if(rflag)
               printf(" %9s ",sym);
          fflag=0;
          while(rcount--) {
               ref.r_flag = getc(in);
               ref.r_offset = getw(in);
               if(ferror(in)) ferr(fname);
               if(rflag && oflag) {
                    if(fflag)
                         puts("           ");
                    else fflag=1;
                    printf("%04x ",ref.r_offset);
                    ftext(ref.r_flag,REF);
               }
          }
          if(rflag && !oflag)
               putchar('\n');
     }
}

void
showlcls(void)
{
     register unsigned count;
     def_ref ref;

     count=getw(in);
     if(oflag)
          printf("\n%u local references\n",count);

     while(count--) {
          ref.r_flag = getc(in);
          ref.r_offset = getw(in);
          if(ferror(in)) ferr(fname);
          if(oflag) {
               printf("   %04x ",ref.r_offset);
               ftext(ref.r_flag,DEF | REF);
          }
     }
}

/* big-endian binary readers - OS-9 ROF files store multi-byte values
   most-significant byte first regardless of the host's byte order */

int
getw(FILE *fp)          /* read a 2-byte big-endian word */
{
     int hi = getc(fp);
     int lo = getc(fp);
     return ((hi & 0xff) << 8) | (lo & 0xff);
}

long
getl(FILE *fp)          /* read a 4-byte big-endian long */
{
     long v = 0;
     int i;

     for(i = 0; i < 4; ++i)
          v = (v << 8) | (getc(fp) & 0xff);
     return v;
}

int
readhead(void)          /* read one ROF header; 0 at clean end of file */
{
     int c,i;

     if((c = getc(in)) == EOF)
          return 0;
     ungetc(c,in);

     hd.h_sync  = getl(in);
     hd.h_tylan = getw(in);
     hd.h_valid = getc(in);
     for(i = 0; i < 5; ++i)
          hd.h_date[i] = getc(in);
     hd.h_edit  = getc(in);
     hd.h_spare = getc(in);
     hd.h_glbl  = getw(in);
     hd.h_dglbl = getw(in);
     hd.h_data  = getw(in);
     hd.h_ddata = getw(in);
     hd.h_ocode = getw(in);
     hd.h_stack = getw(in);
     hd.h_entry = getw(in);
     return 1;
}

void
error(char *fmt, ...)
{
     va_list ap;

     fprintf(stderr,"rdump: ");
     va_start(ap,fmt);
     vfprintf(stderr,fmt,ap);
     va_end(ap);
     putc('\n',stderr);
     exit(1);
}

void
ferr(char *s)
{
     error("error reading '%s'", s);
}
