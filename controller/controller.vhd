
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--cpu sends data latch signal, instructing state of all the buttons to be latched. 
--clock signal is high until data latch pulse falls
--when the data latch pulse falls, 16 clock pulses are sent by the CPU
-- 16 clock pulses are sent as there are 12 buttons and 2^4=16
--each button corresponds to a clock pulse. the button layout order is shown below:

--B: sw<0>
--Y: sw<1>
--Select: sw<2>
--Start: btnc
--up: btnu
--down: btnd 
--left: btn1 
--right: btnr 
--a:sw<3>
--x:sw<4>
--l:sw<5>
--r:sw<6>

--clock pulses 13-16 are left as high, as there are no more buttons

-- 
entity controller is
port(
	clk: in std_logic;
	snes_latch: in std_logic;
	snes_data: out std_logic);
end controller;

architecture Behavioral of controller is

Type state_type is (snes_idle, snes_state1, snes_state2,snes_state3);

--signal declaration
signal state: state_type;
signal data: std_logic;
--buttons vector used to record pressed button data
signal buttons: std_logic_vector(15 downto 0):= "0000000000001111";
signal count: std_logic_vector(3 downto 0);
signal finish_flag: std_logic;


begin


process(clk)
begin
	
--clock counter is implemented to keep track of all 16 data clock pulses
	if rising_edge(clk) then
		if(count = "1111") then 
			count <= "0000";
		else
		count <= count + '1';
	end if;
	end if;
	
	
end process;		

-- fsm
process(clk,snes_latch)
begin
	
	case state is 
			
		--in this state there is 12us delay, and state moves to state 1
		when snes_idle =>
			if(snes_latch' event and snes_latch = '1') then	
				state <= snes_state1;
				end if;
		-- each of the 16 data clock pulses are split
		--in first half, reading if button is pressed.
		--in second half, CPU samples this data, which is shifted to a register in the CPU
		when snes_state1 =>
			if falling_edge(clk) then 
			if(count > "0000" and count < "10001") then 
				state <= snes_state2;
				end if;
				end if;
		--finish flag indicates there have been 16 clock pulses and all the buttons
		--have been checked
		when snes_state2 => 
			if(finish_flag = '1') then 
				state <= snes_state3;
			elsif rising_edge(clk) then 
				if(count > "0000" and count < "10001") then 
					state <= snes_state1;
					end if;
			end if;
		when snes_state3 =>
			state <= snes_idle;
		end case;
		end process;
		
		


process(clk,snes_latch)
begin
		--reset buttons vector and finish flag
		if(state = snes_idle) then 
			finish_flag <='0';
			buttons <= "0000000000001111";
		
		--if certain button or switch is used, its corresponding bit is set to high and 
		--that bit value is assigned to the data variable sampled by the CPU on every falling edge
		elsif(state = snes_state1) then
			if(sw(0) ='1' and count = "0001") then 
				buttons(0) <= '1';
				data <= buttons(0);
			elsif(sw(1) ='1' and count = "0010") then 
				buttons(1) <= '1';
				data <= buttons(1);
			elsif(sw(2) ='1' and count = "0011") then 
				buttons(2) <= '1';
				data <= buttons(2);
			elsif(btnc ='1' and count = "0100") then 
				buttons(3) <= '1';
				data <= buttons(3);
			elsif(btnu ='1' and count = "0101") then 
				buttons(4) <= '1';
				data <= buttons(4);
			elsif(btnd ='1' and count = "0110") then
				buttons(5) <= '1';
				data <= buttons(5);
			elsif(btn1 ='1' and count = "0111") then 
				buttons(6) <= '1';
				data <= buttons(6);
			elsif(btnr ='1' and count = "1000") then 
				buttons(7) <= '1';
				data <= buttons(7);
			elsif(sw(3) ='1' and count = "1001") then 
				buttons(8) <= '1';
				data <= buttons(8);
			elsif(sw(4) ='1' and count = "1010") then 
				buttons(9) <= '1';
				data <= buttons(9);
			elsif(sw(5) ='1' and count = "1011") then  
				buttons(10) <= '1';
				data <= buttons(10);
			elsif(sw(6) ='1' and count = "1111") then  
				buttons(11) <= '1';
				data <= buttons(11);
				end if;
			
			--end if;
			--CPU samples data for corresponding button or switch 
	      elsif(state = snes_state2) then 
			   finish_flag <= '1';
				snes_data <= data;
			end if;
			
end process;
end Behavioral;




