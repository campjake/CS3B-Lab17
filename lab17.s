// Style Sheet
// Programmer   : Jacob Campbell
// Lab #        : 17
// Purpose      : IO Read Array
// Date         : 4/6/2023

	.EQU	O_RDONLY,		0		// READ ONLY
	.EQU	O_WRONLY,		1		// WRITE ONLY
	.EQU	O_CREAT,		0100	// Create file
	.EQU	RW, 	02		// READ/WRITE
	.EQU	T_RW,	01002	// Truncate READ/WRITE
	.EQU	C_W,	0101	// Create file if it dne
	.EQU	READ, 	63		// read
	.EQU	CLOSE,	57		// Close the file

	// FILE PERMISSIONS
//	OWNER	GROUP	OTHER
//	RWE		RWE		RWE
	.EQU	RW__, 0600
	.EQU	AT_FDCWD, -100 	// LOCAL DIRECTORY

	.data
szFile:		.asciz	"input.txt"
iStrLen:	.byte	15			// 16\n32\n64\n128\n-1\n
dbArr:		.fill	5, 8, 0		// Init dbArr[5] = {0}
fileBuf:	.skip	512			// File buffer	
iFD:		.quad	0			// ?
szEOF:		.asciz	"Reached the End of File"
szErr:		.asciz	"FILE READ ERROR\n"
chLF:		.byte	0xA			// Line feed
temp:		.byte	0			// temp placeholder for int

	.global _start
	.text
_start:
// Open the file (same as lab15)
	MOV		X0, #AT_FDCWD	// *X0 = local directory, File Descriptor will be returned
	MOV		X8, #56			// OPENAT
	LDR		X1,=szFile		// Pointer to C-String: Use File Name

	MOV		X2, #O_RDONLY	// Read only
	MOV		X3, RW__		// Permission
	SVC 	0				// Service Call 0 (iosetup)

// Load file input to buffer with read() syscall
	MOV	X8, #READ			// *X8 = READ (63)
	LDR	X1,=fileBuf			// *X1 = fileBuf
	LDR	X2,=iStrLen			// *X1 = 15
	LDR	X2, [X2]			// X1 = 15
	svc 0					// Service Call 0 (iosetup)

	MOV	X8, #CLOSE			// Close the file
	SVC	0					// Service call 0 (iosetup)	

// Call String_replace() to replace instances of '\n'
// with null-terminators
	MOV	X0, X1				// *X0 = fileBuf
	MOV	X1, 0xA				// X1 = LF (\n)
	MOV	X2, 0x00			// X2 = null
	BL	String_replace		// Converts \n to 0x0

// Convert asciz array to dbArr
	MOV	X11, X0				// Copy asciz array base address to X11
	LDR	X3,=dbArr			// X3 = base address
	MOV X4, #0				// Init X4 = i = 0
	MOV	X5, #8				// Init incr val = 8 (2 bytes for each element + null)
	MOV	X6, #0
	MOV	X7, #2

checkLength:
	MOV		X1, 0x00			// Looking for null bit
	MOV		X2, X6				// From index [j]
	BL		String_indexOf_2	// Check where the null bit is
	CMP		X0, #3				// Check if third digit is null terminator
	BGT		threeDigit			// Branch to threeDigit for 128

loop:
	BL		ascint64			// X0 = int
	STR		X0, [X3, X4]		// Store int to dbArr[i]
	ADD		X4, X4, X5			// i += 8
	CMP		X4, #40				// Check if we reached the limit
	BGT		done				// Done if true
	ADD		X6, X6, #3			// Increment iterator for string
	ADD		X0, X11, X6			// Load next element to X0
	B		loop				// Else continue loop

threeDigit:
	BL		ascint64			// X0 = int
	STR		X0, [X3, X4]		// Store int to dbArr[i]
	ADD		X4, X4, X5			// i += 8
	CMP		X4, #40				// Check if we reached the limit
	BGT		done				// Done if true
	ADD		X6, X6, #4			// Increment iterator for string
	ADD		X0, X11, X6			// Load next element to X0
	B		loop				// Else continue loop

done:
// Call kernel to end program
	MOV	X0, #0				// Return code 0 (iosetup)
	MOV	X8, #93				// Service command 93 (exit)
	SVC	0					// Service code 0 (iosetup)
	.end					// End of program
