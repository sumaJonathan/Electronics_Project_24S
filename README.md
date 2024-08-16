# ENGS 31/CoSc 56 Final Project

**FPGA Simulated Calculator**

This digital system implements a calculator with addition, subtraction, and multiplication as possible operations. We interfaced it with a 16-button keypad manufactured by [Diligent](https://digilent.com/reference/pmod/pmodkypd/start?redirect=1) and developed VHDL code for simulation on the Basys3 FPGA.
We had several components within our system that allowed for successful operation including a system clock generator, a decoder for our button interface, a logic module for calculating arithmetic operations, a binary to BCD converter, a digit selection module, and the seven segment driver for display. We thoroughly tested the components that we ourselves did not create which were all of the components listed except for the seven segment driver and clock generator, all of which are documented in the appendices and described within the following sections:

### 1. System Overview
Our system interfaces a 16 button keypad with a Basys3 microcontroller with an embedded seven segment display to perform addition, subtraction, and multiplication operations and display the results to simulate a calculator.

#### 1.1 Top-Level Shell
>*:link: [Go to top-shell code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/top_shell.vhd)*

The system contains the following components:
>1. System Clock Generator
>2. 16-button Keypad Interface
>3. Arithmetic Logic Unit
>4. Binary-to-BCD converter
>5. 4-digit Selector
>6. 7-segment Display Driver

#### 1.2 Description Of Ports
Our overall project has two main inputs, one being the clock to synchronize our different components throughout the entire system and the other being the rows value which is being read off from the 16-button keypad. Our outputs to the overall system are the segments for the seven segment display, the anode driver, and the decimal point. 

#### 1.3 Description Of Components
We have several different components in our overall system: clock generator, button interface, button mapping, calculator arithmetic logic, binary to BCD converter, digit selection, and seven segment driver. The clock generator is responsible for creating our system clock of 1 MHz. Our button interface decodes what button was pressed based on the combination of rows and columns from the 16 button keypad. We combined a FSM and datapath into one module that is responsible for the actual arithmetic calculation of the inputs. We pass the value received from our calculator arithmetic module to a binary to BCD converter such that it can be properly displayed. We included a digit selection module which allows for a rolling operation if we have a number that is more than 4 digits that needs to be displayed. Lastly, we have our external interface, the seven segment display. 

### 2. Technical Description 
#### 2.1 Clock Generator
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/clock_generator.vhd)*

The clock generator is one of the reusable modules provided to us at the start of the project. This module inputs an external clock and outputs a slower clock - system clock - to run the different processes off of.

#### 2.2 16-button Interface 
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/16button_KYPD_interface.vhd)*

**Port Definition**

The 16-button keypad interface unit links the calculator logic to the input source. It outputs a column value to the calculator every and takes in the row output from the keypad. It turns on one column every millisecond and polls the row output from the keypad checking if the user has pressed a button. This process is clocked using the system clock.

**RTL Design**

The keypad interface uses a 12-bit counter (0-4000). The first column is turned on after 1ms (equivalent to count of 1000) and the row value is polled after 8 more clock cycles and the row register for the first column updated. This is done for each of the columns with the same pattern i.e. at 2ms, the second column goes on while the rest off and 8 clock cycles later, each row register subsequently updated, and so on. This is then loaded into only the row register related to the column that is high at the time of press. A button press is detected if the incoming row_port value is not equal to`1111`. The 4 row register values are then concatenated into a 16-bit signal used to generate a monopulse control bit. To ensure that the `btnPress` only goes high for one clock cycle, the `DecodeOut` value and `btnPress` outputs are updated only when `decodeout_mp` is high and `btnPress` reset to low if `decodeout_mp` is low. `DecodeOut` and `btnPress` are wired as inputs into the main arithmetic unit.

**Memory Allocation**

The `DecodeOut` values are assigned to according to the table below similar to what the keypad, based on a given column and row:

|          | col0 | col1 | col2 | col3 |
| ----     | ---- | ---- | ---- | ---- |
| **row0** |*0001*|*0010*|*0011*|*1010*|
| **row1** |*0100*|*0101*|*0110*|*1011*|
| **row2** |*0111*|*1000*|*1001*|*1100*|
| **row3** |*0000*|*1111*|*1110*|*1101*|

*Fig. Keypad-buttons to binary value map.*

#### 2.3 Calculator Arithmetic
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/arithmetic_logic_unit.vhd)*

**Port Definition**

This component takes in inputs from the 16-button interface to perform arithmetic operations. It takes in our system clock of 1MHz, the value of the button that was pressed, and a monopulse signal indicating that a button was pressed. One of the outputs of this component is a 20-bit number which will hold the value of the first operand, the second operand, or the result depending on what state it is in. It similarly produces a control signal indicating to the `BinarytoBCD` converter that a new number is ready to be converted and displayed. We also included an overflow signal that indicates if the result has exceeded the maximum register size such that users can be alerted that their operation was too big.

**RTL Diagram**

This contains synchronous processes because of the registers and counters used. There are two counters that keep track of how many digits have been inputted for each of the two operands to ensure that users cannot input more than three terms for each operand. There are several registers used to keep hold the value of each operand the corresponding result. We included an operation register to hold what was the most recent operation which was pressed, thus once we reach the result state in the FSM the correct result will be calculated depending on if the addition, subtraction, or multiplication button was pressed. For our asynchronous processes we have comparators to determine what type of button was pressed - number, operation, clear, or equal. These comparators assert control signals that are used to transition within the FSM and to ensure that the `term1` and `term2` registers only have numbers loaded in.

**Finite State Machine**

We have several states for our implementation of the FSM. We initialize our FSM in the `Idle` state where all of the clear signals are asserted. The system transitions out of the Idle state only when a button has been pressed where we will transition into the `LoadTerm1` state. The system will remain in this state until an operation button has been pressed where it will move to `LoadTerm2`. Once in the `LoadTerm2` state, if the equal button has been pressed then we will enter the `Result` state to calculate the result for the desired operation and the two operands. In the `Result` state if it receives another operation button press we begin a sequential operation where we make the result our new term1 and wait for the user to input a number for `term2`. This is indicated by the FSM where we transition into an intermediate clear state that will reset `term2` and its corresponding `digitCounter`. From there the transition leads to the `saveResult` state automatically where a `saveResult` control signal is asserted which equates `term1` to result. From there there is another automatic transition into `LoadTerm2` to await for the user to input the value for the second operand. Note that within the FSM, enable signals are asserted to allow for the registers to be updated and that the reset button will reset the FSM to the Idle state no matter where we are in the process.

#### 2.4 Binary to BCD Converter
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/binary_BCD_converter.vhd)*

**Port Definition**

We implemented the [Double-Dabble algorithm](https://en.wikipedia.org/wiki/Double_dabble) to convert numbers from binary to binary-coded decimal numbers for display on the seven-segment display. Inspired by online sources, we implemented it using a 5-state FSM–namely `IDLE`, `LOAD`, `SHIFT`, `CHECK`, `sDONE` (&  `others`) and a datapath consisting of a 0-20 shift counter, 24-bit register, 44-bit shift register, and adders. 

**RTL Diagram**

Once `load_en` goes high (`LOAD` state), the incoming 20-bit number is concatenated with 24-bits of zeros into a 44-bit number to hold both the `displayPort` and the expected 6-digit BCD value in binary(6x4 bits). When `shift_en` is asserted(`SHIFT` state), the shift counter is initiated and the main part of the double dable begins with a left shift. After every shift, we check for any digits with a value greater than 4 and if this is the case, then those digits are incremented by 3 ensuring that none of the 4-bit digits have a value greater than 9 in the long run. This goes on for 20 shifts meaning that the 20-bit binary input has been successfully converted into its BCD representation. Each of the 6 digits is sent out as inputs to the `DIG_SELECT` unit for customized display on the seven-seg. 

**Finite State Machine**

In the `IDLE` state, the `reg_clr` is set, clearing the shift counter. Upon receiving a high `newNumReady` signal, state goes into the `LOAD` state where `load_en` is set, then the `SHIFT` state where `shift_en` goes high to enable the shift counter to begin, before going into the `CHECK` state where `check_en` is asserted to check if any of the digit registers have an integer value equal to 5 or more. If this is the case, as mentioned in the RTL/Datapath description above, the 3 is added to the digit. If the `shift_done` signal is still low (less than 20 bits shifted), then we move back to the `SHIFT` state and keep switching back and forth until `shift_done` is high and we move into the `sDONE` state. Here, update_en is set allowing for the BCD register value to be updated before cycling back to the `IDLE` state.

#### 2.5 4-Digit Selection (Rolling display)
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/4digit_selector.vhd)*

**Port Definition**

The digit selection component as mentioned above takes in the 6 digits from the Binary to BCD Converter and selects which 4 of them will actually be displayed at a given time on the seven segment display. This is shown via the port map where 6 digits are inputted and only 4 are outputted to the seven segment driver.

**RTL Diagram**

This component only relies on a counter which allows for the 1 MHz clock to be reduced down to .25Hz clock - 1 cycle every 4 seconds. There is no clear or enable signal since we always want to be displaying four digits on the seven segment display. We included several control signals that will identify if the number that needs to be displayed has 6 digits, 5 digits, or 4 digits and less that are outputs of comparators. If the most significant digit is greater than 0 this indicates that we have a number that requires six digits and likewise for five and four. These control signals are used to control the transitions within the FSM as described below. The reason we wanted a slow clock (.25Hz) is so that the display is not changing too fast and such that users would be unable to identify what their six digit number is.

**Finite State Machine**

The finite state machine for this module only contains three different states. Its' default state is `sDisplay4to0` which will output the four least significant digits to be displayed. If a five or six digit number is entered then the control signal will be asserted that moves from the default state to `sDisplay6to2` or `sDisplayto5to1`. Note that within the FSM the transitions only occur when the clock has counted enough to obtain our desired frequency. If we were to enter a six digit number it would start in `Display6to2` then move to `Display5to1` when enough time has elapsed and then back to `Display4to0` where it would see that we still have a six digit number and continue to roll the numbers on the display.

#### 2.6 Seven-Segment Display
>*:link: [Go to code](https://github.com/sumaJonathan/Electronics_Project_24S/blob/main/7seg_display.vhd)*

**Port Definition**

The Seven Segment module is also another resource provided to us that we used for interfacing. It takes in four 4 digit numbers for displaying and a decimal set port. Utilizing the inputs given it will determine which segments should be asserted to display the numbers properly. It contains a decimal point that can be used for any purpose, for us we used it as an indication that we had an overflow error. It also outputs anodes that are used internally within the system.

