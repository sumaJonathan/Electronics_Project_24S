library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DibleDabble is
    Port (
        clk        : in  std_logic;
        binary_in  : in  std_logic_vector(19 downto 0); --20 bit number
        start      : in  std_logic; -- signal from the calculator
        
        bcd_out    : out std_logic_vector(23 downto 0);  -- Output BCD number (5 BCD digits)
        bcd_out1   : out std_logic_vector(3 downto 0);
        bcd_out2   : out std_logic_vector(3 downto 0);
        bcd_out3   : out std_logic_vector(3 downto 0);
        bcd_out4   : out std_logic_vector(3 downto 0);
        bcd_out5   : out std_logic_vector(3 downto 0);
        bcd_out6   : out std_logic_vector(3 downto 0)
    );
end DibleDabble;

architecture Behavioral of DibleDabble is
--FSM signals
    type state_type is (IDLE, LOAD, SHIFT, CHECK, sDONE);
    signal curr_state, next_state       : state_type := IDLE;
	
--Datapath signals
    signal shift_count : unsigned (4 downto 0) := (others => '0');
    signal bcd_reg     : std_logic_vector(43 downto 0) := (others => '0');

--Control signals
    signal reg_clr, shift_en, check_en, load_en, shift_done, update_en     :  std_logic;
    signal bcd0_tc, bcd1_tc, bcd2_tc, bcd3_tc, bcd4_tc, bcd5_tc : std_logic := '0';
    
    constant MAX_CNT : integer := 20;
    
begin


-- ===== FSM code =====
-- ++++ 
-- Update the current state
-- +++++
UpdateState: process(clk)
begin
	if rising_edge(clk) then
    	curr_state <= next_state;
    end if;
end process UpdateState;

-- ++++ 
-- Update the next states
-- +++++
NextStateProc:process(clk, curr_state, start, shift_done)
begin
	next_state <= curr_state;
    
    case curr_state is
    when IDLE =>
    	if (start = '1') then
        	next_state <= LOAD;
        end if;
    when LOAD =>
    	next_state <= SHIFT;
    when SHIFT =>
		next_state <= CHECK;
    when CHECK =>
    	if (shift_done = '1') then
        	next_state <= sDONE;
        else
        	next_state <= SHIFT;
        end if;
    when sDone =>
    	next_state <= IDLE;
    when others =>
    	next_state <= IDLE;
    end case;
end process NextStateProc;

-- ++++ 
-- Output for each state
-- +++++
OutputProc:process(clk, curr_state)
begin
	shift_en <= '0';
    load_en <= '0';
    update_en <= '0';
    reg_clr <= '0';
    check_en <= '0';
    
    
    case curr_state is
    when IDLE =>
    	reg_clr <= '1';
    when LOAD =>
    	load_en <= '1';
    when SHIFT =>
		shift_en <= '1';
    when CHECK =>
		check_en <= '1';
    when sDONE =>
		update_en <= '1';
    when others => NULL;
    end case;
end process OutputProc;

-- ===== DataPath code =====
BCD_converter: process(clk, shift_count, bcd_reg)
begin
--SYNCHRONOUS (registers, counters)
	if rising_edge(clk) then
    	if (reg_clr = '1') then
        	bcd_reg <= (others => '0');
            shift_count <= (others => '0');
        else
            if(shift_done = '1') then
                shift_count <= (others => '0');
            end if;
            
            if(load_en = '1') then
                bcd_reg (19 downto 0) <= binary_in;
            end if;
            
            if(shift_en = '1') then
                -- Shift left
                bcd_reg <= bcd_reg(42 downto 0) & '0';
                shift_count <= shift_count + 1;
            end if;
            
            if (check_en = '1' and shift_done = '0') then
                -- Add 3 if any nibble is greater than 4
                if (bcd_reg(23 downto 20) > "0100") then
                	bcd_reg(23 downto 20) <= bcd_reg(23 downto 20) + "0011";
                end if;
                
                if (bcd_reg(27 downto 24) > "0100") then
                    bcd_reg(27 downto 24) <= bcd_reg(27 downto 24) + "0011";
                end if;


                if (bcd_reg(31 downto 28) > "0100") then
                    bcd_reg(31 downto 28) <= bcd_reg(31 downto 28) + "0011";
                end if;
                
                if (bcd_reg(35 downto 32) > "0100") then
                    bcd_reg(35 downto 32) <= bcd_reg(35 downto 32) + "0011";
                end if;

                if (bcd_reg(39 downto 36) > "0100") then
                    bcd_reg(39 downto 36) <= bcd_reg(39 downto 36) + "0011";
                end if;

                if (bcd_reg(43 downto 40) > "0100") then
                    bcd_reg(43 downto 40) <= bcd_reg(43 downto 40) + "0011";
                   
                end if;
            end if;
            
            if(update_en = '1') then
                bcd_out <= bcd_reg(43 downto 20);
                bcd_out1 <= bcd_reg(23 downto 20);
                bcd_out2 <= bcd_reg(27 downto 24);
                bcd_out3 <= bcd_reg(31 downto 28);
                bcd_out4 <= bcd_reg(35 downto 32);
                bcd_out5 <= bcd_reg(39 downto 36);
                bcd_out6 <= bcd_reg(43 downto 40);
            end if;
        end if;
        
    end if;
    
-- ASYNCHRONOUS (comparators)

    if (shift_count = 20) then
        shift_done <= '1';
    else
        shift_done <= '0';
    end if;
end process BCD_converter;

end Behavioral;

