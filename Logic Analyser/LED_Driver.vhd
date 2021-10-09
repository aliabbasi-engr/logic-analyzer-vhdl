library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LED_Driver is
	generic( g_Clock_Frequency : integer := 50_000_000;
			   g_Blink_Time_Interval : integer := 500; -- in milliseconds --
			   g_LED_Number : integer := 8);
    Port ( i_CLK : in STD_LOGIC;
           i_RST : in STD_LOGIC;
           o_LED : out STD_LOGIC_VECTOR (7 downto 0));
end LED_Driver;

architecture Behavioral of LED_Driver is

	constant c_Blink_Time_Clocks : integer := (g_Clock_Frequency / 1_000) * g_Blink_Time_Interval; 
	signal r_Blink_Timer : integer range 0 to c_Blink_Time_Clocks - 1 := 0;
	signal r_LED : STD_LOGIC_VECTOR(7 downto 0) := X"01";

begin

	process(i_CLK) is
	begin
		if (rising_edge(i_CLK)) then
			if (i_RST = '1') then
				r_LED <= X"01";
				r_Blink_Timer <= 0;
			else
				if (r_Blink_Timer < c_Blink_Time_Clocks - 1) then
					r_Blink_Timer <= r_Blink_Timer + 1;
				else
					r_Blink_Timer <= 0;
					r_LED <= r_LED(6 downto 0) & r_LED(7);
				end if;
			end if;
		end if;
	end process;

	o_LED <= r_LED;

end Behavioral;