----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:58:42 03/08/2018 
-- Design Name: 
-- Module Name:    MEMAPPU - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MEMAPPU is
Port (
    --IN
    PAB_IN, DB_IN : in STD_LOGIC_VECTOR(7 downto 0);
    PA_RD, PA_WR : in STD_LOGIC;

    --OUT
    VRD, VB_WR, VA_WR : out STD_LOGIC;
    DB_OUT : out STD_LOGIC_VECTOR(7 downto 0);
    VAA, VBB : out STD_LOGIC_VECTOR(13 downto 0);
    VDA_OUT, VDB_OUT : out STD_LOGIC_VECTOR(7 downto 0)
    CG_DATA : out STD_LOGIC_VECTOR(7 downto 0);
    CG_ADD : out STD_LOGIC_VECTOR(13 downto 0)
);
end MEMAPPU;

architecture Behavioral of MEMAPPU is

--READ ONLY PORTS
SIGNAL MPYL : STD_LOGIC_VECTOR(7 downto 0); --PPU1 Signed Multiply Result (lower 8bits)
SIGNAL MYPM : STD_LOGIC_VECTOR(7 downto 0); --PPU1 Signed Multiply Result (mid 8bits)
SIGNAL MYPH : STD_LOGIC_VECTOR(7 downto 0); --PPU1 Signed Multiply Result (upper 8bits)
SIGNAL SLVH : STD_LOGIC_VECTOR(7 downto 0); --PPU1 Latch H/V-Coutner by Software (Read=Strobe)
SIGNAL RDOAM : STD_LOGIC_VECTOR(7 downto 0); --PPU1 OAM Data Read (read-twice)
SIGNAL RDVRAML : STD_LOGIC_VECTOR(7 downto 0); --PPU1 VRAM Data Read (lower 8bits)
SIGNAL RDVRAMH : STD_LOGIC_VECTOR(7 downto 0); --PPU1 VRAM Data Read (upper 8bits)
SIGNAL RDCGRAM : STD_LOGIC_VECTOR(7 downto 0); --PPU2 CGRAM Data Read (Palette)(read-twice)
SIGNAL OPHCT : STD_LOGIC_VECTOR(7 downto 0); --PPU2 horizontal Counter Latch (read-twice)
SIGNAL OPVCT : STD_LOGIC_VECTOR(7 downto 0); --PPU2 Vertical Counter Latch (read-twice)
SIGNAL STAT77 : STD_LOGIC_VECTOR(7 downto 0); --PPU1 Status and PPU1 Version Number
SIGNAL STAT78 : STD_LOGIC_VECTOR(7 downto 0); --PPU2 Status and PPU2 Version Number (bit7=0)

--WRITE ONLY PORTS
SIGNAL INIDISP : STD_LOGIC_VECTOR(7 downto 0);-- Display Control 1                                  8xh
SIGNAL OBSEL : STD_LOGIC_VECTOR(7 downto 0);  -- Object Size and Object Base                        (?)
SIGNAL OAMADDL : STD_LOGIC_VECTOR(14 downto 0); -- OAM Address (lower 8bit)                           (?)
SIGNAL OAMADDH : STD_LOGIC_VECTOR(7 downto 0); -- OAM Address (upper 1bit) and Priority Rotation     (?)
SIGNAL OAMDATA : STD_LOGIC_VECTOR(7 downto 0); -- OAM Data Write (write-twice)                       (?)
SIGNAL BGMODE : STD_LOGIC_VECTOR(7 downto 0);  -- BG Mode and BG Character Size                      (xFh)
SIGNAL MOSAIC : STD_LOGIC_VECTOR(15 downto 0); -- Mosaic Size and Mosaic Enable                      (?)
SIGNAL BG1SC : STD_LOGIC_VECTOR(15 downto 0);   -- BG1 Screen Base and Screen Size                    (?)
SIGNAL BG2SC : STD_LOGIC_VECTOR(15 downto 0);   -- BG2 Screen Base and Screen Size                    (?)
SIGNAL BG3SC : STD_LOGIC_VECTOR(15 downto 0);   -- BG3 Screen Base and Screen Size                    (?)
SIGNAL BG4SC : STD_LOGIC_VECTOR(15 downto 0);   -- BG4 Screen Base and Screen Size                    (?)
SIGNAL BG12NBA : STD_LOGIC_VECTOR(15 downto 0); -- BG Character Data Area Designation                 (?)
SIGNAL BG34NBA : STD_LOGIC_VECTOR(15 downto 0); -- BG Character Data Area Designation                 (?)
SIGNAL BG1HOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG1 Horizontal Scroll (X) (write-twice) / M7HOFS   (?,?)
SIGNAL BG1VOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG1 Vertical Scroll (Y)   (write-twice) / M7VOFS   (?,?)
SIGNAL BG2HOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG2 Horizontal Scroll (X) (write-twice)            (?,?)
SIGNAL BG2VOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG2 Vertical Scroll (Y)   (write-twice)            (?,?)
SIGNAL BG3HOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG3 Horizontal Scroll (X) (write-twice)            (?,?)
SIGNAL BG3VOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG3 Vertical Scroll (Y)   (write-twice)            (?,?)
SIGNAL BG4HOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG4 Horizontal Scroll (X) (write-twice)            (?,?)
SIGNAL BG4VOFS : STD_LOGIC_VECTOR(15 downto 0); -- BG4 Vertical Scroll (Y)   (write-twice)            (?,?)
SIGNAL VMAIN : STD_LOGIC_VECTOR(15 downto 0);  -- VRAM Address Increment Mode                        (?Fh)
SIGNAL VMADDL : STD_LOGIC_VECTOR(7 downto 0);  -- VRAM Address (lower 8bit)                          (?)
SIGNAL VMADDH : STD_LOGIC_VECTOR(7 downto 0); -- VRAM Address (upper 8bit)                          (?)
SIGNAL VMDATAL : STD_LOGIC_VECTOR(7 downto 0): -- VRAM Data Write (lower 8bit)                       (?)
SIGNAL VMDATAH : STD_LOGIC_VECTOR(7 downto 0); -- VRAM Data Write (upper 8bit)                       (?)
SIGNAL M7SEL : STD_LOGIC_VECTOR(15 downto 0);   -- Rotation/Scaling Mode Settings                     (?)
SIGNAL M7A : STD_LOGIC_VECTOR(15 downto 0);     -- Rotation/Scaling Parameter A & Maths 16bit operand(FFh)(w2)
SIGNAL M7B : STD_LOGIC_VECTOR(7 downto 0);     -- Rotation/Scaling Parameter B & Maths 8bit operand (FFh)(w2)
SIGNAL M7C : STD_LOGIC_VECTOR(15 downto 0);     -- Rotation/Scaling Parameter C         (write-twice) (?)
SIGNAL M7D :  STD_LOGIC_VECTOR(15 downto 0);     -- Rotation/Scaling Parameter D         (write-twice) (?)
SIGNAL M7X : STD_LOGIC_VECTOR(15 downto 0);     -- Rotation/Scaling Center Coordinate X (write-twice) (?)
SIGNAL M7Y : STD_LOGIC_VECTOR(15 downto 0);     -- Rotation/Scaling Center Coordinate Y (write-twice) (?)
SIGNAL CGADD : STD_LOGIC_VECTOR(15 downto 0);  -- Palette CGRAM Address                              (?)
SIGNAL CGDATA : STD_LOGIC_VECTOR(15 downto 0):  -- Palette CGRAM Data Write             (write-twice) (?)
SIGNAL W12SEL : STD_LOGIC_VECTOR(15 downto 0):  -- Window BG1/BG2 Mask Settings                       (?)
SIGNAL W34SEL : STD_LOGIC_VECTOR(15 downto 0);  -- Window BG3/BG4 Mask Settings                       (?)
SIGNAL WOBJSEL : STD_LOGIC_VECTOR(15 downto 0); -- Window OBJ/MATH Mask Settings                      (?)
SIGNAL WH0 : STD_LOGIC_VECTOR(15 downto 0);     -- Window 1 Left Position (X1)                        (?)
SIGNAL WH1 : STD_LOGIC_VECTOR(15 downto 0);     -- Window 1 Right Position (X2)                       (?)
SIGNAL WH2 : STD_LOGIC_VECTOR(15 downto 0);     -- Window 2 Left Position (X1)                        (?)
SIGNAL WH3 : STD_LOGIC_VECTOR(15 downto 0);     -- Window 2 Right Position (X2)                       (?)
SIGNAL WBGLOG : STD_LOGIC_VECTOR(15 downto 0);  -- Window 1/2 Mask Logic (BG1-BG4)                    (?)
SIGNAL WOBJLOG : STD_LOGIC_VECTOR(15 downto 0); -- Window 1/2 Mask Logic (OBJ/MATH)                   (?)
SIGNAL TM : STD_LOGIC_VECTOR(15 downto 0);      -- Main Screen Designation                            (?)
SIGNAL TS : STD_LOGIC_VECTOR(15 downto 0);      -- Sub Screen Designation                             (?)
SIGNAL TMW : STD_LOGIC_VECTOR(15 downto 0);     -- Window Area Main Screen Disable                    (?)
SIGNAL TSW : STD_LOGIC_VECTOR(15 downto 0);    -- Window Area Sub Screen Disable                     (?)
SIGNAL CGWSEL : STD_LOGIC_VECTOR(15 downto 0);  -- Color Math Control Register A                      (?)
SIGNAL CGADSUB : STD_LOGIC_VECTOR(15 downto 0); -- Color Math Control Register B                      (?)
SIGNAL COLDATA : STD_LOGIC_VECTOR(15 downto 0); -- Color Math Sub Screen Backdrop Color               (?)
SIGNAL SETINI : STD_LOGIC_VECTOR(15 downto 0);  -- Display Control 2                                  00h?
SIGNAL CGRAMW : STD_LOGIC; --CGRAM Write

begin

PROCESS(PAB_IN,DB_IN,PA_RD,PA_WR,DB_OUT) begin
  case(PAB_IN) is
  when x"00" => 
    INIDISP <= DB_IN; 
  when x"01" => 
   OBSEL <= DB_IN;
  when x"02" => 
   OAMADDL <= DB_IN;
  when x"03" => 
   OAMADDH <= DB_IN;
  when x"04" => 
   OAMDATA <= DB_IN;
  when x"05" => 
   BGMODE <= DB_IN;
  when x"06" => 
   MOSAIC <= DB_IN;
  when x"07" => 
   BG1SC <= DB_IN;
  when x"08" => 
   BG2SC <= DB_IN;
  when x"09" => 
   BG3SC <= DB_IN;
  when x"0A" =>  
   BG4SC <= DB_IN;
  when x"0B" => 
   BG12NBA <= DB_IN;
  when x"0C" => 
   BG34NBA <= DB_IN;
  when x"0D" => 
    BG1HOFS <= DB_IN;
   when x"0E" =>
    BG1VOFS <= DB_IN;
   when x"0F" =>
    BG2HOFS <= DB_IN;
   when x"10" =>
    BG2VOFS <= DB_IN;
   when x"11" =>
    BG3HOFS <= DB_IN;
   when x"12" =>
    BG3VOFS <= DB_IN;
   when x"13" =>
    BG4HOFS <= DB_IN;
   when x"14" =>
    BG4VOFS <= DB_IN;
   when x"15" =>
    VMAIN <= DB_IN;
   when x"16" =>
    VMADDL <= DB_IN;
   when x"17" =>
    VMADDH <= DB_IN;
   when x"18" =>
    VMDATAL <= DB_IN;
   when x"19" =>
    VMDATAH <= DB_IN;
   when x"1A" =>
    M7SEL <= DB_IN;
   when x"1B" =>
    M7A <=DB_IN;
   when x"1C" =>
    M7B <= DB_IN;
   when x"1D" =>
    M7C <= DB_IN;
   when x"1E" =>
    M7D <= DB_IN;
   when x"1F" =>
    M7X <= DB_IN;
   when x"20" =>
    M7Y <= DB_IN;
    when x"21" =>
    CGADD <= DB_IN;
    when x"22" =>
    CGDATA <= DB_IN;
    when x"23" =>
    W12SEL <= DB_IN;
    when x"24" =>
    W34SEL <= DB_IN;
    when x"25" =>
    WOBJSEL <= DB_IN;
    when x"26" =>
    WH0 <= DB_IN;
    when x"27" =>
    WH1 <= DB_IN;
    when x"28" =>
    WH2 <= DB_IN;
    when x"29" =>
    WH3 <= DB_IN;
    when x"2A" =>
    WBGLOG <= DB_IN;
    when x"2B" =>
    WOBJLOG <= DB_IN;
    when x"2C" =>
    TM <= DB_IN;
    when x"2D" =>
    TS <= DB_IN;
    when x"2E" =>
    TMW <= DB_IN;
    when x"2F" =>
    TSW <= DB_IN;
    when x"30" =>
    CGWSEL <= DB_IN;
    when x"31" =>
    CGADSUB <= DB_IN;
    when x"32" =>
    COLDATA <= DB_IN;
    when x"33" =>
    SETINI <= DB_IN;
    when x"34" =>
    MPYL <= DB_IN;
    when x"35" =>
    MYPM <= DB_IN;
    when x"36" =>
    MYPH <= DB_IN;
    when x"37" =>
    SLVH <= DB_IN;
    when x"38" =>
    RDOAM <= DB_IN;
    when x"39" =>
    RDVRAML <= DB_IN;
    when x"3A" =>
    RDVRAMH <= DB_IN;
    when x"3B" =>
    RDCGRAM <= DB_IN;
    when x"3C" =>
    OPHCT <= DB_IN;
    when x"3D" =>
    OPVCT <= DB_IN;
    when x"3E" =>
    STAT77 <= DB_IN;
    when x"3F" =>
    STAT78 <= DB_IN;
  end case;
 end process;

PROCESS(VAA,VBB,VB_WR, VA_WR, VRD,PAB_IN) begin
   if(x"39" = PAB_IN and VRD = 0) then
    VAA <= VMADDL;
    VDA_OUT <= RDVRAML;
    else if (x"3A" and VRD = 0) then
    VBB <= VMADDH;
    VDB_OUT <= RDVRAMH;
    else if(x"15" and VA_WR = 0) then
    VAA <= VMADDL;
    VDA_OUT <= VMDATAL;
    else if(x"16" and VB_WR = 0) then
    VBB <= VMADDH;
    VDB_OUT <= VMDATAH;
    end if;
    end if;
    end if;
    end if;
end PROCESS;

PROCESS(PAB_IN) begin
    if(x"04" = PAB_IN) then
        VAA(7 downto 0) <= OAMADDL;
        VBB(7 downto 0) <= OAMADDH;
        VDA_OUT <= OAMDATA;
        VDB_OUT <= OAMDATA;
    else if(x"38" = PAB_IN) then
        VAA(7 downto 0) <= OAMADDL;
        VBB(7 downto 0) <= OAMADDH;
        VDA_OUT <= RDOAM;
        VDB_OUT <= RDOAM;
    end if;
    end if;
end PROCESS;

PROCESS(PAB_IN) begin
    if(x"22" = PAB_IN) then
        CG_ADD <= CGADD;
        CG_DATA <= CGDATA;
        CGRAMW <= '0';
    if(x"38" = PAB_IN) then
         CG_ADD <= CGADD;
         CG_DATA <= RDCGRAM;
         CGRAMW <= '1';
    end if;
    end if;
end PROCESS;

end Behavioral;