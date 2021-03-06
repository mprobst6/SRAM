LIBRARY IEEE;
LIBRARY ALTERA_MF;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY SLOW_SRAM_VHDL IS
	PORT(
		IO_WRITE       : IN STD_LOGIC;
		SRAM_ADHI_EN   : IN STD_LOGIC;
		SRAM_ADLOW_EN  : IN STD_LOGIC;
		SRAM_DATA_EN   : IN STD_LOGIC;
		SRAM_CTRL_EN   : IN STD_LOGIC;
		IO_DATA        : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);  --SCOMP data, used in the decoder
		SRAM_ADDR      : INOUT STD_LOGIC_VECTOR (17 DOWNTO 0);
		SRAM_OE_N      : OUT STD_LOGIC;
		SRAM_DQ        : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);  --this is the SRAM data
		SRAM_WE_N      : OUT STD_LOGIC;
		SRAM_UB_N      : OUT STD_LOGIC; --always make active (drive low)
		SRAM_LB_N      : OUT STD_LOGIC; --always make active (drive low)
		SRAM_CE_N      : OUT STD_LOGIC; --always make active (drive low)
		SRAM_CTRL_EX   : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)

	);
END SLOW_SRAM_VHDL;


ARCHITECTURE a OF SLOW_SRAM_VHDL IS
    SIGNAL SRAM_CTRL   : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL Q2          : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL Clk0        : STD_LOGIC;
    SIGNAL Clk1        : STD_LOGIC;
    SIGNAL Clk2        : STD_LOGIC;
    SIGNAL Clk3        : STD_LOGIC;
    
BEGIN
--IO bus that connects the Q2 (from flipflop 2) with the SRAM data.
--Data may only be passed when Output_Drive, which comes from SRAM_CTRL[2], is high
IO_BUS0: LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => Q2,
		enabledt => SRAM_CTRL(2),
		tridata  => SRAM_DQ
	);
--IO bus that connects SRAM data with IO data.
--Once data is retreived from SRAM, IO_WRITE must be low and SRAM_DATA_EN must be high	
IO_BUS1: LPM_BUSTRI
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => SRAM_DQ,
		enabledt => ((NOT IO_WRITE) AND SRAM_DATA_EN),
		tridata  => IO_DATA
	);
--Flipflop to drive the bottom sixteen bits of the SRAM address with IO_DATA from SCOMP.
--Clk0 is SRAM low address enable from the decoder and IO_WRITE from SCOMP
	PROCESS (Clk0)
	BEGIN
		IF Clk0'EVENT AND Clk0 = '1' THEN
			SRAM_ADDR (15 DOWNTO 0) <= IO_DATA (15 DOWNTO 0);
		END IF;
	END PROCESS;

--Flipflop to drive the top two bits of the SRAM address with IO_DATA from SCOMP
--Clk1 is SRAM high address enable from the decoder and IO_WRITE from SCOMP
	PROCESS (Clk1)
	BEGIN
		IF Clk1'EVENT AND Clk1 = '1' THEN
			SRAM_ADDR (17 DOWNTO 16) <= IO_DATA (1 DOWNTO 0);
		END IF;
	END PROCESS;
	
--Flipflop to drive all sixteen bits of SRAM data.
--Q2 is used instead of SRAM_DQ because Q2 must pass through a series of buffers.
--Clk2 is SRAM data enable from the decoder and IO_WRITE from SCOMP
	PROCESS (Clk2)
	BEGIN
		IF Clk2'EVENT AND Clk2 = '1' THEN
			Q2 (15 DOWNTO 0) <= IO_DATA (15 DOWNTO 0);
		END IF;
	END PROCESS;

--Flipflop to drive three bits of SRAM control signal.
--SRAM control signal communicates with the SRAM chip to enable read and write capabilities.
--Clk3 is Sram control enable from the decoder and IO_WRITE from SCOMP
	PROCESS (Clk3)
	BEGIN
		IF Clk3'EVENT AND Clk3 = '1' THEN
			SRAM_CTRL (2 DOWNTO 0) <= IO_DATA (2 DOWNTO 0);
		END IF;
	END PROCESS;
			
	Clk0 <= (IO_WRITE AND SRAM_ADHI_EN);
	Clk1 <= (IO_WRITE AND SRAM_ADLOW_EN);
	Clk2 <= (IO_WRITE AND SRAM_DATA_EN);
	Clk3 <= (IO_WRITE AND SRAM_CTRL_EN); --possible SRAM_CTRL_EN is always enabled, so whenever IO_WRITE changes, it gets writeen to SRAM_CTRL_EN
	SRAM_OE_N <= SRAM_CTRL(0);
	SRAM_WE_N <= SRAM_CTRL(1);
	SRAM_CE_N <= '0'; --active low
	SRAM_UB_N <= '0'; --active low
	SRAM_LB_N <= '0'; --active low
	SRAM_CTRL_EX <= SRAM_CTRL;
END a;