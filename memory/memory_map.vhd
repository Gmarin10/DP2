----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:50:43 03/25/2018 
-- Design Name: 
-- Module Name:    cpu_memory_direct - Behavioral 
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


--LoROM Mapping

entity memory_map is
port(
--INPUTS
ADDBUS : IN STD_LOGIC_VECTOR(23 downto 0); --Address Bus
CART_1 : IN STD_LOGIC; --Does it need to access the cartridge
WRAM_1 : IN STD_LOGIC; --Does it need to access the RAM

--OUTPUTS
AB : OUT STD_LOGIC_VECTOR(23 downto 0); -- A-Bus
PA : OUT STD_LOGIC_VECTOR(7 downto 0) -- B-Bus (No relation to the bank signal)
);
end memory_map;

architecture Behavioral of memory_map is

SIGNAL bank : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL offset : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL internal : STD_LOGIC;

begin
bank <= ADDBUS(23 downto 17);
process(ADDBUS) begin
	--Mirrored Sections (Add Internal registers)
	if((bank >= x"00" and bank <= x"3F") or (bank >= x"80" and bank <= x"BF")) then
		if(offset >= x"0000" and offset <= x"1FFF") then
			AB <= x"7E" & offset;
		elsif ((offset >= x"2000" and offset <= x"20FF") or (offset >= x"2200" and offset <= x"3FFF") or (offset >= x"4400" and offset <= x"7FFF")) then --Uunused
			AB <= bank & offset;
		elsif (offset >= x"2100" and offset <= x"21FF") then 
			PA <= offset(7 downto 0);
		end if;
	end if;	
	
	
	--CARTRDIGE mapping	
	if((bank >= x"00" and bank <= x"3F") or (bank >= x"40" and bank <= x"6F") or (bank >= x"70" and bank <= x"7D")) then
		if(offset >= x"8000" and offset <= x"FFFF") then
			bank(7) <= '0';
			offset(15) <= '0';
			AB <= bank & offset;
		--RAM
		elsif((offset >= x"0000" and offset <= x"7FFF") and (bank >= x"70" and bank <= x"7D")) then			
			AB <= bank & offset;
		end if;
	end if;
	
end process; 

end Behavioral;

-- LOROM DOCUMENTATION: https://www.cs.umb.edu/~bazz/snes/cartridges/lorom.html#memory-map

--MEMORY MAP TAKEN FROM: https://wiki.superfamicom.org/memory-mapping
--  Banks  |  Addresses  | Speed | Mapping
-----------+-------------+-------+---------
-- $00-$3F | $0000-$1FFF | Slow  | Address Bus A + /WRAM (mirror $7E:0000-$1FFF)
--         | $2000-$20FF | Fast  | Address Bus A
--         | $2100-$21FF | Fast  | Address Bus B
--         | $2200-$3FFF | Fast  | Address Bus A
--         | $4000-$41FF | XSlow | Internal CPU registers (see Note 1 below)
--         | $4200-$43FF | Fast  | Internal CPU registers (see Note 1 below)
--         | $4400-$5FFF | Fast  | Address Bus A
--         | $6000-$7FFF | Slow  | Address Bus A
--         | $8000-$FFFF | Slow  | Address Bus A + /CART
-----------+-------------+-------+---------
-- $40-$7D | $0000-$FFFF | Slow  | Address Bus A + /CART
-----------+-------------+-------+---------
-- $7E-$7F | $0000-$FFFF | Slow  | Address Bus A + /WRAM
-----------+-------------+-------+---------
-- $80-$BF | $0000-$1FFF | Slow  | Address Bus A + /WRAM (mirror $7E:0000-$1FFF)
--         | $2000-$20FF | Fast  | Address Bus A
--         | $2100-$21FF | Fast  | Address Bus B
--         | $2200-$3FFF | Fast  | Address Bus A
--         | $4000-$41FF | XSlow | Internal CPU registers (see Note 1 below)
--         | $4200-$43FF | Fast  | Internal CPU registers (see Note 1 below)
--         | $4400-$5FFF | Fast  | Address Bus A
--         | $6000-$7FFF | Slow  | Address Bus A
--         | $8000-$FFFF | Note2 | Address Bus A + /CART
-----------+-------------+-------+---------
-- $C0-$FF | $0000-$FFFF | Note2 | Address Bus A + /CART

