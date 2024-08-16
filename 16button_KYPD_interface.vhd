-- Company: Digilent Inc 2011
-- Engineer: Michelle Yu  
-- Create Date:      17:18:24 08/23/2011 
-- 
-- Module Name:    Decoder - Behavioral 
-- Project Name:  PmodKYPD
-- Target Devices: Nexys3(Modified for Basys3)
-- Tool versions: Xilinx ISE 13.2
-- Description: 
--	This file defines a component Decoder for the demo project PmodKYPD. 
-- The Decoder scans each column by asserting a low to the pin corresponding to the column 
-- at 1KHz. After a column is asserted low, each row pin is checked. 
-- When a row pin is detected to be low, the key that was pressed could be determined.
--
-- Revision: 
-- Revision 0.01 - File Created
--
-- Adapted & Modified by Jonathan S. and Rashad M.
-- Date: May 2024
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
    Port (
			clk : in  STD_LOGIC;
			Row : in  STD_LOGIC_VECTOR (3 downto 0);
			Col : out  STD_LOGIC_VECTOR (3 downto 0);
			DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0);
			btnPress  : out std_logic);
end Decoder;

architecture Behavioral of Decoder is

signal sclk             :STD_LOGIC_VECTOR(11 downto 0) := (others=>'0');
signal DecodeOut_reg    :std_logic_vector(3 downto 0) := (others=>'0');f 
signal DecodeOut_mp     :std_logic := '0';

signal row_reg0         : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg1         : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg2         : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg3         : std_logic_vector(3 downto 0) := (others=>'1');

signal row_reg0_old     : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg1_old     : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg2_old     : std_logic_vector(3 downto 0) := (others=>'1');
signal row_reg3_old     : std_logic_vector(3 downto 0) := (others=>'1');

signal col_reg          : std_logic_vector(3 downto 0) := (others=>'1');
signal col_reg_old      : std_logic_vector(3 downto 0) := (others=>'1');

signal Row_reg          : std_logic_vector(15 downto 0) := (others=>'1');
signal Row_reg_prev     : std_logic_vector(15 downto 0) := (others=>'1');

-- Counter Signals
SIGNAL clkDiv_counter : UNSIGNED(17 downto 0) := (OTHERS => '0');
SIGNAL clkDiv_tc : STD_LOGIC := '0';


begin
	process(clk, row_reg0, row_reg1, row_reg2, row_reg3, row_reg0_old, row_reg1_old, row_reg2_old, row_reg3_old,Row_reg, Row_reg_prev)
		begin 
		if rising_edge(clk) then
			-- 1ms
					
			if sclk = "001111101000" then 
				--C1
				Col<= "0111";
				sclk <= sclk+1;
			-- check row pins
			elsif sclk = "001111110000" then	
				--R1
			     row_reg0 <= Row;
				if Row = "0111" then
					DecodeOut_reg <= "0001";	--1		
				--R2
				elsif Row = "1011" then
					DecodeOut_reg <= "0100"; --4 				
				--R3
				elsif Row = "1101" then
					DecodeOut_reg <= "0111"; --7					
				--R4
				elsif Row = "1110" then
					DecodeOut_reg <= "0000"; --0						
				end if;
				sclk <= sclk+1;
			-- 2ms
			elsif sclk = "011111010000" then	
				--C2
				Col<= "1011";
				sclk <= sclk+1;
			-- check row pins
			elsif sclk = "011111011000" then
				row_reg1 <= Row;	
				--R1
				if Row = "0111" then
					DecodeOut_reg <= "0010"; --2				
				--R2
				elsif Row = "1011" then
					DecodeOut_reg <= "0101"; --5				
				--R3
				elsif Row = "1101" then
					DecodeOut_reg <= "1000"; --8				
				--R4
				elsif Row = "1110" then
					DecodeOut_reg <= "1111"; --F					
				end if;
				sclk <= sclk+1;	
			--3ms
			elsif sclk = "101110111000" then 
				--C3
				Col<= "1101";
				sclk <= sclk+1;
			-- check row pins
			elsif sclk = "101111000000" then 
			     row_reg2 <= Row;
				--R1
				if Row = "0111" then
					DecodeOut_reg <= "0011"; --3 					
				--R2
				elsif Row = "1011" then
					DecodeOut_reg <= "0110"; --6			
				--R3
				elsif Row = "1101" then
					DecodeOut_reg <= "1001"; --9			
				--R4
				elsif Row = "1110" then
					DecodeOut_reg <= "1110"; --E				
				end if;
				sclk <= sclk+1;
			--4ms
			elsif sclk = "111110100000" then 			
				--C4
				Col<= "1110";
				sclk <= sclk+1;
			-- check row pins
			elsif sclk = "111110101000" then 
				--R1
				row_reg3 <= Row;
				if Row = "0111" then
					DecodeOut_reg <= "1010"; --A
				--R2
				elsif Row = "1011" then
					DecodeOut_reg <= "1011"; --B				
				--R3
				elsif Row = "1101" then
					DecodeOut_reg <= "1100"; --C;					
				--R4
				elsif Row = "1110" then
					DecodeOut_reg <= "1101"; --D
				end if;
				sclk <= "000000000000";	
			else
				sclk <= sclk+1;	
			end if;
		end if;
		
		Row_reg <= row_reg0 & row_reg1 & row_reg2 & row_reg3;
		Row_reg_prev <= row_reg0_old & row_reg1_old & row_reg2_old & row_reg3_old;
		
		if ( (not(Row_reg) and ((Row_reg_prev))) = "0000000000000000") then
		  DecodeOut_mp <= '0';
		else 
		  DecodeOut_mp <= '1';
	   end if;
		
		if rising_edge(clk) then
            row_reg0_old <= row_reg0; 		
            row_reg1_old <= row_reg1; 		
            row_reg2_old <= row_reg2;             
            row_reg3_old <= row_reg3; 
		end if;
	end process;
	
	---- Monopulser
    monopulser : process(clk)
    begin   
        if rising_edge(clk) then
            if ( DecodeOut_mp = '1') then
               DecodeOut <= DecodeOut_reg;
               btnPress <= '1';
            else
                btnPress <= '0';
            end if;                   
        end if;
    end process;	
			 
end Behavioral;
