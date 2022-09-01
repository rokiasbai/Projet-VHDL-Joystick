library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity TestOpl is
end TestOpl;

architecture behavior of TestOpl is

    component MasterOpl
        port ( 
            rst : in std_logic;
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
    end component;

    component SlaveOpl
        port ( 
            sclk : in  std_logic;
            mosi : in  std_logic;
            miso : out std_logic;
            ss   : in  std_logic
        );
    end component;

    -- Inputs
    signal clk : std_logic;
    signal reset : std_logic;
    signal en : std_logic;
    signal miso : std_logic;
    signal v1 : std_logic_vector(7 downto 0);
    signal v2 : std_logic_vector(7 downto 0);

    -- Outputs
    signal busy : std_logic;
    signal sclk : std_logic;
    signal mosi : std_logic;
    signal val_nand : std_logic_vector (7 downto 0);
    signal val_nor : std_logic_vector (7 downto 0);
    signal val_xor : std_logic_vector (7 downto 0);
    signal ss : std_logic;
    
    -- References

    -- Clock period definitions
    constant clk_period : time := 20 ns;

    begin

        m: MasterOpl
        port map(
            rst => reset,
            clk => clk,
            en => en,
            v1 => v1,
            v2 => v2,
            miso => miso,
            ss   => ss,
            sclk => sclk,
            mosi => mosi,
            val_nand => val_nand,
            val_nor => val_nor,
            val_xor => val_xor,
            busy => busy
        );

        s: SlaveOpl
        port map(
            sclk  => sclk,
            mosi  => mosi,
            miso  => miso,
            ss    => ss
        );

        clk_process : process
        begin
          clk <= '0';
          wait for clk_period/2;
          clk <= '1';
          wait for clk_period/2;
        end process;

        -- Stimulus process
        stim_proc: process
        begin 

            -- hold reset state for 100 ns.
            reset <= '0';
            wait for clk_period*10; 
            reset <= '1';
            
            wait for clk_period*10;

            -- insert stimulus here
            v1 <= "01010101";
            v2 <= "10101010";
            en <= '1';
            en <=  '0';
            wait for clk_period*10;

            v1 <= "11111011";
            v2 <= "11101100";
            en <= '1';
				--résultats attendus : 1er cycle :
				--nand initial du slave : 00110011
				--nor initial du slave :11001100
				--xor initial du slave : 10100000
				--  						2ème cycle :
				--nand v1 v2 : 00010111
				--nor v1 v2 : 00000000
				--xor v1 v2 : 00010111
            wait;

        end process;
    end behavior;
