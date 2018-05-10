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

entity ppu is
PORT(
--INPUTS
CLK : in STD_LOGIC;
RESETN : in STD_LOGIC;

PAB_IN : in STD_LOGIC_VECTOR(7 downto 0);
PA_RD : in STD_LOGIC;
PA_WR : in STD_LOGIC;
DB_IN : in STD_LOGIC_VECTOR(7 downto 0);
VDA_IN, VDB_IN : out STD_LOGIC_VECTOR(7 downto 0);

---OUTPUTS
VBLANKN : out STD_LOGIC_VECTOR;
DB_OUT : out STD_LOGIC_VECTOR(7 downto 0);
VRD : out STD_LOGIC;
VB_WR, VA_WR : out STD_LOGIC;
VAA, VAB : out STD_LOGIC_VECTOR(13 downto 0);
VA : out STD_LOGIC;
EXT : out STD_LOGIC_VECTOR(7 downto 0);
VDA_OUT, VDB_OUT : out STD_LOGIC_VECTOR(7 downto 0)
);
end ppu;

architecture Behavioral of ppu is

SIGNAL CLK, CE, RSTN : STD_LOGIC;

--MEMAPPU REGS
SIGNAL PAB : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL DB : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL PAR, PAW : STD_LOGIC;
SIGNAL VRD, VAW, VBW : STD_LOGIC;
SIGNAL DBO : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL VAADDI, VBADDI : STD_LOGIC_VECTOR(13 downto 0);
SIGNAL VAADDO, VBADDO : STD_LOGIC_VECTOR(13 downto 0);
SIGNAL VDAO, VDBO : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL VDAI, VDBI : STD_LOGIC_VECTOR(7 downto 0);

--CGRAM REGS
SIGNAL CGAI : STD_LOGIC_VECTOR(13 downto 0);
SIGNAL CGDI : STD_LOGIC_VECTOR(8 downto 0);
SIGNAL CGRW : STD_LOGIC;
SIGNAL CGAO : STD_LOGIC_VECTOR(13 downto 0);
SIGNAL CGDO : STD_LOGIC(7 downto 0);

--SPRITES
SIGNAL HPOS, VPOS : STD_LOGIC;
SIGNAL PTAO : STD_LOGIC;
SIGNAL SFP : STD_LOGIC;
SIGNAL SP : STD_LOGIC;
SIGNAL SOF : STD_LOGIC;

COMPONENT MEMAPPU IS
PORT(
    CLK,CE,RSTN : IN STD_LOGIC;
    PAB_IN, DB_IN : in STD_LOGIC_VECTOR(7 downto 0);
    PA_RD, PA_WR : in STD_LOGIC;
    VRD, VA_WR, VB_WR : out STD_LOGIC;
    DB_OUT : out STD_LOGIC_VECTOR(7 downto 0);
    VAA, VBB : out STD_LOGIC_VECTOR(13 downto 0);
    VDA_OUT, VDB_OUT : out STD_LOGIC_VECTOR(7 downto 0)
);
end COMPONENT;

COMPONENT SPRITE is
PORT(
    CLK : in std_logic;
    CE : in std_logic;
    RSTN : in std_logic;
        
    HPOS : in integer range 0 to 340;
    VPOS : in integer range 0 to 261;
    
	PatternTableAddressOffset : in std_logic;
    
    -- Selector output         
    SpriteForegroundPriority : out std_logic;
    SpriteIsPrimary : out std_logic;
        
    SpriteOverflowFlag : out std_logic;
        
    VAA, VBB : out unsigned(13 downto 0) := (others => '0');
    VDA_OUT, VDB_OUT : in std_logic_vector(7 downto 0);
        
    VAA, VBB : in unsigned(13 downto 0);
    VDA_IN, VDB_IN : out std_logic_vector(7 downto 0);
    VA_WR, VB_WR : in std_logic    
);
end COMPONENT;

COMPONENT CGRAM is
PORT(
    CLK,CE : in STD_LOGIC;
    CG_ADD_IN : in STD_LOGIC_VECTOR(13 downto 0);
    CG_DATA_IN : in STD_LOGIC_VECTOR(13 downto 0);
    CGRAMW : in STD_LOGIC;

    ---OUTPUTS
    CG_ADD_OUT : out STD_LOGIC_VECTOR(13 downto 0);
    CG_DATA_OUT : out STD_LOGIC_VECTOR(7 downto 0)
    );
end COMPONENT;

COMPONENT VGA is
PORT(
    CLK, RSTN : in STD_LOGIC;
    VAA : in STD_LOGIC_VECTOR(13 downto 0);


);
end COMPONENT;

begin

MMPPU : MEMAPPU PORT MAP(CLK,CE,RSTN,PAB,DB,PAR,PAW,VRD,VAW,VBW,DBO,VAADDI,VBADDI,VDAO,VDBO); 
CGR : CGRAM PORT MAP (CLK,CE,CGAI,CGDI,CGRW,CGAO,CGDO);
SPR : SPRITE PORT MAP (CLK,CE,RSTN,HPOS,VPOS,PTAO,SFP,SP,SOF,VAADDI,VBADDI,VDAO,VDBO,VAADDI,VBADDI,VDAI,VDBI,VAW,VBW);
VIDEO : VGA PORT MAP(CLK,RSTN, )

end Behavioral;