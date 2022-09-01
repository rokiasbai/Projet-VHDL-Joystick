library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MasterJoystick is
  port ( rst : in std_logic;
         clk : in std_logic;
         en : in std_logic;
         miso : in std_logic;
			led1 : in std_logic; --1ère led du joystick
			led2 : in std_logic;-- 2ème led du joystick
			X: out std_logic_vector(9 downto 0);--X
			Y: out std_logic_vector(9 downto 0);--Y
			btn1: out std_logic;--1er bouton du joystick
			btn2: out std_logic;--2ème bouton du joystick
			joystick: out std_logic;--etat du joystick
         ss   : out std_logic;
         sclk : out std_logic;
         mosi : out std_logic;
         busy : out std_logic);
end MasterJoystick;

architecture behavior of MasterJoystick is

  type t_etat is (initialisation, attente,transmission);
  --voir shéma de l'automate dans le dossier schémas
  signal etat : t_etat;
  signal enbis: std_logic;
  signal busybis: std_logic;
  signal dinbis : std_logic_vector(7 downto 0); 
  signal doutbis : std_logic_vector(7 downto 0);
  signal busyavant : std_logic;
  signal nouvelleclk :std_logic;--le signal qui connecte le diviseur d'horloge et le masterjoystick

  COMPONENT er_1octet
	PORT(
		rst : IN std_logic;
		clk : IN std_logic;
		en : IN std_logic;
		din : IN std_logic_vector(7 downto 0);
		miso : IN std_logic;          
		sclk : OUT std_logic;
		mosi : OUT std_logic;
		dout : OUT std_logic_vector(7 downto 0);
		busy : OUT std_logic
		);
	END COMPONENT;
	
  component diviseurClk is
    generic(facteur : natural);
    port (
      clk, reset : in  std_logic;
      nclk       : out std_logic);
  end component;

begin
	Inst_er_1octet: er_1octet PORT MAP(
			rst => rst,
			clk => nouvelleclk,
			en => enbis,
			din => dinbis,
			miso => miso,
			sclk => sclk,
			mosi => mosi,
			dout => doutbis,
			busy => busybis
		);
	 Inst_diviseurClk: diviseurClk GENERIC MAP(facteur => 100)PORT MAP(
			clk => clk,
			reset => rst,
			nclk => nouvelleclk
  );
	process(nouvelleclk, rst)--process avec la nouvelle clk

	variable cpt_attente: natural;--compteur pour les cycles (soit 15 soit 10)
	variable num_octet_miso: natural;-- numéro d'octet échangé( de 0 à 5)
	 
	begin

		if(rst = '0') then

			ss <= '1';
			busy <= '0';
			num_octet_miso := 0;		
			cpt_attente := 0;
			X <=(others => '0');
			Y <=(others => '0');
			btn1 <='0';
			btn2 <='0';
			joystick <='0';
	
			etat <= initialisation;
		  
		elsif(rising_edge(nouvelleclk)) then

			case etat is

				 when initialisation => --init de la transmission 
				 if(en = '1') then
					ss <= '0';--début du travail
					busy <= '1';
					cpt_attente := 14;--15 car première fois attente de 15 cycles
					num_octet_miso := 0;--pas d'octet échangé pour l'instant
					etat <= attente;--on passe à l'attente de 10 cycles
				 end if;
					
					when attente =>
					cpt_attente := cpt_attente-1;--décrémenter les cycles d'attente de 15 la 1ère fois 
					--et de 3 les autres fois jusqu'à 0
					if (cpt_attente =0) then
						num_octet_miso :=num_octet_miso +1;--dire que le premier octet a été échangé
						if(num_octet_miso =1) then
							dinbis <= (0 => led1, 1 => led2, 2 to 6  => '0', 7 => '1'); 
							--1er bit envoyé : led1 led2 00000 1
						elsif (num_octet_miso =2) then
							dinbis <= (others => '0');
							--2ème bit envoyé : 00000000
						elsif(num_octet_miso =3) then
							dinbis <= (others => '0');
							--3ème bit envoyé : 00000000
						elsif(num_octet_miso =4) then
							dinbis <= (others => '0');
							--4ème bit envoyé : 00000000
						else
							dinbis <= (others => '0');--sinon, 8bits à 0 encore
						end if;
					enbis <= '1';--enable le composant 1_er octet
					busyavant <= '0';
					etat <= transmission;--passer à la phase de transmission
					end if;
						
				when transmission =>
					if (num_octet_miso =1) then --si c'est le premier échange
						enbis <= '0';--disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							X(7 downto 0) <= doutbis;
							cpt_attente :=9;--vu qu'un octet a déjà été échangé (num_octet_miso =1)
							-- alors le cycle d'attente suivant est de 10
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
						
					elsif (num_octet_miso =2) then --si c'est le deuxieme échange
						enbis <= '0';--disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							X(8)<= doutbis(0);
							X(9) <= doutbis(1);
							cpt_attente :=9;--vu que 2 octets ont maintenant déjà été échangé
							--(num_octet_miso =2) alors le cycle d'attente suivant est de 10 aussi
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
						
					elsif (num_octet_miso =3) then --si c'est le 3ème échange
						enbis <= '0';--disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							Y(7 downto 0) <= doutbis;
							cpt_attente :=9;--vu que 3 octets ont maintenant déjà été échangé
							--(num_octet_miso =3) alors le cycle d'attente suivant est de 10 aussi
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
					
					elsif (num_octet_miso =4) then --si c'est le quatrième échange
						enbis <= '0';--disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							 Y(8)<= doutbis(0); 
							 Y(9) <= doutbis(1);
							cpt_attente :=9;--vu que 4 octets ont maintenant déjà été échangé
							--(num_octet_miso =4) alors le cycle d'attente suivant est de 10 aussi
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
						
					else
						enbis <= '0'; --disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							--la sortie va etre de la forme : joystick btn1 btn2 00000
							joystick <= doutbis(0); 
							btn1 <= doutbis(1);
							btn2 <= doutbis (2);
							--'00000' <= doutbis (4 downto 0);
							ss <= '1';--pour dire que la transmission est terminée (5 octets échangés)
							busy <='0';--le composant masterJoystick n'est plus busy
							enbis <='0';--disable le composant 1_er octet
							etat <= initialisation;
						elsif (busybis='1' and busyavant= '0') then --il est entrain d'envoyer
							busyavant <='1';
						end if;
					end if;

		end case;
	end if;
  end process;
end behavior;
