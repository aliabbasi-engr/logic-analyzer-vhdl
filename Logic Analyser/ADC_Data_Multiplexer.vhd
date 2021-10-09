library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ADC_Data_Multiplexer is

	generic( g_Clock_Frequency : integer := 24_000_000;
			   g_ADC_Resolution : integer := 12);

   port( i_CLK : in  STD_LOGIC;
         i_RST : in  STD_LOGIC;
         i_Selected_Channel : in STD_LOGIC_VECTOR (2 downto 0);
         i_ADC_Data_Valid : in  STD_LOGIC;
         i_ADC_Data : in  STD_LOGIC_VECTOR (g_ADC_Resolution - 1 downto 0);
         i_ADC_Channel : in  STD_LOGIC_VECTOR (2 downto 0);
         o_Muxed_ADC_Data : out  STD_LOGIC_VECTOR (g_ADC_Resolution - 1 downto 0));
end ADC_Data_Multiplexer;

architecture Behavioral of ADC_Data_Multiplexer is

	type t_ADC_Data_Buffer is array (0 to 7) of STD_LOGIC_VECTOR(g_ADC_Resolution - 1 downto 0);
	signal r_ADC_Data_Buffer : t_ADC_Data_Buffer := (Others => (Others => '0'));

begin

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then
			if (i_RST = '1') then
				r_ADC_Data_Buffer <= (Others => (Others => '0'));
			else
				if (i_ADC_Data_Valid = '1') then
					r_ADC_Data_Buffer(TO_INTEGER(UNSIGNED(i_ADC_Channel))) <= i_ADC_Data;
				end if;
			end if;
		end if;
	end process;

	o_Muxed_ADC_Data <= r_ADC_Data_Buffer(TO_INTEGER(UNSIGNED(i_Selected_Channel)));

end Behavioral;