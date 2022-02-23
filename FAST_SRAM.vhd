LIBRARY IEEE;
LIBRARY LPM;


USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY FAST_SRAM IS
	PORT(
		clk            : IN STD_LOGIC;  --25MHz clock
		IO_WRITE       : IN STD_LOGIC;  --goes active whenever the simple computer is outputting to the IO peripheral
		SRAM_ADHI_EN   : IN STD_LOGIC;  --enables user to change the high sixteen bits of the memory address
		SRAM_ADLOW_EN  : IN STD_LOGIC;  --enables user to change the low sixteen bits of the memory address
		SRAM_DATA_EN   : IN STD_LOGIC;  --data to and from the simple computer
		SRAM_DIR_EN	   : IN STD_LOGIC;  --controls the direction of the increment
		IO_DATA        : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);  --SCOMP data, used in the decoder
		SRAM_ADDR      : OUT STD_LOGIC_VECTOR (17 DOWNTO 0);  --memory address for SRAM
		SRAM_OE_N      : OUT STD_LOGIC; --output enable for SRAM
		SRAM_DQ        : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);  --data to and from SRAM
		SRAM_WE_N      : OUT STD_LOGIC; --write enable for SRAM
		SRAM_UB_N      : OUT STD_LOGIC; --always make active (drive low)
		SRAM_LB_N      : OUT STD_LOGIC; --always make active (drive low)
		SRAM_CE_N      : OUT STD_LOGIC  --always make active (drive low)

	);
END FAST_SRAM;

ARCHITECTURE a OF FAST_SRAM IS

TYPE STATE_TYPE IS (
				RESET,
				ADJUST_ADDR,
				SET_HIGH, 
				SET_LOW,
				GET_ADDR1,
				GET_ADDR2,
				GET_ADDR3,
				GET_ADDR4,
				WRITE_ENABLE, 
				WRITE_DATA,
				DEASSERT_WRITE,
				READ_ENABLE,
				READ_DATA1,
				READ_DATA2,
				READ_DATA3,
				DEASSERT_OUT,
				DEASSERT_READ,
				SET_ADDRESS
			);
--consider a variable to specify whether reading up or down the memory (gotem)
SIGNAL state             : STATE_TYPE;
SIGNAL DATA_INT          : STD_LOGIC_VECTOR (15 DOWNTO 0);
SIGNAL SRAM_ADDR_INT     : STD_LOGIC_VECTOR (17 DOWNTO 0); --interal signal because next address based on previous
SIGNAL ONE 				 : STD_LOGIC; --used to increment the memory address
SIGNAL ENABLE_OUT        : STD_LOGIC; --tells the IO peripheral that the simple computer is performing a write
SIGNAL ENABLE_IN         : STD_LOGIC; --tells the IO peripheral that the simple computer is performing a read
SIGNAL ENABLE_GET        : STD_LOGIC; --tells the IO peripheral that the simple computer is requesting a memory address
SIGNAL SEQ_DIR			 : STD_LOGIC_VECTOR (1 DOWNTO 0); --the direction of the incrementation
SIGNAL SEQ_DIR_TEMP		 : STD_LOGIC_VECTOR (1 DOWNTO 0); --the next direction of the incrementation

BEGIN
--This IO bus used during writes. It activates the line that allows IO_DATA to drive SRAM_DQ
	IO_BUS: LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => DATA_INT,
		enabledt => ENABLE_OUT,
		tridata  => SRAM_DQ
	);
--This bus is used during reads to drive IO_DATA with SRAM_DQ
	IO_BUS2: LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => SRAM_DQ,
		enabledt => ENABLE_IN,
		tridata  => IO_DATA
	);
	
--This bus is used when retrieving the memory dress by drive IO_DATA with DATA_INT
	IO_BUS3 : LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => DATA_INT,
		enabledt => ENABLE_GET,
		tridata  => IO_DATA
	);
    PROCESS (clk)
    BEGIN
		IF clk'EVENT AND clk = '1' THEN
		   CASE state IS
				WHEN RESET =>
					SRAM_OE_N <= '1'; --inactive during the reset state
					SRAM_WE_N <= '1'; --inactive during the reset state
		

					IF((SRAM_DIR_EN AND IO_WRITE) = '1') THEN
						SEQ_DIR <= IO_DATA(1 DOWNTO 0); --SEQ_DIR will determine which way the machine will increment
						state <= ADJUST_ADDR;
					END IF;
					
--Below are the setters and getters for the high and low bits of the address. They are accessed using an in or out
--statement, same as data.
					IF((SRAM_ADHI_EN AND IO_WRITE) = '1') THEN
						state <= SET_HIGH;   --state to set the high address
					END IF;
					
					IF ((SRAM_ADLOW_EN AND IO_WRITE) = '1') THEN						
						state <= SET_LOW;    --state to set the low address
					END IF;
					
					IF((SRAM_ADHI_EN AND NOT (IO_WRITE)) = '1') THEN
						DATA_INT (15 DOWNTO 0) <= "00000000000000" & SRAM_ADDR_INT (17 DOWNTO 16); --state to get the high address
						ENABLE_GET <= '1'; --enabled early to save a state during the read
						state <= GET_ADDR1;
					END IF;
					
					IF((SRAM_ADLOW_EN AND (NOT IO_WRITE)) = '1') THEN
						DATA_INT (15 DOWNTO 0) <= SRAM_ADDR_INT (15 DOWNTO 0); --state to get the low address
						ENABLE_GET <= '1'; --enabled early to save a state during the read
						state <= GET_ADDR1;
					END IF;
					
					IF ((SRAM_DATA_EN AND IO_WRITE) = '1') THEN
						ENABLE_OUT <= '1';
						SRAM_WE_N <= '0';
						DATA_INT <= IO_DATA;				--consider putting write enable here to save a state
						state <= WRITE_ENABLE; --state to write data
					END IF;
					IF((SRAM_DATA_EN AND (NOT IO_WRITE)) = '1') THEN
						SRAM_OE_N <= '0';
						state <= READ_ENABLE;  --state to read data
					END IF;
				
				WHEN ADJUST_ADDR =>
					IF((SEQ_DIR_TEMP = "01") AND NOT(SEQ_DIR = "01")) THEN
						IF(SEQ_DIR = "00") THEN
							SRAM_ADDR_INT <= SRAM_ADDR_INT - ONE;
						ELSIF(SEQ_DIR = "10") THEN
							SRAM_ADDR_INT <= SRAM_ADDR_INT - ONE - ONE;
						END IF;
					ELSIF((SEQ_DIR_TEMP = "10") AND NOT(SEQ_DIR = "10")) THEN
						IF(SEQ_DIR = "00") THEN
							SRAM_ADDR_INT <= SRAM_ADDR_INT + ONE;
						ELSIF(SEQ_DIR = "01") THEN
							SRAM_ADDR_INT <= SRAM_ADDR_INT + ONE + ONE;
						END IF;
					END IF;
					state <= SET_ADDRESS;
								
				WHEN SET_HIGH =>
					SRAM_ADDR(17 DOWNTO 16) <= IO_DATA (1 DOWNTO 0);      --drives the top two bits of the address
					SRAM_ADDR_INT (17 DOWNTO 16) <= IO_DATA (1 DOWNTO 0); --this is needed to drive the next address with the current plus one. Since IO_ADDR is an output, it can't drive anything
					state <= RESET;
					
				WHEN SET_LOW =>
					SRAM_ADDR(15 DOWNTO 0) <= IO_DATA; --drives the bottom two bits of the address
					SRAM_ADDR_INT (15 DOWNTO 0) <= IO_DATA;
					state <= RESET;
				WHEN GET_ADDR1 =>  --the next ensure that the IO_DATA line is driven for the entirety of the EX_IN state on the simple ocmputer
					state <= GET_ADDR2;				
				WHEN GET_ADDR2 =>
					state <= GET_ADDR3;
				WHEN GET_ADDR3 =>
					state <= GET_ADDR4;
				WHEN GET_ADDR4 =>
					ENABLE_GET <= '0';
					state <= RESET;
				
					
--Four states to safely perform a write command. The state then goes into increment address before reset				
				WHEN WRITE_ENABLE =>
					state <= WRITE_DATA;  --extra state for WE to be asserted
					
				WHEN WRITE_DATA =>
					IF(SEQ_DIR = "01") THEN
						SRAM_ADDR_INT <= SRAM_ADDR_INT + ONE ;
					ELSIF(SEQ_DIR = "10") THEN
						SRAM_ADDR_INT <= SRAM_ADDR_INT - ONE;
					ELSE 
						SRAM_ADDR_INT <= SRAM_ADDR_INT;
					END IF;
					SRAM_WE_N <= '1';
					
					state <= DEASSERT_WRITE;
					
				WHEN DEASSERT_WRITE =>
					ENABLE_OUT <= '0';
					state <= SET_ADDRESS;
					
--Five states to safely read data from SRAM. Extra read states ensure data is active during the falling
--edge of EX_IN in SCOMP.				
				WHEN READ_ENABLE =>
					ENABLE_IN  <= '1';
					state <= READ_DATA1;
					
				WHEN READ_DATA1 =>
					state <= READ_DATA2;
					
				WHEN READ_DATA2 =>
					state <= READ_DATA3;
					
				WHEN READ_DATA3 =>
					IF(SEQ_DIR = "01") THEN
						SRAM_ADDR_INT <= SRAM_ADDR_INT + ONE; --OE continues to be asserted
					ELSIF(SEQ_DIR = "10") THEN
						SRAM_ADDR_INT <= SRAM_ADDR_INT - ONE;
					ELSE 
						SRAM_ADDR_INT <= SRAM_ADDR_INT;
					END IF;
					ENABLE_IN  <= '0';
					state <= DEASSERT_READ;               --ENABLE_IN is asserted in this state only
					
				WHEN DEASSERT_READ =>
					SRAM_OE_N <= '1';					  --OE is deasserted
					state <= SET_ADDRESS;	
		  
					
				WHEN SET_ADDRESS =>
					SEQ_DIR_TEMP <= SEQ_DIR;
					SRAM_ADDR <= SRAM_ADDR_INT;
					state <= RESET;

				WHEN OTHERS =>
					state <= RESET;
			END CASE;
		END IF;
    END PROCESS;
 
	ONE <= '1'; 			
	SRAM_UB_N <= '0';
	SRAM_LB_N <= '0';
	SRAM_CE_N <= '0';
	

END a;