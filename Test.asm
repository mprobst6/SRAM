; This program uses the SLOW_SRAM device to write and read some
;  values from the DE2 external SRAM chip. It reads a value from
;  the switches, and stores THAT value at THAT address. Then, it
;  runs an endless loop where it reads the switches and displays 
;  the value at that address on the left seven-segment displays.
;  If DE2 is powered off, then on, then this program is run with
;  the switches set for 0000, then it will display 0000, but if
;  the switches are moved to other values, it will display the 
;  random data still at those locations.
;  Resetting the DE2 and running again, without powering off,
;  allows the user to write one new value each time.
;  Limitations:  
;   - cannot specify an address over 16-bits
;   - not a particularly good way to test a lot of locations
;   - uses the SLOW_SRAM device, taking 9-12 instructions for
;       a single read or write
; This program includes...
; - Several useful subroutines (ATAN2, Neg, Abs, mult, div).
; - Some useful constants (masks, numbers, robot stuff, etc.)

ORG 0

;***************************************************************
;* Main code
;***************************************************************
Main:
	CALL	SETUP
	LOADI	4
	STORE	WRITECOUNT
	LOADI	2
	STORE	READCOUNT
	
	CALL	WRITESEQ 
	LOADI	2
	STORE	DIRECTION
	CALL 	READSEQ

	
Done:

	JUMP	Done

	
	
SETUP:	LOAD    ADHI		;load values set beforehand
		OUT		SRAM_ADHI
		LOAD    ADLOW
		OUT     SRAM_ADLOW  ;set memory address to location of ADHI and ADLOW
		RETURN
		
WRITESEQ:	LOAD	DIRECTION	
			OUT		SRAM_DIR
			CALL	WRITE
			RETURN
		
WRITE:	LOAD	WRITECOUNT	;load your value
		OUT 	SRAM_DATA
		LOAD	WRITECOUNT
		ADDI 	-1
		STORE	WRITECOUNT
		JPOS 	WRITE
		RETURN
		
READSEQ:	LOAD	DIRECTION	
			OUT		SRAM_DIR
			CALL	READ
			RETURN
		
READ:	IN		SRAM_DATA
		LOAD	READCOUNT
		ADDI 	-1
		STORE	READCOUNT
		JPOS 	READ
		RETURN
	
	
	
ADHI:	DW		0
ADLOW:	DW		0
WRITECOUNT:	DW	1
READCOUNT:	DW	1
DIRECTION: DW	1
	
DataArray:
	DW 0
;***************************************************************
;* IO address space map
;***************************************************************
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
XLEDS:    EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:     EQU &H0A  ; Control the beep
CTIMER:   EQU &H0C  ; Configurable timer for interrupts
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_RDY:  EQU &H92  ; ... and BUSY register
UART_DAT: EQU &H98  ; UART data
UART_RDY: EQU &H99  ; UART status
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONALARM: EQU &HB0  ; Write alarm distance; read alarm register
SONARINT: EQU &HB1  ; Write mask for sonar interrupts
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-359)
RESETPOS: EQU &HC3  ; write anything here to reset odometry to 0
RIN:      EQU &HC8
LIN:      EQU &HC9
IR_HI:    EQU &HD0  ; read the high word of the IR receiver (OUT will clear both words)
IR_LO:    EQU &HD1  ; read the low word of the IR receiver (OUT will clear both words)
SRAM_DATA: EQU &H10 
SRAM_ADLOW: EQU &H11 
SRAM_ADHI: EQU &H12 
SRAM_DIR: EQU &H13 ; 00 for same addr, 01 for increment, 10 for decrement, 11 for something??

;SRAM_CTRL: EQU &H10 ; write the two bits controlling SRAM function (bit 1 is write, bit 0 is output enable)
;SRAM_DATA: EQU &H11 ; write the data to go to SRAM (before setting control bits) or read the data from SRAM (after setting bits)
;SRAM_ADLOW: EQU &H12 ; write the lower 16 bits of the SRAM address (before setting control bits)
;SRAM_ADHI: EQU &H13  ; write the upper 2 bits of the SRAM address (before setting control bits)
;SRAM_DIRECTION: EQU &H14 ;determines whether the memory is read/written up or down