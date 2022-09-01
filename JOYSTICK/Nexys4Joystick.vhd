library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity Nexys4Joystick is
  port (
    -- les 16 switchs
    swt : in std_logic_vector (15 downto 0);
    -- les 5 boutons noirs
    btnC, btnU, btnL, btnR, btnD : in std_logic;
    -- horloge
    mclk : in std_logic;
    -- les 16 leds
    led : out std_logic_vector (15 downto 0);
    -- les anodes pour sélectionner les afficheurs 7 segments à utiliser
    an : out std_logic_vector (7 downto 0);
    -- valeur affichée sur les 7 segments (point décimal compris, segment 7)
    ssg : out std_logic_vector (7 downto 0);
	 ssjoystick :out std_logic;-- déclaré dans .ucf avec PMOD JA 
	 sclkjoystick :out std_logic;
	 mosijoystick :out std_logic;
	 misojoystick :in std_logic
  );
end Nexys4Joystick;

architecture synthesis of Nexys4Joystick is

  -- rappel du (des) composant(s)
  component diviseurClk is
    generic(facteur : natural);
    port (
      clk, reset : in  std_logic;
      nclk       : out std_logic);
  end component;
  component All7Segments is 
    Port ( clk : in  std_logic;
           reset : in std_logic;
           e0 : in std_logic_vector (3 downto 0);
           e1 : in std_logic_vector (3 downto 0);
           e2 : in std_logic_vector (3 downto 0);
           e3 : in std_logic_vector (3 downto 0);
           e4 : in std_logic_vector (3 downto 0);
           e5 : in std_logic_vector (3 downto 0);
           e6 : in std_logic_vector (3 downto 0);
           e7 : in std_logic_vector (3 downto 0);
           an : out std_logic_vector (7 downto 0);
           ssg : out std_logic_vector (7 downto 0));
	end component;
	
	component MasterJoystick is 
		Port (rst : in std_logic;
         clk : in std_logic;
         en : in std_logic;
         miso : in std_logic;
			led1 : in std_logic;
			led2 : in std_logic;
			X: out std_logic_vector(9 downto 0);
			Y: out std_logic_vector(9 downto 0);
			btn1 : out std_logic;
			btn2 : out std_logic;
			joystick : out std_logic;
         ss   : out std_logic;
         sclk : out std_logic;
         mosi : out std_logic;
         busy : out std_logic);
	end component;

signal Xbis :std_logic_vector (9 downto 0);--signal intermédiaire de xl
signal Ybis :std_logic_vector (9 downto 0);--signal intermédiaire de xh
signal busybis : std_logic;-- signal intermédiaire de busybis
begin

  -- valeurs des sorties 
  -- 13 leds éteintes
  led(15 downto 3) <= (others => '0');

  -- connexion du (des) composant(s) avec les ports de la carte
  -- voir le dossier schémas pour la carte FPGA
	Inst_MasterJoystick: MasterJoystick PORT MAP(
		rst => swt(0),
		clk => mclk,
		en => '1',
		X => Xbis,
		Y => Ybis,
		btn1 =>led(0),
		btn2 => led(1),
		joystick =>led(2),
		led1 =>btnC,
		led2 =>btnU,
		miso =>misojoystick,
		ss => ssjoystick,
		sclk => sclkjoystick,
		mosi => mosijoystick,
		busy=> busybis
	);
	Inst_all7seg: All7Segments PORT MAP(
		clk => mclk,
		reset =>swt(1),
		e0 => Xbis(3 downto 0),--X3 x2 X1 X0
		e1 => Xbis(7 downto 4),--X7 X6 X5 X4
		--0 0 X9 X8
		e2(0) => '0',
		e2(1) => '0',
		e2(2)=>Xbis(9),
		e2(3) => Xbis(8),
		e3 => (others => '0'),--0 0 0 0 
		e4 => Ybis(3 downto 0),--Y3 Y2 Y1 Y0
		e5 => Ybis(7 downto 4),-- Y7 Y6 Y5 Y4
		-- 0 0 Y9 Y8
		e6(0)=> '0',
		e6(1) => '0',
		e6(2)=>Ybis(9),
		e6(3) => Ybis(8), 
		e7 => (others => '0'),-- 0 0 0 0
		an =>an,
		ssg => ssg
	);

end synthesis;
