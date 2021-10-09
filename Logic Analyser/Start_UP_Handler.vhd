library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Start_UP_Handler is

	generic( g_Clock_Frequency : integer := 24_000_000;
			   g_Initial_Reset_Time : integer := 1_000); -- in milliseconds

   port( i_CLK : in  STD_LOGIC;
         o_RST : out  STD_LOGIC);
end Start_UP_Handler;

architecture Behavioral of Start_UP_Handler is

	signal r_RST : STD_LOGIC := '1';
	constant c_Initial_Reset_Clocks : integer := g_Clock_Frequency * (g_Initial_Reset_Time / 1_000); 
	signal r_RST_Counter : integer range 0 to c_Initial_Reset_Clocks - 1 := 0;

begin

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then
			if (r_RST_Counter < c_Initial_Reset_Clocks - 1) then
				r_RST_Counter <= r_RST_Counter + 1;
			else
				r_RST <= '0';
			end if;
		end if;
	end Process;
	
	o_RST <= r_RST;

end Behavioral;