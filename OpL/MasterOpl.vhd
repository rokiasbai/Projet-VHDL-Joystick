library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MasterOpl is
  port ( rst : in std_logic;
         clk : in std_logic;
         en : in std_logic;
         v1 : in std_logic_vector (7 downto 0);
         v2 : in std_logic_vector(7 downto 0);
         miso : in std_logic;
         ss   : out std_logic;
         sclk : out std_logic;
         mosi : out std_logic;
         val_nand : out std_logic_vector (7 downto 0);
         val_nor : out std_logic_vector (7 downto 0);
         val_xor : out std_logic_vector (7 downto 0);
         busy : out std_logic);
end MasterOpl;

architecture behavior of MasterOpl is

  type t_etat is (initialisation, attente,transmission);
  signal etat : t_etat;
  signal enbis: std_logic;--en du composant 1_er octet
  signal busybis: std_logic; --busy du composant 1_er octet
  signal dinbis : std_logic_vector(7 downto 0); --soit v1 soit v2 soit des 0
  signal doutbis : std_logic_vector(7 downto 0);--à connecter avec nand, nor, xor plus tard..
  signal busyavant : std_logic; --busybis avant chaque front montant de l'horloge

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
	

begin
	Inst_er_1octet: er_1octet PORT MAP(
			rst => rst,
			clk => clk,
			en => enbis,
			din => dinbis,
			miso => miso,
			sclk => sclk,
			mosi => mosi,
			dout => doutbis,
			busy => busybis
		);
		
	process(clk, rst)

	variable cpt_attente: natural;--compteur pour les cycles (soit 3 soit 10)
	variable num_octet_miso: natural;-- numéro d'octet échangé
	 
	begin

		if(rst = '0') then

			ss <= '1';
			val_nand <= (others => '0');
			val_nor <= (others => '0');
			val_xor <= (others => '0');
			busy <= '0';
			num_octet_miso := 0;		
			cpt_attente := 0;
	
			etat <= initialisation;
		  
		elsif(rising_edge(clk)) then

			case etat is

				when initialisation => --init de la transmission 
				 if(en = '1') then
					ss <= '0';--début du travail
					busy <= '1';
					cpt_attente := 9;--10 car première fois attente de 10 cycles
					num_octet_miso := 0;--pas d'octet échangé pour l'instant
					etat <= attente;--on passe à l'attente de 10 cycles
				 end if;
				 
				 when attente =>
					cpt_attente := cpt_attente-1;--décrémenter les cycles d'attente de 10 la 1ère fois 
					--et de 3 les autres foisjusqu'à 0
					if (cpt_attente =0) then
						num_octet_miso :=num_octet_miso +1;--dire que le premier octet a été échangé
						if(num_octet_miso =1) then
							dinbis <= v1; --si c'est le premier échange alors c'est v1 l'entrée
						elsif (num_octet_miso =2) then
							dinbis <= v2;--sinon, si c'est le 2ème échange alors c'est v2
						else
							dinbis <= (others => '0');--sinon, 8bits à 0
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
							val_nand <= doutbis; --mettre la sortie(l'op nand) du 1_er octet 
							--dans la sortie val_nand du masterOpl
							cpt_attente :=2;--vu qu'un octet a déjà été échangé (num_octet_miso =1)
							-- alors le cycle d'attente suivant est de 3
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
						
					elsif (num_octet_miso =2) then --si c'est le deuxieme échange
						enbis <= '0';--disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							val_nor <= doutbis; --mettre la sortie(l'op nor) du 1_er octet 
							--dans la sortie val_nor du masterOpl
							cpt_attente :=2;--vu que 2 octets ont maintenant déjà été échangé
							--(num_octet_miso =2) alors le cycle d'attente suivant est de 3 aussi
							etat <= attente;--retour en phase d'attente
						elsif (busybis='1' and busyavant= '0' ) then --il est entrain d'envoyer
							busyavant <='1';
						end if;
						
					else
						enbis <= '0'; --disable le composant 1_er octet
						if (busybis='0' and busyavant= '1') then --il a envoye et il envoie plus
							--il vient d'envoyer 1octet
							val_xor <= doutbis; --mettre la sortie(l'op xor) du 1_er octet 
							--dans la sortie val_xor du masterOpl
							ss <= '1';--pour dire que la transmission est terminée (3octets échangés)
							busy <='0';--le composant masterOpl n'est plus busy
							enbis <='0';--diable le composant 1_er octet
							etat <= initialisation;
						elsif (busybis='1' and busyavant= '0') then --il est entrain d'envoyer
							busyavant <='1';
						end if;
					end if;						

		end case;
	end if;
  end process;
end behavior;