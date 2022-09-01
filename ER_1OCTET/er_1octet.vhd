library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity er_1octet is
  port ( rst : in std_logic ;
         clk : in std_logic ;
         en : in std_logic ;
         din : in std_logic_vector (7 downto 0) ;
         miso : in std_logic ;
         sclk : out std_logic ;
         mosi : out std_logic ;
         dout : out std_logic_vector (7 downto 0) ;
         busy : out std_logic);
end er_1octet;

architecture behavioral_3 of er_1octet is

type t_etat is (repos, bit_emis, bit_recu);
  signal etat : t_etat;

begin

  process(clk, rst)
    variable cpt_bit: natural;
    variable registre : std_logic_vector(7 downto 0);

  begin

    if(rst = '0') then

      cpt_bit := 7;
      registre := (others => 'U');

      dout <= (others => '0');
		busy <= '0';
		mosi <= '0';
		sclk <= '1';

      etat <= repos;

    elsif(rising_edge(clk)) then

      case etat is

        when repos =>
      
          if(en = '1') then
				registre := din;
				cpt_bit := 7;
				mosi <= registre (cpt_bit);
				busy <= '1';
				sclk <= '0';
				etat <= bit_emis;
			 end if;
			
        when bit_emis =>
				if(cpt_bit =0)then
			 
				sclk <= '1';
				busy <= '0';
            registre(cpt_bit):= miso;
				dout <= registre;
				
				
				etat <= repos;
          elsif(cpt_bit > 0) then
				registre (cpt_bit) := miso;
				sclk <= '1'; 
				
				etat <= bit_recu;
          end if;

        when bit_recu =>
			
			sclk <= '0';
			cpt_bit := cpt_bit-1;
			mosi <= registre (cpt_bit);

			etat <= bit_emis;		
			
      end case;
    end if;
  end process;

end behavioral_3;
