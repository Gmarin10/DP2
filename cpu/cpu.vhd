----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:19:10 03/02/2018 
-- Design Name: 
-- Module Name:    cpu - Behavioral 
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

entity cpu is
PORT(
--INPUTS
--ABORTB : in STD_LOGIC;
--IRQB : in STD_LOGIC;
--NMIB : in STD_LOGIC;
--RESB : in STD_LOGIC;
--PHI2 : in STD_LOGIC;
--BE : in STD_LOGIC;
RESET_1 : in STD_LOGIC; 
clk : in STD_LOGIC;

--
----OUTPUTS
--RWB : out STD_LOGIC;
--VPA : out STD_LOGIC;
--VDA : out STD_LOGIC;
--MLB : out STD_LOGIC;
--VPB : out STD_LOGIC;
--E : out STD_LOGIC;
--MX : out STD_LOGIC;
AB : out STD_LOGIC_VECTOR(23 downto 0); --Address Bus 
--RD_1 : out STD_LOGIC;
--WR_1 : out STD_LOGIC; 


--RDY : INOUT STD_LOGIC;
DB : IN STD_LOGIC_VECTOR(7 downto 0)
DBO : OUT STD_LOGIC_VECTOR(7 downto 0)
);
end cpu;

architecture Behavioral of cpu is

--ALU
component ALU is 
PORT(
A : in  STD_LOGIC_VECTOR(15 downto 0);
B : in  STD_LOGIC_VECTOR(15 downto 0);  -- 2 inputs 16-bit
ALU_Sel : in  STD_LOGIC_VECTOR(3 downto 0);  -- 1 input 4-bit for selecting function
ALU_Out : out  STD_LOGIC_VECTOR(15 downto 0); -- 1 output 16-bit

--FLAGS
c_fi : IN STD_LOGIC; --Carry Flag
c_fo : OUT STD_LOGIC; --Carry Flag
z_fo : OUT STD_LOGIC; --Zero Flag
v_fo : OUT STD_LOGIC; --Overflow Flag
n_fo : OUT STD_LOGIC --Negative Flag
);
end component;

-- ALU REGISTERS
SIGNAL alua_r : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL alub_r : STD_LOGIC_VECTOR(15 downto 0);
SIGNAL alusel_r : STD_LOGIC_VECTOR(3 downto 0);
SIGNAL aluout_r : STD_LOGIC_VECTOR(15 downto 0);


--INTERNAL REGISTERS
SIGNAL ix_r : STD_LOGIC_VECTOR(15 downto 0); --INDEX X
SIGNAL iy_r : STD_LOGIC_VECTOR(15 downto 0); -- INDEX Y
SIGNAL stk_r : STD_LOGIC_VECTOR(15 downto 0); -- STACK POINTER
SIGNAL acc_r : STD_LOGIC_VECTOR(15 downto 0); --ACCUMULATOR 
SIGNAL pc_r : STD_LOGIC_VECTOR(15 downto 0); --PROGRAM COUNTER
SIGNAL dir_r : STD_LOGIC_VECTOR(15 downto 0); --Direct
SIGNAL pb_r : STD_LOGIC_VECTOR(7 downto 0); --PROGRAM BANK
SIGNAL dbk_r : STD_LOGIC_VECTOR(7 downto 0); --DATA BANK
SIGNAL dl_r : STD_LOGIC_VECTOR(15 downto 0); --DATA LATCH
SIGNAL ir_r : STD_LOGIC_VECTOR(7 downto 0); --INSTRUCTION REGISTER
SIGNAL prs_r : STD_LOGIC_VECTOR(7 downto 0); --PROCESSOR STATUS
SIGNAL abl_r : STD_LOGIC_VECTOR(7 downto 0); --Address Bus Buffer Low
SIGNAL abh_r : STD_LOGIC_VECTOR(7 downto 0); --Address Bus Buffer High
SIGNAL abb_r : STD_LOGIC_VECTOR(7 downto 0); --Address Buffer (BANK)
SIGNAL db_r : STD_LOGIC_VECTOR(7 downto 0); --Data Bus

--CUSTOM REGISTERS
SIGNAL ab_r : STD_LOGIC_VECTOR(23 downto 0); --Address Bus
SIGNAL dll_r : STD_LOGIC_VECTOR(7 downto 0); --Data Latch Low
SIGNAL dlh_r : STD_LOGIC_VECTOR(7 downto 0); --Data Latch Hich
SIGNAL cpurd_1: STD_LOGIC; --Cpu read
SIGNAL cpuwr_1: STD_LOGIC; --Cpu write

--PROCESSOR STATUS: FLAGS
SIGNAL c_f : STD_LOGIC; --BIT 0, Carry Flag
SIGNAL z_f : STD_LOGIC; --BIT 1, Zero Flag
SIGNAL i_f : STD_LOGIC; --BIT 2, IRQ Disable Flag
SIGNAL d_f : STD_LOGIC; --BIT 3, Decimal Mode Flag
SIGNAL x_f : STD_LOGIC; --BIT 4, Index 8-bit Mode Flag
SIGNAL m_f : STD_LOGIC; --BIT 5, Memory/Accumulator Flag
SIGNAL v_f : STD_LOGIC; --BIT 6, Overflow Flag
SIGNAL n_f : STD_LOGIC; --BIT 7, Negative Flag

--PROCESSOR STATUS: WEIRD FLAGS
SIGNAL e_f : STD_LOGIC; -- Emulation Flag
SIGNAL b_f : STD_LOGIC; -- Break Flag

--FLAG REGISTERS
SIGNAL c_f_r : STD_LOGIC; --BIT 0, Carry Flag
SIGNAL z_f_r : STD_LOGIC; --BIT 1, Zero Flag
SIGNAL v_f_r : STD_LOGIC; --BIT 6, Overflow Flag
SIGNAL n_f_r : STD_LOGIC; --BIT 7, Negative Flag

----BUSES (MIGHT NOT NEED)
--SIGNAL ia_b : STD_LOGIC_VECTOR(15 downto 0); --Internal Address Bus
--SIGNAL is_b : STD_LOGIC_VECTOR(15 downto 0); --Internal Special Bus
--SIGNAL id_b : STD_LOGIC_VECTOR(15 downto 0); --Internal Data Bus
--SIGNAL unk_b : STD_LOGIC_VECTOR(7 downto 0); --Unknown Named Bus

--Time States
TYPE  TIMESTATE IS (RESET,T1,T2,T3,T4,T5,T6,T7,T8,T9);
SIGNAL state : TIMESTATE;

--OPCODE KEY ADDRESING MODES
-- a
-- ac A
-- ax
-- ay
-- al
-- alx
-- ap (a)
-- axp (a,x)
-- d
-- ds
-- dx
-- dy
-- dp (d)
-- db [d]
-- dspy (d,s),y
-- dxp (d,x)
-- dpy (d),y
-- dby [d],y
-- i
-- r
-- rl
-- s
-- xyc
-- num #

TYPE OPCODES IS(
ADC_a, ADC_dx, ADC_ay, ADC_al, ADC_alx, ADC_ap, ADC_d, ADC_ds, ADC_dx, ADC_dp, ADC_db, ADC_dspy, ADC_dxp, ADC_dpy, ADC_dby, ADC_num, 
AND_a, AND_dx, AND_ay, AND_al, AND_alx, AND_d, AND_ds, AND_dx, AND_dp, AND_db, AND_dspy, AND_dxp, AND_dpy, AND_dby, AND_num,
ASL_a, ASL_ac, ASL_dx, ASL_d, ASL_dx,
BCC_r, BCS_r, BEQ_r,
BIT_a, BIT_dx, BIT_d, BIT_dx, BIT_num,
BMI_r, BNE_r,
BPL_r, BRA_r, BRK_s,
BRL_rl, BVC_r, BVS_r,
CLC_i, CLC_d, CLI_i, CLV_i,
CMP_a, CMP_dx, CMP_ay, CMP_al, CMP_alx, CMP_d, CMP_ds, CMP_dx, CMP_dp, CMP_db, CMP_dspy, CMP_dxp, CMP_dpy, CMP_dby, CMP_num,
COP_s,
CPX_a, CPX_d, CPX_num, 
CPY_a, CPY_d, CPY_num,
DEX_i, DEY_i,
EOR_a, EOR_dx, EOR_ay, EOR_al, EOR_alx, EOR_d, EOR_ds, EOR_dx, EOR_dp, EOR_db, EOR_dspy, EOR_dxp, EOR_dpy, EOR_dby, EOR_num,
INC_a, INC_ac, INC_dx, INC_d, INC_dx, INX_i, INY_i,
JMP_a, JMP_al, JMP_ap, JMP_dxp, 
JSL_al, JSR_a, JSR_dxp, JML_ap,
LDA_a, LDA_dx, LDA_ay, LDA_al, LDA_alx, LDA_d, LDA_ds, LDA_dx, LDA_dp, LDA_db, LDA_dspy, LDA_dxp, LDA_dpy, LDA_dby, LDA_num,
LDX_a, LDX_ay, LDX_d, LDX_dy, LDX_num,
LDY_a, LDY_ay, LDY_d, LDY_dx, LDY_num,
LSR_a, LSR_ac, LSR_dx, LSR_d, LSR_dx,
MVN_xyc, MVP_xyc,
NOP_i,
ORA_a, ORA_dx, ORA_ay, ORA_al, ORA_alx, ORA_d, ORA_ds, ORA_dx, ORA_dp, ORA_db, ORA_dspy, ORA_dxp, ORA_dpy, ORA_dby, ORA_num,
PEA_s, PEI_s, PER_s, PHA_s, PHB_s,
PHD_s, PHK_s, PHP_s, PHX_s, PHY_s,
PLA_s, PLB_s, PLD_s, PLP_s, PLX_s, PLY_s,
REP_num,
ROL_a, ROL_ac, ROL_dx, ROL_d, ROL_dx,
ROR_a, ROR_ac, ROR_dx, ROR_d, ROR_dx,
RTI_s, RTL_s, RTS_s,
SBC_a, SBC_dx, SBC_ay, SBC_alx, SBC_d, SBC_ds, SBC_dx, SBC_dp, SBC_db, SBC_dspy, SBC_dxp, SBC_dpy, SBC_dby, SBC_num,
SEC_i, SED_i, SEI_i, SEP_num,
STA_a, STA_dx, STA_al, STA_alx, STA_d, STA_ds, STA_dx, STA_dp, STA_db, STA_dspy, STA_dxp, STA_dpy, STA_dby,
STP_i,
STX_a, STX_d, STX_dy,
STY_a, STY_d, STY_dx,
STZ_a, STZ_dx, STZ_d, STZ_dx,
TAX_i, TAY_i, TCD_i, TCS_i, TDC_i, 
TRB_a, TRB_d, TSB_a, TSB_d,
TSC_ac, TSX_ac, 
TXA_ac, TXS_ac, TXY_ac, 
TYA_ac, TYX_ac,
WAI_ac, WDM_ac,
XBA_ac, XCE_ac
);

SIGNAL opc : OPCODES;

begin

LOGIC : alu PORT MAP(alua_r,alub_r,alusel_r,aluout_r,c_f,c_f_r,z_f_r, v_f_r, n_f_r);


--Assign opc
WITH ir_r SELECT 
opc<=
	ADC_a WHEN x"6D", ADC_dx WHEN x"7D", ADC_ay WHEN x"79", ADC_al WHEN x"6F", ADC_alx WHEN x"7F", ADC_d WHEN x"65", ADC_ds WHEN x"63", ADC_dx WHEN x"75", ADC_dp WHEN x"72", ADC_db WHEN x"67", ADC_dspy WHEN x"73", ADC_dxp WHEN x"61", ADC_dpy WHEN x"71", ADC_dby WHEN x"77", ADC_num WHEN x"69", 
	AND_a WHEN x"2D", AND_dx WHEN x"3D", AND_ay WHEN x"39", AND_al WHEN x"2F", AND_alx WHEN x"3F", AND_d WHEN x"25", AND_ds WHEN x"23", AND_dx WHEN x"35", AND_dp WHEN x"32", AND_db WHEN x"27", AND_dspy WHEN x"33", AND_dxp WHEN x"21", AND_dpy WHEN x"31", AND_dby WHEN x"37", AND_num WHEN x"29",
	ASL_a WHEN x"0E", ASL_ac WHEN x"0A", ASL_dx WHEN x"1E", ASL_d WHEN x"06", ASL_dx WHEN x"16",
	
	BCC_r WHEN x"90", BCS_r WHEN x"B0", BEQ_r WHEN x"F0",
	BIT_a WHEN x"2C", BIT_dx WHEN x"3C", BIT_d WHEN x"24", BIT_dx WHEN x"34", BIT_num WHEN x"89",
   BMI_r WHEN x"30", BNE_r WHEN x"D0",
	BPL_r WHEN x"10", BRA_r WHEN x"80", BRK_s WHEN x"00",
	BRL_rl WHEN x"82", BVC_r WHEN x"50", BVS_r WHEN x"70",

	CLC_i WHEN x"18", CLC_d WHEN x"D8", CLI_i WHEN x"58", CLV_i WHEN x"B8",
	CMP_a WHEN x"CD", CMP_dx WHEN x"DD", CMP_ay WHEN x"D9", CMP_al WHEN x"CF", CMP_alx WHEN x"DF", CMP_d WHEN x"C5", CMP_ds WHEN x"C3", CMP_dx WHEN x"D5", CMP_dp WHEN x"D2", CMP_db WHEN x"C7", CMP_dspy WHEN x"D3", CMP_dxp WHEN x"C1", CMP_dpy WHEN x"D1", CMP_dby WHEN x"D7", CMP_num WHEN x"C9",
	COP_s WHEN x"02",
	CPX_a WHEN x"EC", CPX_d WHEN x"E4", CPX_num WHEN x"E0", 
	CPY_a WHEN x"CC", CPY_d WHEN x"C4", CPY_num WHEN x"C0",

	DEC_a WHEN x"CE", DEC_ac WHEN x"3A", DEC_dx WHEN x"DE", DEC_d WHEN x"C6", DEC_dx WHEN x"D6",  
	DEX_i WHEN x"CA", DEY_i WHEN x"88",

   EOR_a WHEN x"4D", EOR_dx WHEN x"5D", EOR_ay WHEN x"59", EOR_al WHEN x"4F", EOR_alx WHEN x"5F", EOR_d WHEN x"45", EOR_ds WHEN x"43", EOR_dx WHEN x"55", EOR_dp WHEN x"52", EOR_db WHEN x"47", EOR_dspy WHEN x"53", EOR_dxp WHEN x"41", EOR_dpy WHEN x"51", EOR_dby WHEN x"57", EOR_num WHEN x"49",

	INC_a WHEN x"EE", INC_ac WHEN x"1A", INC_dx WHEN x"FE", INC_d WHEN x"E6", INC_dx WHEN x"F6", INX_i WHEN x"E8", INY_i WHEN x"C8",

   JMP_a WHEN x"4C", JMP_al WHEN x"5C", JMP_ap WHEN x"6C", JMP_dxp WHEN x"7C", 
   JSL_al WHEN x"22", JSR_a WHEN x"20", JSR_dxp WHEN x"FC", JML_ap WHEN x"DC",
	
	LDA_a WHEN x"AD", LDA_dx WHEN x"BD", LDA_ay WHEN x"B9", LDA_al WHEN x"AF", LDA_alx WHEN x"BF", LDA_d WHEN x"A5", LDA_ds WHEN x"A3", LDA_dx WHEN x"B5", LDA_dp WHEN x"B2", LDA_db WHEN x"A7", LDA_dspy WHEN x"B3", LDA_dxp WHEN x"A1", LDA_dpy WHEN x"B1", LDA_dby WHEN x"B7", LDA_num WHEN x"A9",
	LDX_a WHEN x"AE", LDX_ay WHEN x"BE", LDX_d WHEN x"A6", LDX_dy WHEN x"B6", LDX_num WHEN x"A2",
	LDY_a WHEN x"AC", LDY_ay WHEN x"BC", LDY_d WHEN x"A4", LDY_dx WHEN x"B4", LDY_num WHEN x"A0",
	LSR_a WHEN x"4E", LSR_ac WHEN x"4A", LSR_dx WHEN x"5E", LSR_d WHEN x"46", LSR_dx WHEN x"56",
	
   MVN_xyc WHEN x"54", MVP_xyc WHEN x"44",

   NOP_i WHEN x"EA",

   ORA_a WHEN x"0D", ORA_dx WHEN x"1D", ORA_ay WHEN x"19", ORA_al WHEN x"0F", ORA_alx WHEN x"1F", ORA_d WHEN x"05", ORA_ds WHEN x"03", ORA_dx WHEN x"15", ORA_dp WHEN x"12", ORA_db WHEN x"07", ORA_dspy WHEN x"13", ORA_dxp WHEN x"01", ORA_dpy WHEN x"11", ORA_dby WHEN x"17", ORA_num WHEN x"09",

   PEA_s WHEN x"F4", PEI_s WHEN x"D4", PER_s WHEN x"62", PHA_s WHEN x"48", PHB_s WHEN x"8B",
   PHD_s WHEN x"0B", PHK_s WHEN x"4B", PHP_s WHEN x"08", PHX_s WHEN x"DA", PHY_s WHEN x"5A",
	PLA_s WHEN x"68", PLB_s WHEN x"AB", PLD_s WHEN x"2B", PLP_s WHEN x"28", PLX_s WHEN x"FA", PLY_s WHEN x"7A",

   REP_num WHEN x"C2",
   ROL_a WHEN x"2E", ROL_ac WHEN x"2A", ROL_dx WHEN x"3E", ROL_d WHEN x"26", ROL_dx WHEN x"36",
   ROR_a WHEN x"6E", ROR_ac WHEN x"6A", ROR_dx WHEN x"7E", ROR_d WHEN x"66", ROR_dx WHEN x"76",
   RTI_s WHEN x"40", RTL_s WHEN x"6B", RTS_s WHEN x"60",
	
	SBC_a WHEN x"ED", SBC_dx WHEN x"FD", SBC_ay WHEN x"F9", SBC_alx WHEN x"FF", SBC_d WHEN x"E5", SBC_ds WHEN x"E3", SBC_dx WHEN x"F5", SBC_dp WHEN x"F2", SBC_db WHEN x"E7", SBC_dspy WHEN x"F3", SBC_dxp WHEN x"E1", SBC_dpy WHEN x"F1", SBC_dby WHEN x"F7", SBC_num WHEN x"E9",
	SEC_i WHEN x"38", SED_i WHEN x"F8", SEI_i WHEN x"78", SEP_num WHEN x"E2",
	STA_a WHEN x"8D", STA_dx WHEN x"9D", STA_al WHEN x"8F", STA_alx WHEN x"9F", STA_d WHEN x"85", STA_ds WHEN x"83", STA_dx WHEN x"95", STA_dp WHEN x"92", STA_db WHEN x"87", STA_dspy WHEN x"93", STA_dxp WHEN x"81", STA_dpy WHEN x"91", STA_dby WHEN x"97",
	STP_i WHEN x"DB",
	STX_a WHEN x"8E", STX_d WHEN x"86", STX_dy WHEN x"96",
	STY_a WHEN x"8C", STY_d WHEN x"84", STY_dx WHEN x"94",
	STZ_a WHEN x"9C", STZ_dx WHEN x"9E", STZ_d WHEN x"64", STZ_dx WHEN x"74",

	TAX_i WHEN x"AA", TAY_i WHEN x"A8", TCD_i WHEN x"5B", TCS_i WHEN x"1B", TDC_i WHEN x"7B", 
	TRB_a WHEN x"1C", TRB_d WHEN x"14", TSB_a WHEN x"0C", TSB_d WHEN x"04",
	TSC_ac WHEN x"3B", TSX_ac WHEN x"BA", 
	TXA_ac WHEN x"8A", TXS_ac WHEN x"9A", TXY_ac WHEN x"9B", 
	TYA_ac WHEN x"98", TYX_ac WHEN x"BB",
	
   WAI_ac WHEN x"CB", WDM_ac WHEN x"42",

   XBA_ac WHEN x"EB", XCE_ac WHEN x"FB",
   XCE_ac WHEN OTHERS;

--Output Stuff

	AB <= ab_r;
	db_r <= DB;
	--RD_1 <= cpurd_1;
	--WR_1 <= cpuwr_1;
	
--	process(cpurd_1, cpuwr_1)begin
--		if(cpurd_1 = '0') then db_r <= DB; end if;
--		if(cpuwr_1f = '1') then DBO => db_r; end if;
--		
--	end process;
	--FLAGS

--Flag update
process(c_f_r,z_f_r, v_f_r, n_f_r, state) begin
	CASE state IS
		WHEN RESET=>
			--c_f <= '0';
			z_f <= '0';
			v_f <= '0';
			n_f <= '0';
			i_f <= '0';
			d_f <= '0';
			x_f <= '0';
			m_f <= '0';
			e_f <= '0';
			b_f <= '0';
		WHEN others=>
			--c_f <= c_f_r;
			z_f <= z_f_r;
			v_f <= v_f_r;
			n_f <= n_f_r;
	END CASE;
end process;

--State Diagram/Bus Activity per opcode
process(RESET_1,clk) begin
    if(RESET_1 = '0') then
	    state <= RESET;
    elsif(clk'EVENT and clk='1') then
	    CASE state IS
		WHEN RESET =>
			state <= T1;
        WHEN T1=>
            state <= T2;
		WHEN T2=>
            if((opc = brk_s) or (opc = cop_s))then
                if(e_f = '1')then
                    state <= T4; --22j
                end if;
            elsif(((opc = bcc_r) AND (c_f /= '0'))or
            ((opc = bcs_r) AND (c_f /= '1')) or 
            ((opc = beq_r) AND (z_f /= '1')) or 
            ((opc = bmi_r) AND (n_f /= '0')) or
            ((opc = bne_r) AND (z_f /= '0')) or 
            ((opc = bpl_r) AND (n_f /= '0')) or 
            ((opc = bvc_r) AND (v_f /= '0')) or 
            ((opc = bvs_r) AND (v_f /= '1')))then
                state <= T5; --20
            elsif((opc = ADC_dxp) or 
            (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or 
            (opc = LDA_dxp) or (opc = ORA_dxp) or (opc = SBC_dxp) or 
            (opc = STA_dxp) or (opc = ADC_dp) or (opc = AND_dp) or 
            (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or 
            (opc = ORA_dp) or (opc = SBC_dp) or (opc = STA_dp) or
            (opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or 
            (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
            (opc = SBC_dpy) or (opc = STA_dpy) or (opc = ADC_dby) or 
            (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or 
            (opc = LDA_dby) or (opc = ORA_dby) or (opc = SBC_dby) or 
            (opc = STA_dby) or (opc = ADC_db) or (opc = AND_db) or 
            (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or 
            (opc = ORA_db) or (opc = SBC_db) or (opc = STA_db) or
            (opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or 
            (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or
            (opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or 
            (opc = STA_dx) or (opc = STY_dx) or (opc = STZ_dx) or
            (opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or 
            (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx) or
            (opc = LDX_dy) or (opc = STX_dy) or (opc = pei_s))then
                if(dir_r(7 downto 0) = x"00")then 
                    state <= T4; --11, 12, 13, 14, 15, 16a, 16b, 17, 22e
                end if;
           
            elsif((opc = ADC_d) or (opc = AND_d) or (opc = BIT_d) or 
            (opc = CMP_d) or (opc = CPX_d) or (opc = CPY_d) or
            (opc = EOR_d) or (opc = LDA_d) or (opc = LDX_d) or 
            (opc = LDY_d) or (opc = ORA_d) or (opc = SBC_d) or 
            (opc = STA_d) or (opc = STX_d) or (opc = STY_d) or 
            (opc = STZ_d) or (opc = ASL_d) or (opc =  DEC_d) or (opc = INC_d) or 
            (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
            (opc = TRB_d) or (opc = TSB_d))then
                if((dir_r(7 downto 0) = x"00") AND ((m_f /= '0') or (x_f /= '0')))then
                    state <= T5; --10a, 10b
                end if;
            elsif((opc = asl_ac) or (opc = dec_ac) or 
            (opc = inc_ac) or (opc = lsr_ac) or
            (opc = rol_ac) or (opc = ror_ac) or
            (opc = CLC_i) or (opc = CLD_i) or
            (opc = CLI_i) or (opc = CLV_i) or 
            (opc = DEX_i) or (opc = DEY_i) or
            (opc = INX_i) or (opc = INY_i) or 
            (opc = NOP_i) or (opc = SEC_i) or 
            (opc = SED_i) or (opc = SEI_i) or
            (opc = TAX_i) or (opc = TAY_i) or 
            (opc = TCD_i) or (opc = TCS_i) or 
            (opc = TDC_i) or (opc = TSC_i) or
            (opc = TSX_i) or (opc = TXA_i) or 
            (opc = TXS_i) or (opc = TXY_i) or 
            (opc = TYA_i) or (opc = TYX_i) or
            (opc = XCE_i))then
                state <= T1; --8, 19
			else state <= T3; end if;
		WHEN T3 =>
            if(((opc = bcc_r) AND (e_f /= '1'))or
            ((opc = bcs_r) AND (e_f /= '1')) or 
            ((opc = beq_r) AND (e_f /= '1')) or 
            ((opc = bmi_r) AND (e_f /= '1')) or
            ((opc = bne_r) AND (e_f /= '1')) or 
            ((opc = bpl_r) AND (e_f /= '1')) or 
            ((opc = bvc_r) AND (e_f /= '1')) or 
            ((opc = bvs_r) AND (e_f /= '1')) or
            ((opc = bra_r) AND (e_f /= '1')))then
                state <= T5; --20
            elsif((opc = ADC_a) or (opc = AND_a) or 
            (opc = BIT_a) or (opc = CMP_a) or (opc = CPX_a) or 
            (opc = CPY_a) or (opc = EOR_a) or(opc = LDA_a) or 
            (opc = LDX_a) or (opc =LDY_a) or (opc = ORA_a) or 
            (opc = SBC_a) or (opc = STA_a) or (opc = STX_a) or
            (opc = STY_a) or (opc = STZ_a) or (opc = ASL_a) or 
            (opc = DEC_a) or (opc = INC_a) or 
            (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
            (opc = TRB_a) or (opc = TSB_a) or (opc = ADC_d) or (opc = AND_d) or (opc = BIT_d) or 
            (opc = CMP_d) or (opc = CPX_d) or (opc = CPY_d) or
            (opc = EOR_d) or (opc = LDA_d) or (opc = LDX_d) or 
            (opc = LDY_d) or (opc = ORA_d) or (opc = SBC_d) or 
            (opc = STA_d) or (opc = STX_d) or (opc = STY_d) or 
            (opc = STZ_d) or (opc = ASL_d) or (opc =  DEC_d) or (opc = INC_d) or 
            (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
            (opc = TRB_d) or (opc = TSB_d) or (opc = PLA_s) or (opc = PLB_s) or 
            (opc = PLD_s) or (opc = PLP_s) or (opc = PLX_s) or 
            (opc = PLY_s) or (opc = ADC_ds) or (opc = AND_ds) or 
            (opc = CMP_ds) or (opc = EOR_ds) or (opc = LDA_ds) or 
            (opc = ORA_ds) or (opc = SBC_ds) or (opc = STA_ds))then
                if((m_f /= '0') or (x_f /= '0'))then
                    state <= T5; --1a, 1d, 10a, 10b, 22b, 23
                end if;
            elsif((opc = ADC_dx) or (opc = AND_dx) or
            (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or 
            (opc = LDA_dx) or (opc = LDY_dx) or (opc = ORA_dx) or 
            (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
            (opc = STZ_dx) or (opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or 
            (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
            (opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay) )then
                if(x_f /= '0')then
                    if((m_f /= '0') or (x_f /= '0'))then
                        state <= T6; --6a, 7
                    end if;
                end if;
            elsif(opc = xba_i)then 
                state <= T1; --19b
            else state <= T4; end if;
		WHEN T4 =>
            if((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or 
            (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
            (opc = SBC_al) or (opc = STA_al) or (opc = ADC_alx) or 
            (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or 
            (opc = LDA_alx) or (opc = ORA_alx) or (opc = SBC_alx) or 
            (opc = STA_alx) or (opc = ADC_dx) or (opc = AND_dx) or
            (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or 
            (opc = LDA_dx) or (opc = LDY_dx) or (opc = ORA_dx) or 
            (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
            (opc = STZ_dx) or (opc = ASL_dx) or (opc = DEC_dx) or 
            (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or 
            (opc = ROR_dx) or (opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or 
            (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
            (opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay) or
            (opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or 
            (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or
            (opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or 
            (opc = STA_dx) or (opc = STY_dx) or (opc = STZ_dx) or
            (opc = LDX_dy) or (opc = STX_dy) or (opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or 
            (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
            ) then
                if((m_f /= '0') or (x_f /= '0'))then
                    state <= T6; --4a, 5, 6a, 6b, 7, 16a, 17, 16b
                end if;
            elsif((opc = jmp_a) or (opc = wai_ac))then
                state <= T2; --1b, 19d
            else state <= T5; end if;
		WHEN T5 =>
            if((opc = ADC_a) or (opc = AND_a) or 
            (opc = BIT_a) or (opc = CMP_a) or (opc = CPX_a) or 
            (opc = CPY_a) or (opc = EOR_a) or(opc = LDA_a) or 
            (opc = LDX_a) or (opc =LDY_a) or (opc = ORA_a) or 
            (opc = SBC_a) or (opc = STA_a) or (opc = STX_a) or
            (opc = STY_a) or (opc = STZ_a) or (opc = ADC_d) or (opc = AND_d) or (opc = BIT_d) or 
            (opc = CMP_d) or (opc = CPX_d) or (opc = CPY_d) or
            (opc = EOR_d) or (opc = LDA_d) or (opc = LDX_d) or 
            (opc = LDY_d) or (opc = ORA_d) or (opc = SBC_d) or 
            (opc = STA_d) or (opc = STX_d) or (opc = STY_d) or 
            (opc = STZ_d) or (opc = brl_rl) or (opc = PLA_s) or (opc = PLB_s) or 
            (opc = PLD_s) or (opc = PLP_s) or (opc = PLX_s) or 
            (opc = PLY_s) or (opc = pea_s) or (opc = bcc_r) or
            (opc = bcs_r) or (opc = beq_r) or (opc = bmi_r) or
            (opc = bne_r) or (opc = bpl_r) or (opc = bra_r) or
            (opc = bvc_r) or (opc = bvs_r) or (opc = ADC_ds) or (opc = AND_ds) or 
            (opc = CMP_ds) or (opc = EOR_ds) or (opc = LDA_ds) or 
            (opc = ORA_ds) or (opc = SBC_ds) or (opc = STA_ds))then
                state <= T1; --1a, 10a, 21, 22b, 22d, 20, 23
            elsif((opc = jmp_al))then
                state <= T2; --4b
            elsif((opc = ADC_dp) or (opc = AND_dp) or 
            (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or 
            (opc = ORA_dp) or (opc = SBC_dp) or (opc = STA_dp))then
                if((m_f /= '0') or (x_f /= '0'))then
                    state <= T7; --12
                end if;
            elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or 
            (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
            (opc = SBC_dpy) or (opc = STA_dpy))then
                if(x_f /= '0')then
                    if((m_f /= '0') or (x_f /= '0'))then
                        state <= T8; --13
                    end if;
                end if;
			else state <= T6; end if;
        WHEN T6 =>
            if(opc = rti_s)then
                if(e_f = '1')then
                    state <= T8; --22g
                end if;
            elsif((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or 
            (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
            (opc = SBC_al) or (opc = STA_al) or (opc = ADC_alx) or 
            (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or 
            (opc = LDA_alx) or (opc = ORA_alx) or (opc = SBC_alx) or 
            (opc = STA_alx) or (opc = ADC_dx) or (opc = AND_dx) or
            (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or 
            (opc = LDA_dx) or (opc = LDY_dx) or (opc = ORA_dx) or 
            (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
            (opc = STZ_dx) or (opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or 
            (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
            (opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay) or
            (opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or 
            (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or
            (opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or 
            (opc = STA_dx) or (opc = STY_dx) or (opc = STZ_dx) or
            (opc = LDX_dy) or (opc = STX_dy) or (opc = per_s))then
                state <= T1; --4a, 5, 6a, 7, 16a, 17, 22f
            elsif(opc = jmp_ap)then 
                state <= T2; --3b,
				elsif((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or 
            (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
            (opc = TRB_a) or (opc = TSB_a) or (opc = ASL_d) or (opc =  DEC_d) or (opc = INC_d) or 
            (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
            (opc = TRB_d) or (opc = TSB_d) or (opc = ADC_dxp) or 
            (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or 
            (opc = LDA_dxp) or (opc = ORA_dxp) or (opc = SBC_dxp) or 
            (opc = STA_dxp) or (opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or 
            (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
            (opc = SBC_dpy) or (opc = STA_dpy) or (opc = ADC_dby) or 
            (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or 
            (opc = LDA_dby) or (opc = ORA_dby) or (opc = SBC_dby) or 
            (opc = STA_dby) or (opc = ADC_db) or (opc = AND_db) or 
            (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or 
            (opc = ORA_db) or (opc = SBC_db) or (opc = STA_db) or 
            (opc = ADC_dspy) or (opc = AND_dspy) or 
            (opc =  CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or 
            (opc = ORA_dspy) or (opc = SBC_dspy) or (opc = STA_dspy))then
                if((m_f /= '0') or (x_f /= '0'))then
                    state <= T8; --1d, 10b, 11, 14, 15, 13, 24
                end if;
            else state <= T7; end if;
        WHEN T7 =>
            if((opc = ADC_dp) or (opc = AND_dp) or 
            (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or 
            (opc = ORA_dp) or (opc = SBC_dp) or (opc = STA_dp) or
            (opc = pei_s) or (opc = rts_s) or (opc = rtl_s))then    
                state <= T1; --12, 22e, 22h, 22i
            elsif((opc = jsr_a) or (opc = jmp_dxp) or (opc = jml_ap))then
                state <= T2; --1c, 2a, 3a, 
            elsif((opc = ASL_dx) or (opc = DEC_dx) or 
            (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or 
            (opc = ROR_dx) or (opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or 
            (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx))then
                if((m_f /= '0') or (x_f /= '0'))then
                    state <= T9; --6b, 16b
                end if;
			else state <= T8; end if;
        WHEN T8 =>
            if((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or 
            (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
            (opc = TRB_a) or (opc = TSB_a) or (opc = ASL_d) or (opc =  DEC_d) or (opc = INC_d) or 
            (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
            (opc = TRB_d) or (opc = TSB_d) or (opc = ADC_dxp) or 
            (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or 
            (opc = LDA_dxp) or (opc = ORA_dxp) or (opc = SBC_dxp) or 
            (opc = STA_dxp) or (opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or 
            (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
            (opc = SBC_dpy) or (opc = STA_dpy) or (opc = ADC_dby) or 
            (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or 
            (opc = LDA_dby) or (opc = ORA_dby) or (opc = SBC_dby) or 
            (opc = STA_dby) or (opc = ADC_db) or (opc = AND_db) or 
            (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or 
            (opc = ORA_db) or (opc = SBC_db) or (opc = STA_db) or 
            (opc = ADC_dspy) or (opc = AND_dspy) or 
            (opc =  CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or 
            (opc = ORA_dspy) or (opc = SBC_dspy) or (opc = STA_dspy))then
                state <= T1; --1d, 10b, 11, 13, 14, 15, 24, 
            elsif((opc = rti_s))then
                state <= T2; --22g
            end if;
            state <= T9;
        WHEN T9 =>
            if((opc = jsr_dxp) or (opc = jsl_al) or (opc = brk_s) or (opc = cop_s))then
                state <= T2; --2b, 4c, 22j
            else state <= T1; end if;--(didnt write box#)
		WHEN others => 
            report "unreachable" severity failure;
        END CASE;
    end if;
end process;

--State diagram/Bus activity per opcode
process(RESET_1,clk) begin
	if(RESET_1 = '0') then
		state <= RESET;
	elsif(clk'EVENT and clk='1') then
	CASE state IS
		WHEN RESET =>
			state <= T1;
      WHEN T1=> 
			state<=T2;
		WHEN T2=> 
			if((opc = adc_a) or (opc = and_a) or (opc =  bit_a) or 
			(opc =  cmp_a) or (opc =  cpx_a) or (opc =  cpy_a) or 
			(opc =  eor_a) or (opc = lda_a) or (opc =  ldx_a) or 
			(opc = ldy_a) or (opc = ora_a) or (opc = sbc_a) or 
			(opc =  sta_a) or (opc =  stx_a) or (opc = sty_a) or (opc =  stz_a)) then
				state <= T3;
			end if;
		WHEN T3 =>
			if((opc = adc_a) or (opc = and_a) or (opc =  bit_a) or 
			(opc =  cmp_a) or (opc =  cpx_a) or (opc =  cpy_a) or 
			(opc =  eor_a) or (opc = lda_a) or (opc =  ldx_a) or 
			(opc = ldy_a) or (opc = ora_a) or (opc = sbc_a) or 
			(opc =  sta_a) or (opc =  stx_a) or (opc = sty_a) or (opc =  stz_a)) then
				if(m_f = '0' or x_f = '0') then
					state <= T4;
				else
					state <= T5;
				end if;
			end if;
		WHEN T4 =>
		if((opc = adc_a) or (opc = and_a) or (opc =  bit_a) or 
			(opc =  cmp_a) or (opc =  cpx_a) or (opc =  cpy_a) or 
			(opc =  eor_a) or (opc = lda_a) or (opc =  ldx_a) or 
			(opc = ldy_a) or (opc = ora_a) or (opc = sbc_a) or 
			(opc =  sta_a) or (opc =  stx_a) or (opc = sty_a) or (opc =  stz_a)) then
				state <= T5;
			end if;
		WHEN T5 =>
			if((opc = adc_a) or (opc = and_a) or (opc =  bit_a) or 
			(opc =  cmp_a) or (opc =  cpx_a) or (opc =  cpy_a) or 
			(opc =  eor_a) or (opc = lda_a) or (opc =  ldx_a) or 
			(opc = ldy_a) or (opc = ora_a) or (opc = sbc_a) or 
			(opc =  sta_a) or (opc =  stx_a) or (opc = sty_a) or (opc =  stz_a)) then
				state <= T1;
			end if;
		when others => report "unreachable" severity failure;
   END CASE;
	end if;
end process;

--Detailed activity per opcode
process(state) begin
	CASE state IS
		WHEN RESET=>
			alua_r <= x"0000";
			alub_r <= x"0000";
			alusel_r <= x"0";
			ix_r <= x"0000";
			iy_r <= x"0000";
			stk_r <= x"0000";
			acc_r <= x"0000";
			pc_r <= x"0000";
			dir_r <= x"0000";
			pb_r <= x"00";
			dbk_r <= x"00";
			dl_r <= x"0000";
			prs_r <= x"00";
			abl_r <= x"00";
			abh_r <= x"00";
			abb_r <= x"00";
			ab_r <= x"000000";
			cpurd_1 <= '1';
			cpuwr_1 <= '1';
      WHEN T1=> 
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r;
			ir_r <= db_r; --opcode
		WHEN T2=> 
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
	--1a-----------------------------
			if((opc = ADC_a) or (opc = AND_a) or (opc = BIT_a) or (opc = CMP_a) or (opc = CPX_a) or (opc = CPY_a) or 
				(opc = EOR_a) or (opc = LDA_a) or (opc = LDX_a) or (opc = LDY_a) or (opc = ORA_a) or 
				(opc = SBC_a) or (opc = STA_a) or (opc = STX_a) or (opc = STY_a) or (opc = STZ_a)
			) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--1b------------------------------
			elsif((opc = JMP_a)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				pcl_r <= db_r;
--1c--------------------------------
			elsif((opc = JSR_a)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				pcl_r <= db_r;
--1d---------------------------------
			elsif((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
			(opc = TRB_a) or (opc = TSB_a)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--2a--------------------------------
			elsif((opc = JMP_dxp)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--2b----------------------------------
			elsif((opc = JSR_dxp)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--3a------------------------------------
			elsif((opc = JML_ap)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--3b------------------------------------
			elsif((opc = JMP_ap)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--4a---------------------------------------
			elsif((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
			(opc = SBC_al) or (opc = STA_al) or (opc = 8 OpCodes_al) or (opc = 4 bytes_al)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--4b---------------------------------------
			elsif((opc = JMP_al)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				pcl_r <= db_r;
--4c----------------------------------------
			elsif((opc = JSL_al)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				pcl_r <= db_r;
--5------------------------------------------
			elsif((opc = ADC_alx) or (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or (opc = LDA_alx) or (opc = ORA_alx) or 
			(opc = SBC_alx) or (opc = STA_alx)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--6a------------------------------------------
			elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
			(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
			(opc = STZ_dx)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--6b--------------------------------------------
			elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--7-----------------------------------------------
			elsif((opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
			(opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				abl_r <= db_r;
--10b-----------------------------------------------
			elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
			(opc = TRB_d) or (opc = TSB_d)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--11-------------------------------------------------
			elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
			(opc = SBC_dxp) or (opc = STA_dxp)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--12---------------------------------------------------
			elsif((opc = ADC_dp) or (opc = AND_dp) or (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or (opc = ORA_dp) or 
			(opc = SBC._dp) or (opc = STA_dp)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--13-----------------------------------------------------
			elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
			(opc = SBC_dpy) or (opc = STA_dpy)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--14--------------------------------------------------------
		elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
		(opc = SBC_dby) or (opc = STA_dby)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--15----------------------------------------------------------
		elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
		(opc = SBC_db) or (opc = STA_db)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--16a------------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STY_dx) or 
		(opc = STZ_dx)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--16b---------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
		) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--17---------------------------------------------------------------
		elsif((opc = LDX_dy) or (opc = STX_dy)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--20---------------------------------------------------------------
		elsif((opc = BCC_r) or (opc = BCS_r) or (opc = BEQ_r) or (opc = BMI_r) or (opc = BNE_r) or (opc = BPL_r) or 
		(opc = BRA_r) or (opc = BVC_r) or (opc = BVS_r)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--21---------------------------------------------------------------
		elsif((opc = BRL_rl)) then
				ab_r <= pb_r & pc_r + '1';
				pc_r <= pc_r+ '1';
				off_r <= db_r;
--22b---------------------------------------------------------------
		elsif((opc = PLA_s) or (opc = PLB_s) or (opc = PLD_s) or (opc = PLP_s) or (opc = PLX_s) or (opc = PLY_s)) then
				
--22d-------------------------------------------------------------------
		elsif((opc = PEA_s)) then
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abl_r <= db_r;
--22e------------------------------------------------------------------
		elsif((opc = PEI_s)) then
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			off_r <= db_r;
--22f----------------------------------------------------------------
		elsif((opc = PER_s)) then
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			off_r <= db_r;
--22g------------------------------------------------------------------
		elsif((opc = RTI_s)) then
     
--22h-------------------------------------------------------
		elsif((opc = RTS_s)) then

--22i----------------------------------------------------------
		elsif((opc = RTL_s)) then

--23-------------------------------------------------------------
		elsif((opc = ADC_ds) or (opc = AND_ds) or (opc = CMP_ds) or (opc = EOR_ds) or (opc = LDA_ds) or (opc = ORA_ds) or 
		(opc = SBC_ds) or (opc = STA_ds)) then
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			off_r <= db_r;
--24------------------------------------------------------------
		elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
		(opc = SBC_dspy) or (opc = STA_dspy)) then
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			off_r <= db_r;
		elsif(SEI_i) then
			i_f <= '1';
		elsif(CLC_i) then
			c_f <= '0';
		elsif(XCE_ac) then
			c_f <= e_f;
end if;
			
WHEN T3=> 
--1a------------------------------------------------------
		if((opc = ADC_a) or (opc = AND_a) or (opc = BIT_a) or (opc = CMP_a) or (opc = CPX_a) or (opc = CPY_a) or 
		(opc = EOR_a) or (opc = LDA_a) or (opc = LDX_a) or (opc = LDY_a) or (opc = ORA_a) or 
		(opc = SBC_a) or (opc = STA_a) or (opc = STX_a) or (opc = STY_a) or (opc = STZ_a)
		) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
			
--1b---------------------------------------------------------
		elsif((opc = JMP_a)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pch_r <= db_r;
--1c-------------------------------------------------------------
		elsif((opc = JSR_a)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pch_r <= db_r;
--1d----------------------------------------------------------
		elsif((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
		(opc = TRB_a) or (opc = TSB_a)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--2a-------------------------------------------------------
		elsif((opc = JMP_dxp)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--2b-------------------------------------------------------
		elsif((opc = JSR_dxp)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= x"00" & stk_r;
			db_r <= pch_r;
--3a-------------------------------------------------------
		elsif((opc = JML_ap)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--3b-------------------------------------------------------
		elsif((opc = JMP_ap)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--4a-------------------------------------------------------
		elsif((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
		(opc = SBC_al) or (opc = STA_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--4b-------------------------------------------------------
		elsif((opc = JMP_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pch_r <= db_r;
--4c--------------------------------------------------------
		elsif((opc = JSL_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pch_r <= db_r;
--5--------------------------------------------------------
		elsif((opc = ADC_alx) or (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or (opc = LDA_alx) or (opc = ORA_alx) or 
		(opc = SBC_alx) or (opc = STA_alx)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--6a-------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
		(opc = STZ_dx)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--6b--------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--7---------------------------------------------------------
		elsif((opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
		(opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--10b------------------------------------------------------
		elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
		(opc = TRB_d) or (opc = TSB_d)) then
     
--11-------------------------------------------------------
		elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
		(opc = SBC_dxp) or (opc = STA_dxp)) then
     
--12-------------------------------------------------------
		elsif((opc = ADC_dp) or (opc = AND_dp) or (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or (opc = ORA_dp) or 
		(opc = SBC._dp) or (opc = STA_dp)) then

--13---------------------------------------------------------
		elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
		(opc = SBC_dpy) or (opc = STA_dpy)) then
     
--14--------------------------------------------------------
		elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
		(opc = SBC_dby) or (opc = STA_dby)) then
     
--15--------------------------------------------------------
		elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
		(opc = SBC_db) or (opc = STA_db)) then

--16a------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STY_dx) or 
		(opc = STZ_dx)) then
     
--16b------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
		) then
     
--17---------------------------------------------------------------
		elsif((opc = LDX_dy) or (opc = STX_dy)) then
     
--20--------------------------------------------------------------
		elsif((opc = BCC_r) or (opc = BCS_r) or (opc = BEQ_r) or (opc = BMI_r) or (opc = BNE_r) or (opc = BPL_r) or 
		(opc = BRA_r) or (opc = BVC_r) or (opc = BVS_r)) then
     
--21--------------------------------------------------------
		elsif((opc = BRL_rl)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			offh_r <= db_r;
--22b--------------------------------------------------------
elsif((opc = PLA_s) or (opc = PLB_s) or (opc = PLD_s) or (opc = PLP_s) or (opc = PLX_s) or (opc = PLY_s)) then
    
--22d------------------------------------------------------------
		elsif((opc = PEA_s)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--22e-----------------------------------------------------------
		elsif((opc = PEI_s)) then
			
--22f--------------------------------------------------------
		elsif((opc = PER_s)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			offh_r <= db_r;
--22g---------------------------------------------------------
		elsif((opc = RTI_s)) then
     
--22h--------------------------------------------------------
		elsif((opc = RTS_s)) then
     
--22i-------------------------------------------------------
		elsif((opc = RTL_s)) then
     
--23----------------------------------------------------------
		elsif((opc = ADC_ds) or (opc = AND_ds) or (opc = CMP_ds) or (opc = EOR_ds) or (opc = LDA_ds) or (opc = ORA_ds) or 
		(opc = SBC_ds) or (opc = STA_ds)) then
     
--24------------------------------------------------------
		elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
		(opc = SBC_dspy) or (opc = STA_dspy)) then
     
end if;

WHEN T4=> 
--1a---------------------------------------------------------
		if((opc = ADC_a) or (opc = AND_a) or (opc = BIT_a) or (opc = CMP_a) or (opc = CPX_a) or (opc = CPY_a) or 
		(opc = EOR_a) or (opc = LDA_a) or (opc = LDX_a) or (opc = LDY_a) or (opc = ORA_a) or 
		(opc = SBC_a) or (opc = STA_a)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			dll_r <= db_r;
     --ADD CODE HERE
		elsif((opc = STX_a) or (opc = STY_a) or (opc = STZ_a)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			db_r <= dll_r;
     --ADD CODE HERE
--2a------------------------------------------------------------------
		elsif((opc = JMP_dxp)) then
			
--2b-------------------------------------------------------------------
		elsif((opc = JSR_dxp)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r-'1';
			db_r <= pcl_r;
--3a-------------------------------------------------------------------
		elsif((opc = JML_ap)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & abh_r & abh_r;
			pcl_r <= db_r;
--3b-----------------------------------------------------------------------
		elsif((opc = JMP_ap)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & abh_r & abh_r;
			pcl_r <= db_r;
--4a----------------------------------------------------------------------
		elsif((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
		(opc = SBC_al) or (opc = STA_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abb_r <= db_r;
--4b--------------------------------------------------------------------
		elsif((opc = JMP_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pb_r <= db_r;
--4c----------------------------------------------------------------------
		elsif((opc = JSL_al)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r;
			db_r <= pb_r;
--5----------------------------------------------------------------------
		elsif((opc = ADC_alx) or (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or (opc = LDA_alx) or (opc = ORA_alx) or 
		(opc = SBC_alx) or (opc = STA_alx)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abb_r <= db_r;
--6a----------------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STA_dx) or 
		(opc = STZ_dx)) then
			
--6b-----------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
		
--7------------------------------------------------------------------
		elsif((opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
		(opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay)) then
     
--10b------------------------------------------------------------------
		elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
		(opc = TRB_d) or (opc = TSB_d)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			dll_r <= db_r;
--11--------------------------------------------------------------------
		elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
		(opc = SBC_dxp) or (opc = STA_dxp)) then
		
--12---------------------------------------------------------------------
		elsif((opc = ADC_dp) or (opc = AND_dp) or (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or (opc = ORA_dp) or 
		(opc = SBC._dp) or (opc = STA_dp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			abl_r <= db_r;
--13-------------------------------------------------------------------
		elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
		(opc = SBC_dpy) or (opc = STA_dpy)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			abl_r <= db_r;
--14-----------------------------------------------------------------
		elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
		(opc = SBC_dby) or (opc = STA_dby)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			abl_r <= db_r;
--15--------------------------------------------------------------------
		elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
		(opc = SBC_db) or (opc = STA_db)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			abl_r <= db_r;
--16a-----------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx) or (opc = STY_dx) or 
		(opc = STZ_dx)) then
		
--16b----------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
		) then
		
--17-------------------------------------------------------------------
		elsif((opc = LDX_dy) or (opc = STX_dy)) then
     
--20---------------------------------------------------------------------
		elsif((opc = BCC_r) or (opc = BCS_r) or (opc = BEQ_r) or (opc = BMI_r) or (opc = BNE_r) or (opc = BPL_r) or 
		(opc = BRA_r) or (opc = BVC_r) or (opc = BVS_r)) then
     
--21-------------------------------------------------------------------
		elsif((opc = BRL_rl)) then
     
--22b-----------------------------------------------------------------
		elsif(opc = PLA_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLB_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLD_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLP_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLX_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLY_s) then
			ab_r <= x"00" & stk_r+'1';
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
--22d----------------------------------------------------------------
		elsif(opc = PEA_s) then
			--ADD CODE HE
--22e-----------------------------------------------------------------
		elsif((opc = PEI_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r;
			abl_r <= db_r;
--22f----------------------------------------------------------------
		elsif((opc = PER_s)) then
     
--22g------------------------------------------------------------------
		elsif((opc = RTI_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			prs_r <= db_r;
--22h-----------------------------------------------------------------
		elsif((opc = RTS_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			pcl_r <= db_r;
--22i-------------------------------------------------------------------
		elsif((opc = RTL_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+'1';
			pcl_r <= db_r;
--23-------------------------------------------------------------------
		elsif((opc = ADC_ds) or (opc = AND_ds) or (opc = CMP_ds) or (opc = EOR_ds) or (opc = LDA_ds) or (opc = ORA_ds) or 
		(opc = SBC_ds) or (opc = STA_ds)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r;
			dll_r <= db_r;
			--ADD CODE HERE

--24-----------------------------------------------------------------------
		elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
		(opc = SBC_dspy) or (opc = STA_dspy)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r;
			abl_r <= db_r;
	end if;			

WHEN T5=>
		--1a-------------------------------------------------------------
		if(opc = ADC_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = AND_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = BIT_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = CMP_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = CPX_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = CPY_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = EOR_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = LDA_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = LDX_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = LDY_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = ORA_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = SBC_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = STA_a) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = STX_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = STY_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = STZ_a) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			--ADD CODE HERE
--1c---------------------------------------------------------------
		elsif((opc = JSR_a)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r;
			db_r <= pch_r;
--1d-----------------------------------------------------------------
		elsif((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
		(opc = TRB_a) or (opc = TSB_a)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r + '1';
			dlh_r <= db_r;
--2a--------------------------------------------------------------------
		elsif((opc = JMP_dxp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= pb_r & abh_r & abl_r & ix_r;
			pcl_r <= db_r;
--2b-------------------------------------------------------------------
		elsif((opc = JSR_dxp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			abh_r <= db_r;
--3a---------------------------------------------------------------------
		elsif((opc = JML_ap)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & abh_r & abh_r + '1';
			pch_r <= db_r;
--3b-----------------------------------------------------------------------
		elsif((opc = JMP_ap)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & abh_r & abh_r + '1';
			pch_r <= db_r;
--4a------------------------------------------------------------
		elsif((opc = ADC_al) or (opc = AND_al) or (opc = CMP_al) or (opc = EOR_al) or (opc = LDA_al) or (opc = ORA_al) or 
		(opc = SBC_al) or (opc = STA_al)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r;
			dll_r <= db_r;
			--ADD CODE HERE

--4b-------------------------------------------------------------
		elsif((opc = JMP_al)) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r;
			ir_r <= db_r <= db_r;
--4c--------------------------------------------------------------
		elsif((opc = JSL_al)) then
			
--5----------------------------------------------------------------
		elsif((opc = ADC_alx) or (opc = AND_alx) or (opc = CMP_alx) or (opc = EOR_alx) or (opc = LDA_alx) or (opc = ORA_alx) or 
		(opc = SBC_alx) or (opc = STA_alx)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			dll_r <= db_r;
			--ADD CODE HERE
--6a---------------------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			dll_r <= db_r;
			--ADD CODE HERE
		elsif((opc = STZ_dx)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			db_r <= dll_r;
			--ADD CODE HERE
--6b----------------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			dll_r <= db_r;
--7------------------------------------------------------------------------
		elsif((opc = ADC_ay) or (opc = AND_ay) or (opc = CMP_ay) or (opc = EOR_ay) or (opc = LDA_ay) or (opc = LDX_ay) or 
		(opc = ORA_ay) or (opc = SBC_ay) or (opc = STA_ay)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r;
			dll_r <= db_r;
			--ADD CODE HERE
--10b---------------------------------------------------------------
		elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
		(opc = TRB_d) or (opc = TSB_d)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			dlh_r <= db_r;
--11------------------------------------------------------------------
		elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
		(opc = SBC_dxp) or (opc = STA_dxp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r;
			abl_r <= db_r;
--12------------------------------------------------------------------
		elsif((opc = ADC_dp) or (opc = AND_dp) or (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or (opc = ORA_dp) or 
		(opc = SBC._dp) or (opc = STA_dp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			abh_r <= db_r;
--13------------------------------------------------------------------
		elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
		(opc = SBC_dpy) or (opc = STA_dpy)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			abh_r <= db_r;
--14---------------------------------------------------------------------
		elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
		(opc = SBC_dby) or (opc = STA_dby)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			abh_r <= db_r;
--15-----------------------------------------------------------------------
		elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
		(opc = SBC_db) or (opc = STA_db)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			abh_r <= db_r;
--16a--------------------------------------------------------------------
		elsif((opc = ADC_dx) or (opc = AND_dx) or (opc = BIT_dx) or (opc = CMP_dx) or (opc = EOR_dx) or (opc = LDA_dx) or 
		(opc = LDY_dx) or (opc = ORA_dx) or (opc = SBC_dx) or (opc = STA_dx)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r;
			dll_r <= db_r;
			--ADD CODE HERE
		elsif((opc = STY_dx) or (opc = STZ_dx)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & dir_r + off_r + ix_r;
			db_r <= dll_r;
			--ADD CODE HERE
--16b----------------------------------------------------------------
		elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
		) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r;
			dll_r <= db_r;
--17------------------------------------------------------------------
		elsif((opc = LDX_dy)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + iy_r;
			dll_r <= db_r;
			--ADD CODE HERE
		elsif((opc = STX_dy)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & dir_r + off_r + iy_r;
			db_r <= dll_r;
			--ADD CODE HERE
--20-------------------------------------------------------------------
		elsif(opc = BCC_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BCS_r) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BEQ_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BMI_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BNE_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BPL_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BRA_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			--ADD CODE HERE
		elsif(opc = BVC_r) then
			romRd <= '0';
			ramRd <= '1';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + off_r;
			ir_r <= db_r;
			 --ADD CODE HERE
		elsif(opc = BVS_r) then
			--ADD CODE HE
--21---------------------------------------------------------------------
		elsif(opc = BRL_rl) then
			--ADD CODE HE
--22b-------------------------------------------------------------------
		elsif(opc = PLA_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLB_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLD_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLP_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLX_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
		elsif(opc = PLY_s) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			-- REG GOES HERE <= db_r;
			--ADD CODE HERE
--22d--------------------------------------------------------------------
		elsif(opc = PEA_s) then
			--ADD CODE HE
--22e-------------------------------------------------------------------
		elsif((opc = PEI_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '1';
			abh_r <= db_r;
--22f--------------------------------------------------------------------
		elsif((opc = PER_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r;
			db_r <= pch_r +off_r + c_f;
--22g-------------------------------------------------------------------
		elsif((opc = RTI_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			pcl_r <= db_r;
--22h-----------------------------------------------------------------
		elsif((opc = RTS_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			pch_r <= db_r;
--22i---------------------------------------------------------------
		elsif((opc = RTL_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"01";
			pch_r <= db_r;
--23-------------------------------------------------------------
		elsif(opc = ADC_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = AND_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = CMP_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = EOR_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = LDA_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = ORA_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1'; 
			--ADD CODE HERE
		elsif(opc = SBC_ds) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HERE
		elsif(opc = STA_ds) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r+off_r+'1';
			--ADD CODE HE
--24-------------------------------------------------------------------
		elsif(opc = ADC_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = AND_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = CMP_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = EOR_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = LDA_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = ORA_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = SBC_dspy) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+off_r+'1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = STA_dspy) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			--ADD CODE HE
end if;
		
WHEN T6=>
--1c----------------------------------------------------------------
		if((opc = JSR_a)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r-'1';
			db_r <= pcl_r;
--1d----------------------------------------------------------------
		elsif(opc = ASL_a) then
			--ADD CODE HERE
		elsif(opc = DEC_a) then
			--ADD CODE HERE
		elsif(opc = INC_a) then
			--ADD CODE HERE
		elsif(opc = LSR_a) then
			--ADD CODE HERE
		elsif(opc = ROL_a) then
			--ADD CODE HERE
		elsif(opc = ROR_a) then
			--ADD CODE HERE
		elsif(opc = TRB_a) then
			--ADD CODE HERE
		elsif(opc = TSB_a) then
			--ADD CODE HE
--2a--------------------------------------------------------------------
		elsif((opc = JMP_dxp)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= pb_r & abh_r & abl_r & ix_r;
			pch_r <= db_r;
--2b--------------------------------------------------------------------
		elsif((opc = JSR_dxp)) then
			
--3a-------------------------------------------------------------------
		elsif((opc = JML_ap)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & abh_r & abh_r + '2';
			pb_r <= db_r;
--3b-------------------------------------------------------------------
		elsif(opc = JMP_ap) then
		   --ADD CODE HE
--4a----------------------------------------------------------------------
		elsif(opc = ADC_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';	  
			--ADD CODE HERE
		elsif(opc = AND_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';
			 --ADD CODE HERE
		elsif(opc = CMP_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1'; 
			--ADD CODE HERE
		elsif(opc = EOR_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';
			--ADD CODE HERE
		elsif(opc = LDA_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';  
			 --ADD CODE HERE
		elsif(opc = ORA_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';  
			 --ADD CODE HERE
		elsif(opc = SBC_al) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abh_r + '1';  
			 --ADD CODE HERE
		elsif(opc = STA_al) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= abb_r & abh_r & abh_r + '1';
			 --ADD CODE HERE
		--4c------------------------------------------------------------------
		elsif((opc = JSL_al)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= pb_r & pc_r + '1';
			pc_r <= pc_r+ '1';
			pb_r <= db_r;
		--5-------------------------------------------------------------------
		elsif(opc = ADC_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;  
			 --ADD CODE HERE
		elsif(opc = AND_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
		   --ADD CODE HERE
		elsif(opc = CMP_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = EOR_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = LDA_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = ORA_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = SBC_alx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = STA_alx) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= abb_r & abh_r & abl_r & ix_r;
			--ADD CODE HE
		--6a--------------------------------------------------------------
		elsif(opc = ADC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			 --ADD CODE HERE
		elsif(opc = AND_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;  
			 --ADD CODE HERE
		elsif(opc = BIT_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			--ADD CODE HERE
		elsif(opc = CMP_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			--ADD CODE HERE
		elsif(opc = EOR_dx) then
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			--ADD CODE HERE
		elsif(opc = LDA_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = LDY_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = ORA_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = SBC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			--ADD CODE HERE
		elsif(opc = STA_dx) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			--ADD CODE HERE
		elsif(opc = STA_dx) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			 --ADD CODE HERE
		elsif(opc = STZ_dx) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= dbk_r & abh_r & abl_r & ix_r; 
			 --ADD CODE HE
		--6b------------------------------------------------------------------
		elsif(opc = ASL_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			dlh_r <= db_r;
			--ADD CODE HERE
		elsif((opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & ix_r;
			dlh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = ROR_dx) then
			 --ADD CODE HE
		--7-------------------------------------------------------------------
		elsif(opc = ADC_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = AND_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = CMP_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';  
			--ADD CODE HERE
		elsif(opc = EOR_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = LDA_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = LDX_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';  
			--ADD CODE HERE
		elsif(opc = ORA_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = SBC_ay) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			--ADD CODE HERE
		elsif(opc = STA_ay) then
			 --ADD CODE HE
		--10b--------------------------------------------------------------
		elsif(opc = ASL_d) then
			--ab_r <= x"00" & dir_r + off_r + '1';
			--IO <= db_r;
			--ADD CODE HERE
		elsif(opc = DEC_d) then
			--ab_r <= x"00" & dir_r + off_r + '1';
			--IO <= db_r;
			--ADD CODE HERE
		elsif(opc = INC_d) then
			-- ab_r <= x"00" & dir_r + off_r + '1';
			--  IO <= db_r;
			  --ADD CODE HERE
		elsif(opc = LSR_d) then
			-- ab_r <= x"00" & dir_r + off_r + '1';
			--  IO <= db_r;
			  --ADD CODE HERE
		elsif(opc = ROL_d) then
			-- ab_r <= x"00" & dir_r + off_r + '1';
			--  IO <= db_r;
			  --ADD CODE HERE
		elsif(opc = ROR_d) then
			-- ab_r <= x"00" & dir_r + off_r + '1';
			--  IO <= db_r;
			  --ADD CODE HERE
		elsif(opc = TRB_d) then
			-- ab_r <= x"00" & dir_r + off_r + '1';
			--  IO <= db_r;
			  --ADD CODE HERE
		elsif(opc = TSB_d) then
			 --ADD CODE HE
		--11--------------------------------------------------------------------
		elsif(opc = ADC_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = AND_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = CMP_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
			--ADD CODE HERE
		elsif(opc = EOR_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
		    --ADD CODE HERE
		elsif(opc = LDA_dxp) 
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = ORA_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
	        abh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = SBC_dxp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			abh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = STA_dxp) then
			 --ADD CODE HE
		--12-------------------------------------------------
		elsif(opc = ADC_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			--ADD CODE HERE
		elsif(opc = AND_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = CMP_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = EOR_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = LDA_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = ORA_dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = SBC._dp) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= dbk_r & abh_r & abh_r;
			  --ADD CODE HERE
		elsif(opc = STA_dp) then
			 --ADD CODE HE
		--13-----------------------------------------------------------
		elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
		(opc = SBC_dpy) or (opc = STA_dpy)) then
			  --ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
			  --IO <= db_r;
		--14---------------------------------------------------------------
		elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
		(opc = SBC_dby) or (opc = STA_dby)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + '2';
			abb_r <= db_r;
		--15-------------------------------------------------------------------
		elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
		(opc = SBC_db) or (opc = STA_db)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + "10";
			abb_r <= db_r;
		--16a-----------------------------------------------------------------
		elsif(opc = ADC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = AND_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = BIT_dx) then
		    romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = CMP_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = EOR_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = LDA_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = LDY_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = ORA_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			  --ADD CODE HERE
		elsif(opc = SBC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';  
			  --ADD CODE HERE
		elsif(opc = STA_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';  
			  --ADD CODE HERE
		elsif(opc = STY_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			 ab_r <= x"00" & dir_r + off_r + ix_r + '1';  
			  --ADD CODE HERE
		elsif(opc = STZ_dx) then
			 --ADD CODE HE
		--16b-------------------------------------------------------------------
		elsif(opc = ASL_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			dlh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = DEC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			dlh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = INC_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			dlh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = LSR_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			dlh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = ROL_dx) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & dir_r + off_r + ix_r + '1';
			dlh_r <= db_r;
			  --ADD CODE HERE
		elsif(opc = ROR_dx) then
			 --ADD CODE HE
		--17-------------------------------------------------------------------
		elsif(opc = LDX_dy) then
			ab_r <= x"00" & dir_r + off_r + iy_r + '1';  
			  --ADD CODE HERE
		elsif(opc = STX_dy) then
			 --ADD CODE HE
		--22e-------------------------------------------------------------
		elsif((opc = PEI_s)) then
			romRd <= '1';
			ramRd <= '1';
			ramWr <= '0';
			ab_r <= x"00" & stk_r;
			db_r <= abh_r;
		--22f--------------------------------------------------------------
		elsif(opc = PER_s) then
			 --ADD CODE HE
		--22g-----------------------------------------------------------------
		elsif((opc = RTI_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"11";
			pch_r <= db_r;
		--22h------------------------------------------------------------------
		elsif((opc = RTS_s)) then
			--ab_r <= x"00" & stk_r+"01";
			--IO <= db_r;
		--22i--------------------------------------------------------------------
		elsif((opc = RTL_s)) then
			romRd <= '1';
			ramRd <= '0';
			ramWr <= '1';
			ab_r <= x"00" & stk_r+"11";
			pb_r <= db_r;
		--24---------------------------------------------------------------------
		elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
		(opc = SBC_dspy) or (opc = STA_dspy)) then
			--ab_r <= x"00" & stk_r+off_r+'1';
			--IO <= db_r;

end if;

	WHEN T7=>
	--1c---------------------------------------------------------------------
	if(opc = JSR_a) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= pb_r & ir_r;
    	ir_r <= db_r <= db_r;
     --ADD CODE HERE
	--1d----------------------------------------------------------------
	elsif((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
	(opc = TRB_a) or (opc = TSB_a)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
    	ab_r <= dbk_r & abh_r & abh_r + '1';
     	db_r <= dlh_r;
	--2a-----------------------------------------------------------------
		elsif(opc = JMP_dxp) then
    --ADD CODE HE
	--2b----------------------------------------------------------------
	elsif((opc = JSR_dxp)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= pb_r & abh_r & abl_r & ix_r;
     	pcl_r <= db_r;
	--3a------------------------------------------------------------------
	elsif(opc = JML_ap) then
    --ADD CODE HE
	--4c------------------------------------------------------------------
	elsif((opc = JSL_al)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & stk_r-'1';
     	db_r <= pch_r;
	--6b-------------------------------------------------------------------
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
     	--ab_r <= dbk_r & abh_r & abl_r & ix_r;
     	--IO <= db_r;
	--10b------------------------------------------------------------------
	elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
	(opc = TRB_d) or (opc = TSB_d)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & dir_r + off_r + '1';
     	db_r <= dlh_r;
	--11-----------------------------------------------------------------
	elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
	(opc = SBC_dxp) or (opc = STA_dxp)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= dbk_r & abh_r & abh_r;
     	dll_r <= db_r;
     --ADD CODE HERE
	--12-------------------------------------------------------------------
	elsif((opc = ADC_dp) or (opc = AND_dp) or (opc = CMP_dp) or (opc = EOR_dp) or (opc = LDA_dp) or (opc = ORA_dp) or 
	(opc = SBC._dp) or (opc = STA_dp)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= dbk_r & abh_r & abh_r + '1';
     	dlh_r <= db_r;
     	--ADD CODE HERE
	--13-----------------------------------------------------------------------
	elsif((opc = ADC_dpy) or (opc = AND_dpy) or (opc = CMP_dpy) or (opc = EOR_dpy) or (opc = LDA_dpy) or (opc = ORA_dpy) or 
	(opc = SBC_dpy) or (opc = STA_dpy)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= dbk_r & abh_r & abl_r & iy_r;
     	dll_r <= db_r;
     	--ADD CODE HERE
	--14---------------------------------------------------------------------
	elsif((opc = ADC_dby) or (opc = AND_dby) or (opc = CMP_dby) or (opc = EOR_dby) or (opc = LDA_dby) or (opc = ORA_dby) or 
	(opc = SBC_dby) or (opc = STA_dby)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= abb_r & abh_r & abl_r & iy_r;
    	dll_r <= db_r;
     	--ADD CODE HERE
	--15---------------------------------------------------------------------
	elsif((opc = ADC_db) or (opc = AND_db) or (opc = CMP_db) or (opc = EOR_db) or (opc = LDA_db) or (opc = ORA_db) or 
	(opc = SBC_db) or (opc = STA_db)) then
    	ab_r <= abb_r & abh_r & abh_r;
     	dll_r <= db_r;
     --ADD CODE HERE
	--16b-----------------------------------------------------------------
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
	) then
    	
	--22e--------------------------------------------------------------------
	elsif(opc = PEI_s) then
    	--ADD CODE HE
--22g------------------------------------------------------------------
	elsif((opc = RTI_s)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= x"00" & stk_r+"100";
     	pb_r <= db_r;
	--22h---------------------------------------------------------------
	elsif(opc = RTS_s) then
    	--ADD CODE HE
	--22i----------------------------------------------------------------
	elsif(opc = RTL_s) then
    	--ADD CODE HE
	--24--------------------------------------------------------------------
	elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
	(opc = SBC_dspy) or (opc = STA_dspy)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= dbk_r & abh_r & abl_r & iy_r;
     	dll_r <= db_r;
     	--ADD CODE HERE
end if;

	WHEN T8=>
	--1d------------------------------------------------------------
	if((opc = ASL_a) or (opc = DEC_a) or (opc = INC_a) or (opc = LSR_a) or (opc = ROL_a) or (opc = ROR_a) or 
	(opc = TRB_a) or (opc = TSB_a)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= dbk_r & abh_r & abh_r;
     	db_r <= dll_r;
	--2b-----------------------------------------------------------------
	elsif((opc = JSR_dxp)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= pb_r & abh_r & abl_r & ix_r;
     	pch_r <= db_r;
	--4c----------------------------------------------------------------
	elsif((opc = JSL_al)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & stk_r-"01";
     	db_r <= pcl_r;
	--6b----------------------------------------------------------------
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= dbk_r & abh_r & abl_r & ix_r;
    	db_r <= dlh_r;
	--10b---------------------------------------------------------------
	elsif((opc = ASL_d) or (opc = DEC_d) or (opc = INC_d) or (opc = LSR_d) or (opc = ROL_d) or (opc = ROR_d) or 
	(opc = TRB_d) or (opc = TSB_d)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & dir_r + off_r;
     	db_r <= dll_r;
	--11------------------------------------------------------------------
	elsif((opc = ADC_dxp) or (opc = AND_dxp) or (opc = CMP_dxp) or (opc = EOR_dxp) or (opc = LDA_dxp) or (opc = ORA_dxp) or 
	(opc = SBC_dxp) or (opc = STA_dxp)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= dbk_r & abh_r & abh_r + '1';
     	dlh_r <= db_r;
     --ADD CODE HERE
	elsif(opc = EOR_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
    	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = LDA_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = LDX_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = LDY_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = ORA_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = SBC_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = STA_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = STX_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = STY_d) then
		romRd <= '0';
		ramRd <= '1';
		ramWr <= '1';
    	ab_r <= pb_r & pc_r + '1';
     	pc_r <= pc_r+ '1';
     	off_r <= db_r;
     --ADD CODE HERE
	elsif(opc = STZ_d) then
    	--ADD CODE HE
	--13-------------------------------------------------------------
	elsif(opc = ADC_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';   
     	--ADD CODE HERE
	elsif(opc = AND_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = CMP_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = EOR_dpy) then
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = LDA_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = ORA_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = SBC_dpy) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = STA_dpy) then
    	--ADD CODE HE
	--14------------------------------------------------------------
	elsif(opc = ADC_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = AND_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = CMP_dby) then
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
    	--ADD CODE HERE
	elsif(opc = EOR_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = LDA_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = ORA_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = SBC_dby) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abl_r & iy_r +'1';
     --ADD CODE HERE
	elsif(opc = STA_dby) then
    	--ADD CODE HE
	--15--------------------------------------------------------------------
	elsif(opc = ADC_db) then
    	ab_r <= abb_r & abh_r & abh_r + '1';
     --ADD CODE HERE
	elsif(opc = AND_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abh_r + '1';
     	--ADD CODE HERE
	elsif(opc = CMP_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abh_r + '1';
     --ADD CODE HERE
	elsif(opc = EOR_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
        ab_r <= abb_r & abh_r & abh_r + '1';
     	--ADD CODE HERE
	elsif(opc = LDA_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abh_r + '1';
     	--ADD CODE HERE
	elsif(opc = ORA_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abh_r + '1';
     	--ADD CODE HERE
	elsif(opc = SBC_db) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= abb_r & abh_r & abh_r + '1';
     	--ADD CODE HERE
	elsif(opc = STA_db) then
    	--ADD CODE HE
	--16b-----------------------------------------------------------------
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
	) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & dir_r + off_r + ix_r + '1';
     	db_r <= dlh_r;
	--22e----------------------------------------------------------------------
	elsif(opc = PEI_s) then
    --ADD CODE HE
	--22g-----------------------------------------------------------------
	elsif((opc = RTI_s)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
     	ab_r <= x"00" & stk_r+"100";
     	pb_r <= db_r;
	--22h--------------------------------------------------------------------
	elsif(opc = RTS_s) then
    	--ADD CODE HE
	--22i-------------------------------------------------------------------
	elsif(opc = RTL_s) then
    	--ADD CODE HE
	--24------------------------------------------------------------------
	elsif((opc = ADC_dspy) or (opc = AND_dspy) or (opc = CMP_dspy) or (opc = EOR_dspy) or (opc = LDA_dspy) or (opc = ORA_dspy) or 
	(opc = SBC_dspy) or (opc = STA_dspy)) then
		romRd <= '1';
		ramRd <= '0';
		ramWr <= '1';
    	ab_r <= dbk_r & abh_r & abl_r & iy_r;
     	dll_r <= db_r;
     --ADD CODE HERE
end if;		

	WHEN T9=>
	--2b
	if(opc = JSR_dxp) then
		--ADD CODE HE
	--4c
	elsif(opc = JSL_al) then
    	--ADD CODE HE

	--6b
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= dbk_r & abh_r & abl_r & ix_r;
     	db_r <= dll_r;
	--16b
	elsif((opc = ASL_dx) or (opc = DEC_dx) or (opc = INC_dx) or (opc = LSR_dx) or (opc = ROL_dx) or (opc = ROR_dx)
	) then
		romRd <= '1';
		ramRd <= '1';
		ramWr <= '0';
     	ab_r <= x"00" & dir_r + off_r + ix_r;
     	db_r <= dll_r;
end if;			
when others => report "unreachable" severity failure;   END CASE;
end process;


end Behavioral;