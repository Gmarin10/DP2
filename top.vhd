----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:24:44 04/14/2018 
-- Design Name: 
-- Module Name:    top - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
port(
res_1 : in STD_LOGIC;
CLK : in STD_LOGIC;
Datao: out STD_LOGIC_VECTOR(7 downto 0)
);
end top;

architecture Behavioral of top is

component cpu is
PORT(
RESET_1 : in STD_LOGIC; 
clk : in STD_LOGIC;
AB : out STD_LOGIC_VECTOR(23 downto 0); --Address Bus 
DB : IN STD_LOGIC_VECTOR(7 downto 0)
);
end component;



--SIGNAL en_a : STD_LOGIC;
SIGNAL output: STD_LOGIC_VECTOR(7 downto 0);
SIGNAL add : STD_LOGIC_VECTOR(18 DOWNTO 0);
SIGNAL en_a : STD_LOGIC;


component cartridge
PORT(
	AB : IN STD_LOGIC_VECTOR(23 downto 0); -- ADDRESS BUS A
	DB : OUT STD_LOGIC_VECTOR(7 downto 0) --DATA BUS
);
end component;

SIGNAL address : STD_LOGIC_VECTOR(23 downto 0);
SIGNAL data : STD_LOGIC_VECTOR(7 downto 0);

begin
--romA : rom1 PORT MAP(en_A,add,output,clk100MHz);
--romB : rom2 PORT MAP(en_A,add,output,clk_100MHz);
ROM : cartridge PORT MAP(address,data);
COMP : cpu PORT MAP(res_1,clk,address,data);
datao <= data;
end Behavioral;

