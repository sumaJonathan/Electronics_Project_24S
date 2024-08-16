--=============================================================
--Final Project Top Shell
--=============================================================

--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL; -- needed for arithmetic
use ieee.math_real.all; -- needed for automatic register sizing
library UNISIM; -- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Shell Entitity Declarations
--=============================================================
entity FinalProj_topShell is
port (  
	clk_ext_port   	: in  std_logic; --ext 100 MHz clock

    --Keypad inputs and outputs
    row_port      	: in std_logic_vector(3 downto 0);
    column_port   	: out std_logic_vector(3 downto 0);

    --Seven-seg
    DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0);
    btnPress : out  std_logic;
	seg_ext_port  	: out std_logic_vector(0 to 6); --segment control
	dp_ext_port  	: out std_logic; --decimal point control
	an_ext_port  	: out std_logic_vector(3 downto 0) --digit control
	); 
end FinalProj_topShell;

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of FinalProj_topShell is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--System Clock Generation:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component system_clock_generator is
    generic (CLOCK_DIVIDER_RATIO : integer);
	port (
        input_clk_port		: in std_logic;
        system_clk_port	    : out std_logic;
		fwd_clk_port		: out std_logic
	);
end component;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--ButtonProcessor
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component Decoder is
    Port (
			clk : in  STD_LOGIC;
			Row : in  STD_LOGIC_VECTOR (3 downto 0);
			Col : out  STD_LOGIC_VECTOR (3 downto 0);
			DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0);
			btnPress  : out std_logic
    );
end component;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Main Arithmetic Unit
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component calcArithmetic is
	PORT(
		clk         	: in STD_LOGIC;
		btnVal      	: in STD_LOGIC_VECTOR(3 downto 0);
		btnPress    	: in STD_LOGIC;
		newNumReady 	: out STD_LOGIC;
		displayPort 	: out STD_LOGIC_VECTOR(19 downto 0);
		overflow_port 	: out std_logic
	);
end component;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--BinarytoBCD Converter
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component DoubleDabble is
    PORT (
        clk        : in  std_logic;
        binary_in  : in  std_logic_vector(19 downto 0);
        start      : in  std_logic;        
        bcd_out    : out std_logic_vector(23 downto 0);
        bcd_out1   : out std_logic_vector(3 downto 0);
        bcd_out2   : out std_logic_vector(3 downto 0);
        bcd_out3   : out std_logic_vector(3 downto 0);
        bcd_out4   : out std_logic_vector(3 downto 0);
        bcd_out5   : out std_logic_vector(3 downto 0);
        bcd_out6   : out std_logic_vector(3 downto 0)
    );
end component;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Digit Select
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component digSelect is
	PORT (
		clk     : in STD_LOGIC;
		digit0 	: in STD_LOGIC_VECTOR(3 downto 0);
		digit1 	: in STD_LOGIC_VECTOR(3 downto 0);
		digit2 	: in STD_LOGIC_VECTOR(3 downto 0);
		digit3 	: in STD_LOGIC_VECTOR(3 downto 0);
		digit4 	: in STD_LOGIC_VECTOR(3 downto 0);
		digit5 	: in STD_LOGIC_VECTOR(3 downto 0);
		y3_port : out STD_LOGIC_VECTOR(3 downto 0);
		y2_port : out STD_LOGIC_VECTOR(3 downto 0);
		y1_port : out STD_LOGIC_VECTOR(3 downto 0);
		y0_port : out STD_LOGIC_VECTOR(3 downto 0)
	);
end component;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--7 Segment Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component mux7seg is 
    PORT ( clk_port 	: in  std_logic;						-- runs on a fast (1 MHz or so) clock
	       y3_port 	    : in  std_logic_vector (3 downto 0);	-- digits
		   y2_port 	    : in  std_logic_vector (3 downto 0);	-- digits
		   y1_port 	    : in  std_logic_vector (3 downto 0);	-- digits
           y0_port 	    : in  std_logic_vector (3 downto 0);	-- digits
           dp_set_port  : in  std_logic_vector(3 downto 0);     -- decimal points
		   
           seg_port 	: out  std_logic_vector(0 to 6);		-- segments (a...g)
           dp_port 	    : out  std_logic;						-- decimal point
           an_port 	    : out  std_logic_vector (3 downto 0) );	-- anodes
end component;

--=============================================================
--Local Signal Declaration
--=============================================================
-- Clk Generation
signal system_clk 	: std_logic := '0';

-- Btn Processor
signal cols_internal	    : std_logic_vector(3 downto 0) := (others=>'0');
signal rows_internal	    : std_logic_vector(3 downto 0) := (others=>'0');
signal Decode_internal      : std_logic_vector (3 downto 0) := (others=>'0');
signal BtnPress_internal    : std_logic := '0';

-- Main Arithmetic Unit
signal newNumReady_internal : std_logic := '0';
signal displayPort_internal : std_logic_vector(19 downto 0) := (others=>'0');
signal overflow            	: std_logic := '0';

-- BinarytoBCD Converter
signal bcd_out_internal 	: std_logic_vector(23 downto 0);
signal bcd_out0_internal	: std_logic_vector(3 downto 0);
signal bcd_out1_internal	: std_logic_vector(3 downto 0);
signal bcd_out2_internal	: std_logic_vector(3 downto 0);
signal bcd_out3_internal	: std_logic_vector(3 downto 0);
signal bcd_out4_internal	: std_logic_vector(3 downto 0);
signal bcd_out5_internal	: std_logic_vector(3 downto 0);

-- Digit Select
signal y3_internal	: std_logic_vector(3 downto 0) := (others => '0');
signal y2_internal	: std_logic_vector(3 downto 0) := (others => '0');
signal y1_internal	: std_logic_vector(3 downto 0) := (others => '0');
signal y0_internal	: std_logic_vector(3 downto 0) := (others => '0');

-- 7 Seg Display
signal dp_set_port_internal	: std_logic_vector(3 downto 0) := (others => '0');
--=============================================================
--Port Mapping + Processes:
--=============================================================
begin
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timing:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
clocking: system_clock_generator
	generic map(
		CLOCK_DIVIDER_RATIO => 100) -- Clock divider for 1MHz system clock
	port map(
		input_clk_port => clk_ext_port,
		system_clk_port => system_clk);
	
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Btn Interface:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
interface: Decoder
    port map (
        clk        	    => system_clk,
        Row   	 	   => row_port,
        Col		       => column_port, 
        DecodeOut	  => Decode_internal,
        btnPress      => BtnPress_internal);
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Main Arithmetic Unit:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
arithmetic: calcArithmetic
	port map (
		clk 			=> system_clk,
		btnVal			=> Decode_internal,
		btnPress		=> BtnPress_internal,
		newNumReady 	=> newNumReady_internal,
		displayPort		=> displayPort_internal,
		overflow_port 	=> overflow);
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Display
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
bcdConverter: DoubleDabble
	port map (
		clk 		=> system_clk,
		binary_in 	=> displayPort_internal,
		start 		=> newNumReady_internal,
		bcd_out 	=> bcd_out_internal,
		bcd_out0 	=> bcd_out0_internal,
		bcd_out1 	=> bcd_out1_internal,
		bcd_out2 	=> bcd_out2_internal,
		bcd_out3 	=> bcd_out3_internal,
		bcd_out4 	=> bcd_out4_internal,
		bcd_out5 	=> bcd_out5_internal
	);

digitSelection: digSelect
	port map (
		clk 			=> system_clk,
		digit0			=> bcd_out0_internal,
		digit1			=> bcd_out1_internal,
		digit2 			=> bcd_out2_internal,
		digit3			=> bcd_out3_internal,
		digit4			=> bcd_out4_internal,
		digit5			=> bcd_out5_internal,
		y3_port			=> y3_internal,
		y2_port			=> y2_internal,
		y1_port			=> y1_internal,
		y0_port			=> y0_internal);

  dp_set_port_internal <= "000" & overflow;

sevenSeg: mux7seg 
	port map(
		clk_port 		=> system_clk,       -- runs on the 1 MHz clock
		y3_port 		=> y3_internal,        
		y2_port 		=> y2_internal,
		y1_port 		=> y1_internal,
		y0_port 		=> y0_internal,
		dp_set_port    	=> dp_set_port_internal,  
		seg_port 		=> seg_ext_port,
		dp_port 		=> dp_ext_port,
		an_port 		=> an_ext_port );
		   
end Behavioral; 



