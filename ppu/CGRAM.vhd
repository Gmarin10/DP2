----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:19:10 03/02/2018 
-- Design Name: 
-- Module Name:    ppu - Behavioral 
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
USE IEEE.STD_LOGIC_UNSIGNED.ALL; --use CONV_INTEGER
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CGRAM is
PORT(
--INPUTS
CLK : in STD_LOGIC;
CG_ADD_IN : in STD_LOGIC_VECTOR(13 downto 0);
CG_DATA_IN : in STD_LOGIC_VECTOR(13 downto 0);
CGRAMW : in STD_LOGIC;

---OUTPUTS
CG_ADD_OUT : out STD_LOGIC_VECTOR(13 downto 0);
CG_DATA_OUT : out STD_LOGIC_VECTOR(7 downto 0)
);
end CGRAM;

architecture Behavioral of CGRAM is

type ram is array (0 to 256) of std_logic_vector (7 downto 0);
signal CG_RAM : ram:= (others => (others => '0'));
begin

PROCESS (CG_ADD_IN, CG_ADD_OUT,CGRAMW) begin
	if(CGRAMW = '0') then 
		CG_DATA_OUT <= ram(CONV_INTEGER(CG_ADD_IN));
	elsif(CGRAMW = '1') then
		ram(CONV_INTEGER(CG_ADD_IN)) <= CG_DATA_IN;
	end if;
end process;
end Behavioral;

end Behavioral;