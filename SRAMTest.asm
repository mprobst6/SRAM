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

;Set the memory address to &H0000
	LOADI   0
	OUT		SRAM_ADHI
	LOADI   0
	OUT     SRAM_ADLOW
;Set the direction to increment addresses after each write
	LOADI   &b01		
	OUT     SRAM_DIR
;Write the values 32-51 onto memory addresses &H0000 through &H0013
	LOADI   32
	OUT     SRAM_DATA	;write the value 32 to &H0000
		
	LOADI   33
	OUT     SRAM_DATA   ;write the value 33 to &H0001
	
	LOADI 	34			;write the value 34 to &H0002
	OUT		SRAM_DATA
	
	LOADI 	35			;write the value 35 to &H0003
	OUT		SRAM_DATA
	
	LOADI 	36			;write the value 36 to &H0004
	OUT		SRAM_DATA
	
	LOADI 	37			;write the value 37 to &H0005
	OUT		SRAM_DATA
	
	LOADI 	38			;write the value 38 to &H0006
	OUT		SRAM_DATA
	
	LOADI 	39			;write the value 39 to &H0007
	OUT		SRAM_DATA
	
	LOADI 	40			;write the value 40 to &H0008
	OUT		SRAM_DATA
	
	LOADI 	41			;write the value 41 to &H0009
	OUT		SRAM_DATA
	
	LOADI 	42			;write the value 42 to &H000A
	OUT		SRAM_DATA
	
	LOADI 	43			;write the value 43 to &H000B
	OUT		SRAM_DATA
	
	LOADI 	44			;write the value 44 to &H000C
	OUT		SRAM_DATA
	
	LOADI 	45			;write the value 45 to &H000D
	OUT		SRAM_DATA
	
	LOADI 	46			;write the value 46 to &H000E
	OUT		SRAM_DATA
	
	LOADI 	47			;write the value 47 to &H000F
	OUT		SRAM_DATA
	
	LOADI 	48			;write the value 48 to &H0010
	OUT		SRAM_DATA
	
	LOADI 	49			;write the value 49 to &H0011
	OUT		SRAM_DATA
	
	LOADI 	50			;write the value 50 to &H0012
	OUT		SRAM_DATA
	
	LOADI 	51			;write the value 51 to &H0013
	OUT		SRAM_DATA
;change the direction to decrement addresses
    LOADI  &B10
    OUT    SRAM_DIR
    
   	IN     SRAM_DATA    ;read 50 from &H0012
    IN     SRAM_DATA    ;read 49 from &H0011
    IN     SRAM_DATA    ;read 48 from &H0010
    IN     SRAM_DATA    ;read 47 from &H000F
    IN     SRAM_DATA    ;read 46 from &H000E
    IN     SRAM_DATA    ;read 45 from &H000D
    IN     SRAM_DATA    ;read 44 from &H000C
    IN     SRAM_DATA    ;read 43 from &H000B
    IN     SRAM_DATA    ;read 42 from &H000A
    IN     SRAM_DATA    ;read 41 from &H0009
    IN     SRAM_DATA    ;read 40 from &H0008
    IN     SRAM_DATA    ;read 39 from &H0007
    IN     SRAM_DATA    ;read 38 from &H0006
    IN     SRAM_DATA    ;read 37 from &H0005
    IN     SRAM_DATA    ;read 36 from &H0004
    IN     SRAM_DATA    ;read 35 from &H0003
    IN     SRAM_DATA    ;read 34 from &H0002
    IN     SRAM_DATA    ;read 33 from &H0001
    IN     SRAM_DATA    ;read 32 from &H0000
    
   	
		
Done:

	JUMP	Done



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
SRAM_DIR: EQU &H13 ; 00 for same addr, 01 for increment, 10 for decrement