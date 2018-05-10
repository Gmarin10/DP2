
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:09:52 03/30/2018 
-- Design Name: 
-- Module Name:    cartridge - Behavioral 
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
--ROM based upon code given from: http://people.sabanciuniv.edu/erkays/el310/MemoryModels.pdf
----------------------------------------------------------------------------------
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

entity cartridge is
port(
    --MEMORY RELATED
    AB : IN STD_LOGIC_VECTOR(19 downto 0); -- ADDRESS BUS A
    DB : OUT STD_LOGIC_VECTOR(7 downto 0); --DATA BUS
	 CLK: IN STD_LOGIC
);
end cartridge;

architecture Behavioral of cartridge is

component rom1 is 
PORT(
	ENA            : IN STD_LOGIC;  --opt port
	ADDRA          : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
	DOUTA          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
   CLKA       : IN STD_LOGIC
);
end component;

component rom2 is 
PORT(
	ENA            : IN STD_LOGIC;  --opt port
	ADDRA          : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
	DOUTA          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
   CLKA       : IN STD_LOGIC
);
end component;

begin
	romA : rom1 PORT MAP(en_A,add,out_A,clk);
	romB : rom2 PORT MAP(en_B,add,out_B,clk); 
	SIGNAL en_A: std_logic;
	SIGNAL en_B: std_logic; 
	SIGNAL add: STD_LOGIC_VECTOR(18 DOWNTO 0);
	
	en_A = AB(19);
	en_B = not(AB(19));
	add = AB(18 downto 0);
	
	process(add) begin
		if(en_A = '1') then DB <= out_B; else
		DB <= out_A; end if;
	end process;
	
end Behavioral;
