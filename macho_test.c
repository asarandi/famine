#include <stdio.h>
#include <mach-o/loader.h>

//struct mach_header_64 {
//	uint32_t	magic;		/* mach magic number identifier */                  // 4        0xfeedfacf
//	cpu_type_t	cputype;	/* cpu specifier */                                 // 4        0x01000007
//	cpu_subtype_t	cpusubtype;	/* machine specifier */                         // 4        0x80000003
//	uint32_t	filetype;	/* type of file */                                  // 4        0x00000002
//	uint32_t	ncmds;		/* number of load commands */                       // 4        0x0000000f
//	uint32_t	sizeofcmds;	/* the size of all the load commands */             // 4        0x000004b0
//	uint32_t	flags;		/* flags */                                         // 4        0x00200085
//	uint32_t	reserved;	/* reserved */                                      // 4        0x00000000
//};
//                                                                              total: 0x20 bytes

//struct segment_command_64 { /* for 64-bit architectures */
//	uint32_t	cmd;		/* LC_SEGMENT_64 */
//	uint32_t	cmdsize;	/* includes sizeof section_64 structs */
//	char		segname[16];	/* segment name */
//	uint64_t	vmaddr;		/* memory address of this segment */
//	uint64_t	vmsize;		/* memory size of this segment */
//	uint64_t	fileoff;	/* file offset of this segment */
//	uint64_t	filesize;	/* amount to map from the file */
//	vm_prot_t	maxprot;	/* maximum VM protection */
//	vm_prot_t	initprot;	/* initial VM protection */
//	uint32_t	nsects;		/* number of sections in segment */
//	uint32_t	flags;		/* flags */
//};
//
//struct section_64 { /* for 64-bit architectures */
//	char		sectname[16];	/* name of this section */
//	char		segname[16];	/* segment this section goes in */
//	uint64_t	addr;		/* memory address of this section */
//	uint64_t	size;		/* size in bytes of this section */
//	uint32_t	offset;		/* file offset of this section */
//	uint32_t	align;		/* section alignment (power of 2) */
//	uint32_t	reloff;		/* file offset of relocation entries */
//	uint32_t	nreloc;		/* number of relocation entries */
//	uint32_t	flags;		/* flags (section type and attributes)*/
//	uint32_t	reserved1;	/* reserved (for offset or index) */
//	uint32_t	reserved2;	/* reserved (for count or sizeof) */
//	uint32_t	reserved3;	/* reserved */
//};
//




//00000000  cf fa ed fe 07 00 00 01  03 00 00 80 02 00 00 00  |................|
//00000010  0f 00 00 00 b0 04 00 00  85 00 20 00 00 00 00 00  |.......... .....|



int main()
{
    printf("sizeof(struct mach_header_64) = %lx\n", sizeof(struct mach_header_64));
    printf("sizeof(struct segment_command_64) = %lx\n", sizeof(struct segment_command_64));    
    printf("sizeof(struct section_64) = %lx\n", sizeof(struct section_64));
    return 0;
}
