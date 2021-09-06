library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity Buffer_RAM_64 is
	port( i_CLK : in  STD_LOGIC;
			i_RD_PORT_Adress : in  STD_LOGIC_VECTOR(5 downto 0);
			o_RD_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_WR_PORT_Adress : in STD_LOGIC_VECTOR(5 downto 0);
			i_WR_PORT_Data : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_WR_PORT_WR_EN : in STD_LOGIC);
end entity Buffer_RAM_64;

architecture Behavioral of Buffer_RAM_64 is

begin

	RAM_64_Core : entity work.RAM_64_Core
	port map ( clk => i_CLK, -- input CLK
				  a => i_WR_PORT_Adress, -- WR Adress
				  d => i_WR_PORT_Data, -- WR Data
				  we => i_WR_PORT_WR_EN, -- WR EN
				  dpra => i_RD_PORT_Adress, -- RD Adress
				  dpo => o_RD_PORT_Data); -- RD Data

end Behavioral;

