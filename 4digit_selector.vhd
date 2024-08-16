library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY calcArithmetic IS
PORT(
    clk         	: in STD_LOGIC;
    btnVal      	: in STD_LOGIC_VECTOR(3 downto 0);
    btnPress    	: in STD_LOGIC;
    newNumReady 	: out STD_LOGIC;
    displayPort 	: out STD_LOGIC_VECTOR(19 downto 0);
	overflow_port 	: out std_logic);
END calcArithmetic;

ARCHITECTURE behavior OF calcArithmetic IS

-- Constants
signal termBuffer : STD_LOGIC_VECTOR(15 downto 0) := (others=>'0');

-- FSM Signals
TYPE stateType IS (sIdle, sLoadTerm1, sLoadTerm2, sResult, sClear, sSaveResult);
SIGNAL currentState, nextState : stateType := sIdle;

-- Register Signals
SIGNAL term1Reg   : UNSIGNED(19 downto 0) := (others=>'0');
SIGNAL term2Reg   : UNSIGNED(19 downto 0) := (others=>'0');
SIGNAL resultReg  : UNSIGNED(19 downto 0) := (others=>'0');
SIGNAL term1En    : STD_LOGIC := '0';
SIGNAL term2En    : STD_LOGIC := '0';
SIGNAL resultEn   : STD_LOGIC := '0';
SIGNAL term1Clr   : STD_LOGIC := '0';
SIGNAL term2Clr   : STD_LOGIC := '0';
SIGNAL resultClr  : STD_LOGIC := '0';
SIGNAL opReg  	  : STD_LOGIC_VECTOR(1 downto 0) := "00";
SIGNAL opRegClr   : STD_LOGIC := '0';
SIGNAL digit1  	  : UNSIGNED(9 downto 0) := (others => '0');
SIGNAL digit2  	  : UNSIGNED(9 downto 0) := (others => '0');

-- Control Signals
SIGNAL addPressed 	: STD_LOGIC := '0';
SIGNAL subPressed  	: STD_LOGIC := '0';
SIGNAL multPressed 	: STD_LOGIC := '0';
SIGNAL divPressed  	: STD_LOGIC := '0';

SIGNAL opPressed    : STD_LOGIC := '0';
SIGNAL clearPressed : STD_LOGIC := '0';
SIGNAL eqPressed    : STD_LOGIC := '0';
signal numPressed   : STD_LOGIC := '0';
SIGNAL saveResult   : STD_LOGIC := '0';
SIGNAL firstValue  	: STD_LOGIC := '0';
SIGNAL secondValue  : STD_LOGIC := '0';

-- Counter Signals
SIGNAL digitCounter1   	: UNSIGNED(1 downto 0) := (others => '0');
SIGNAL digitCounterEn1 	: STD_LOGIC := '0';
SIGNAL digitCounterClr1 : STD_LOGIC := '0';
SIGNAL digitCounter2   	: UNSIGNED(1 downto 0) := (others => '0');
SIGNAL digitCounterEn2 	: STD_LOGIC := '0';
SIGNAL digitCounterClr2 : STD_LOGIC := '0';

BEGIN

    -- State update process for the finite state machine
    stateUpdate: PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            currentState <= nextState;
        END IF;
    END PROCESS stateUpdate;

    -- Next state logic for the finite state machine
    nextStateLogic: PROCESS(currentState, btnPress, clearPressed, eqPressed, opPressed)
    BEGIN
        -- Set default values for nextState
        nextState <= currentState;

        CASE currentState IS
            WHEN sIdle =>
                IF ((btnPress = '1') AND (NOT(clearPressed = '1'))) THEN
                    nextState <= sLoadTerm1;
                ELSIF ((btnPress = '1') AND (clearPressed = '1')) THEN
                    nextState <= sIdle;
                END IF;
            WHEN sLoadTerm1 =>
                IF (opPressed = '1') THEN
                    nextState <= sLoadTerm2;
                ELSIF (clearPressed = '1') THEN
                    nextState <= sIdle;
                END IF;
            WHEN sLoadTerm2 =>
                IF (eqPressed = '1') THEN
                    nextState <= sResult;
                ELSIF (clearPressed = '1') THEN
                    nextState <= sIdle;
                END IF;
            WHEN sResult =>
                IF (opPressed = '1') THEN
                    nextState <= sClear;
                ELSIF (clearPressed = '1') THEN
                    nextState <= sIdle;
                END IF;
            WHEN sClear =>
				nextState <= sSaveResult;
            WHEN sSaveResult =>
                nextState <= sLoadTerm2;
                IF (clearPressed = '1') THEN
                    nextState <= sIdle;
                END IF;
            WHEN OTHERS =>
                nextState <= sIdle; -- Just to take care of possible "ghost" states
        END CASE;
    END PROCESS nextStateLogic;

    -- Output state logic for the finite state machine
    outputLogic: PROCESS(currentState)
    BEGIN
        -- Set default values for control signals
        term1En <= '0';
        term2En <= '0';
        resultEn <= '0';
        digitCounterEn1 <= '0';
        digitCounterClr1 <= '0';
        digitCounterEn2 <= '0';
        digitCounterClr2 <= '0';
        term1Clr <= '0';
        term2Clr <= '0';
        resultClr <= '0';
        opRegClr <= '0';
        saveResult <= '0';

        CASE currentState IS
            WHEN sIdle =>
				term1Clr <= '1';
                term2Clr <= '1';
                resultClr <= '1';
                digitCounterClr1 <= '1';
                digitCounterClr2 <= '1';
                opRegClr <= '1';
            WHEN sLoadTerm1 =>
                term1En <= '1';
                digitCounterEn1 <= '1';
            WHEN sLoadTerm2 =>
                term2En <= '1';
                digitCounterEn2 <= '1';
            WHEN sResult =>
                resultEn <= '1';
            WHEN sClear =>
                term2Clr <= '1';
                digitCounterClr1 <= '1';
                digitCounterClr2 <= '1';
            WHEN sSaveResult =>
                saveResult <= '1';
            WHEN OTHERS =>
                NULL; -- Just to take care of possible "ghost" states
        END CASE;
    END PROCESS outputLogic;

    -- Synchronous processes datapath (counter/registers)
    synchronousProcess: PROCESS(clk)
    BEGIN

        IF rising_edge(clk) THEN
            -- Update registers
           
            -- term1 Reg
            IF (term1Clr = '1') THEN
                term1Reg <= (OTHERS => '0');
            ELSIF (((term1En = '1') AND (not(digitCounter1 = "11")) AND (numPressed='1') AND (btnPress='1')) OR (firstValue = '1')) THEN
				term1Reg <= ((term1Reg(15 downto 0) * to_unsigned(10,4)) + unsigned(termBuffer & btnVal));
            ELSIF (saveResult = '1') THEN
				term1Reg <= resultReg;          
            END IF;

			-- term2 Reg
            IF (term2Clr = '1') THEN
                term2Reg <= (OTHERS => '0');
            ELSIF (((term2En = '1') AND (not(digitCounter2 = "11")) AND (numPressed = '1') AND (btnPress='1')) OR (secondValue = '1')) THEN
			     term2Reg <= ((term2Reg(15 downto 0) * to_unsigned(10,4)) + unsigned(termBuffer & btnVal));
            END IF;
           
            -- op Reg
            IF (opRegClr = '1') THEN
				opReg <= (OTHERS => '0');
            ELSIF (addPressed = '1') THEN
				opReg <= "01";
            ELSIF (subPressed = '1') THEN
				opReg <= "10";
            ELSIF (multPressed = '1') THEN
				opReg <= "11";
            END IF;

			-- result Reg
            IF (resultClr = '1') THEN
                resultReg <= (OTHERS => '0');
            ELSIF (resultEn = '1') THEN
                IF (opReg = "01") THEN -- Add the terms
                    resultReg <= resize((term1Reg + term2Reg),20);
                ELSIF (opReg = "10") THEN
                    resultReg <= resize((term1Reg - term2Reg),20);
                ELSIF (opReg = "11") THEN
                    resultReg <= resize((term1Reg * term2Reg),20);
                END IF;
            END IF;

            -- Update counter for term1 digits
            IF (digitCounterClr1 = '1') THEN
                digitCounter1 <= (OTHERS => '0');
            ELSIF (((digitCounterEn1 = '1') AND (numPressed = '1') AND (btnPress = '1') AND (not(digitCounter1 = "11"))) OR (firstValue = '1')) THEN
                digitCounter1 <= digitCounter1 + 1;
            END IF;
           
            -- Update counter for term2 digits
            IF (digitCounterClr2 = '1') THEN
                digitCounter2 <= (OTHERS => '0');
            ELSIF (((digitCounterEn2 = '1') AND (numPressed = '1') AND (btnPress = '1') AND (not(digitCounter2 = "11"))) OR (secondValue = '1')) THEN
                digitCounter2 <= digitCounter2 + 1;
            END IF;
        END IF;
    END PROCESS synchronousProcess;

    -- Asynchronous process (comparators)
    asynchronousProcess: PROCESS(btnVal, digitCounter1, digitCounter2, btnPress, currentState, term1Reg, term2Reg, resultReg)
    BEGIN
   
        -- Reset control signals
        addPressed <= '0';
        subPressed <= '0';
        multPressed <= '0';
        divPressed <= '0';  
        opPressed <= '0';
        clearPressed <= '0';
        eqPressed <= '0';
        numPressed <= '0';      
        newNumReady <= '0';
   
		-- Control Signals
		IF (btnVal = "1010") THEN --A(Add)
			addPressed <= '1';
			opPressed <= '1';
        ELSIF (btnVal = "1011")  THEN --B(Sub)
			subPressed <= '1';
			opPressed <= '1';
        ELSIF (btnVal = "1100")  THEN --C(Mult)
			multPressed <= '1';
			opPressed <= '1';
        ELSIF (btnVal = "1101") THEN --D(Divide)
			divPressed <= '1';
			opPressed <= '1';
	    ElSIF (btnVal = "1111") THEN
            clearPressed <= '1';
        ELSIF (btnVal = "1110") THEN
            eqPressed <= '1';
        ELSE
            numPressed <= '1';
        END IF;
                                    
        IF ((digitCounter1 = "00") AND (btnPress = '1') AND (currentState = sIdle)) THEN
			firstValue <= '1';
        ELSIF ((digitCounter1 = "00") AND (currentState = sLoadTerm1)) THEN
			firstValue <= '1';
	    else  
	        firstValue <= '0';
        END IF;
       
        IF (((digitCounter1 = "00") OR (digitCounter2 = "00")) AND (btnPress = '1') AND (currentState = sSaveResult)) THEN
			secondValue <= '1';
	    else
	       secondValue <= '0';
        END IF;
       
		-- Overflow logic
		IF (resultReg > "11110100001000111111") THEN -- greater than 999999
			overflow_port <= '1';
		ELSE 
			overflow_port <= '0';
	    END IF;
       
        -- choose which term to display based on current state
        IF (currentState = sLoadTerm1) THEN
            displayPort <= std_logic_vector(term1Reg);
            newNumReady <= '1';
        ELSIF (currentState = sLoadTerm2) THEN
            displayPort <= std_logic_vector(term2Reg);
            newNumReady <= '1';
        ELSIF (currentState = sResult) THEN
            displayPort <= std_logic_vector(resultReg);
            newNumReady <= '1';
        ELSE
            displayPort <= (others=>'0');
            newNumReady <= '1';
        END IF;
    END PROCESS asynchronousProcess;

END behavior;
