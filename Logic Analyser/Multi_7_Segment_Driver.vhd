library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Multi_7_Segment_Driver is
	generic( g_Clock_Frequency : integer := 50_000_000;
			   g_Digits_Number : integer := 4);
   port( i_CLK : in  STD_LOGIC;
         i_RST : in  STD_LOGIC;
         i_Number : in  STD_LOGIC_VECTOR (4 * g_Digits_Number - 1 downto 0);
         o_Display : out  STD_LOGIC_VECTOR (g_Digits_Number - 1 downto 0);
         o_Segment : out  STD_LOGIC_VECTOR (7 downto 0));
end Multi_7_Segment_Driver;

architecture Behavioral of Multi_7_Segment_Driver is

	constant c_Refresh_Clocks : integer := g_Clock_Frequency / 1_000;
	signal r_Refresh_Counter : integer range 0 to c_Refresh_Clocks - 1 := 0;
	signal r_Display_Counter : integer range 0 to g_Digits_Number - 1 := 0;
	signal s_Multiplexed_Number : STD_LOGIC_VECTOR(3 downto 0);
	
begin

	o_Display <= not "0001" when r_Display_Counter = 3 else
				 not "0010" when r_Display_Counter = 2 else
				 not "0100" when r_Display_Counter = 1 else
				 not "1000";

	o_Segment <= not "00111111" when s_Multiplexed_Number = X"0" else
				 not "00000110" when s_Multiplexed_Number = X"1" else
				 not "01011011" when s_Multiplexed_Number = X"2" else
				 not "01001111" when s_Multiplexed_Number = X"3" else
				 not "01100110" when s_Multiplexed_Number = X"4" else
				 not "01101101" when s_Multiplexed_Number = X"5" else
				 not "01111101" when s_Multiplexed_Number = X"6" else
				 not "00000111" when s_Multiplexed_Number = X"7" else
				 not "01111111" when s_Multiplexed_Number = X"8" else
				 not "01101111" when s_Multiplexed_Number = X"9" else
				 not "01110111" when s_Multiplexed_Number = X"A" else
				 not "01111100" when s_Multiplexed_Number = X"B" else
				 not "00111001" when s_Multiplexed_Number = X"C" else
				 not "01011110" when s_Multiplexed_Number = X"D" else
				 not "01111001" when s_Multiplexed_Number = X"E" else
				 not "01110001";

	s_Multiplexed_Number <= i_Number((r_Display_Counter + 1) * 4 - 1 downto (r_Display_Counter) * 4);

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then
			if (i_RST = '1') then
				r_Display_Counter <= 0;
				r_Refresh_Counter <= 0;
			else
				if (r_Refresh_Counter < c_Refresh_Clocks - 1) then
					r_Refresh_Counter <= r_Refresh_Counter + 1;
				else
					r_Refresh_Counter <= 0;
					r_Display_Counter <= r_Display_Counter + 1;
				end if;
			end if;
		end if;
	end process;

end Behavioral;