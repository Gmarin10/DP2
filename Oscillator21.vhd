----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:04:31 02/19/2018 
-- Design Name: 
-- Module Name:    Oscillator21 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Oscillator21 is
Port ( 
	CLK: in  STD_LOGIC;
	newCLK: out STD_LOGIC
);
end Oscillator21;

architecture Behavioral of Oscillator21 is
signal slowCLK: std_logic:='0';
signal i_cnt: std_logic_vector(23 downto 0):=x"0000000";

begin
-----Creating a slowCLK of 21.477Hz using the board's 100MHz clock----
process(CLK)
begin

if (rising_edge(CLK)) then
	if (i_cnt=x"2385EA")then --Hex(2385EA)=Dec(2328042)
		slowCLK<=not slowCLK; --slowCLK toggles once after we see 100000 rising edges of CLK. 2 toggles is one period.
		i_cnt<=x"00000";
	else
		i_cnt<=i_cnt+'1';
	end if;
end if;

end process;



end Behavioral;

