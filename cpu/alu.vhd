----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:58:42 03/08/2018 
-- Design Name: 
-- Module Name:    alu - Behavioral 
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
-- ALU CODE REVISED FROM: http://www.fpga4student.com/2017/06/vhdl-code-for-arithmetic-logic-unit-alu.html

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.NUMERIC_STD.all;
-----------------------------------------------
---------- ALU 16-bit VHDL ---------------------
-----------------------------------------------
entity alu is
Port (
--Original Inputs
A : in  STD_LOGIC_VECTOR(15 downto 0);  -- 2 inputs 16-bit
B : in  STD_LOGIC_VECTOR(15 downto 0);  -- 2 inputs 16-bit
ALU_Sel : in  STD_LOGIC_VECTOR(3 downto 0);  -- 1 input 4-bit for selecting function
ALU_Out : out  STD_LOGIC_VECTOR(15 downto 0); -- 1 output 16-bit 

--FLAGS
--Input
c_fi : IN STD_LOGIC; --Carry Flag
z_fi : IN STD_LOGIC; --Zero Flag
n_fi : IN STD_LOGIC; --Negative Flag
v_fi : IN STD_LOGIC; --Overflow Flag

--Output
c_fo : IN STD_LOGIC; --Carry Flag
z_fo : IN STD_LOGIC; --Zero Flag
n_fo : IN STD_LOGIC; --Negative Flag
v_fo : IN STD_LOGIC; --Overflow Flag 
);
end alu; 
architecture Behavioral of alu is

signal ALU_Result : std_logic_vector (15 downto 0);
signal tmp : std_logic_vector (16 downto 0);

--Flags
signal c_f :  STD_LOGIC; --Carry Flag
signal z_f :  STD_LOGIC; --Zero Flag
signal n_f :  STD_LOGIC; --Negative Flag
signal v_f :  STD_LOGIC; --Overflow Flag


begin
c_f <= c_fi;
z_f <= z_fi;
n_f <= n_fi;
v_f <= v_fi;

c_fo <= c_f;
z_fo <= z_f;
n_fo <= n_f;
v_fo <= v_f;



PROCESS(A,B,ALU_Sel) begin
  case(ALU_Sel) is
  
  when "0000" => -- Addition w/ carry
		ALU_Result <= A + B + c_f;
		tmp <= A + B + c_f;
		c_f <= tmp(16);
		v_f <= tmp(16);
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
  
  when "0001" => -- And
		ALU_Result <= A and B; 
		tmp <= A + B + c_f;
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;

  when "0010" => -- Shift Left
		ALU_Result <= std_logic_vector(unsigned(A) sll 1);
		tmp <= std_logic_vector(unsigned(A) sll 1);
		c_f <= tmp(16);
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
  
  when "0011" => -- BIT
		ALU_Result <= A and B;
  
  when "0100" => --CMP
		ALU_Result <= A - B;
		tmp <= A- B;
		c_f <= tmp(16);
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;

  when "0101" => --DEC
		ALU_Result <= A - '1';		
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
	when "0110" => --EOR
		ALU_Result <= A xor B;		
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
	when "0111" => --INC
		ALU_Result <= A + '1';		
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
	when "1000" => --LDA
		ALU_Result <= A;		
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
	when "1001" => --ORA
		ALU_Result <= A or B ;		
		n_f <= ALU_Result(15);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
	when "1010" => -- Rotate right
		ALU_Result <= std_logic_vector(unsigned(A) ror 1);
		tmp <= std_logic_vector(unsigned(A) ror 1);
		n_f <= '0';
		c_f <= tmp(16);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
		
  when "1011" => --SUB
		ALU_Result <= A - B - not(c_f); 
		tmp <= std_logic_vector(unsigned(A) ror 1);
		n_f <= '0';
		c_f <= tmp(16);
		if(ALU_Result = x"0000") then z_f <= '1'; end if;
		
  end case;
 end process;
 
 ALU_Out <= ALU_Result; 
end Behavioral;