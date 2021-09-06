library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Filter is
	generic(	g_Clock_Frequency : integer := 50_000_000;
				g_Filter_Steps : integer := 10);
	port( i_CLK, i_RST : in  STD_LOGIC;
			i_RAW_UART_RX_Serial : in  STD_LOGIC;
			o_Clean_UART_RX_Serial : out STD_LOGIC);
end entity UART_Filter;

architecture Behavioral of UART_Filter is

	type t_Filter_Counters is record
		Ones  : integer range 0 to g_Filter_Steps - 1;
		Zeros : integer range 0 to g_Filter_Steps - 1;
	end record t_Filter_Counters;

	signal r_Filter_Counter : t_Filter_Counters := (Ones => 0, Zeros => 0);

begin

	o_Clean_UART_RX_Serial <= '1' when r_Filter_Counter.Ones >= r_Filter_Counter.Zeros else '0';

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then
		
			if (i_RST = '1') then
				r_Filter_Counter <= ( Ones  => 0, Zeros => 0);
				
			else
				
				if (i_RAW_UART_RX_Serial = '1') then
					
					if (r_Filter_Counter.Ones < g_Filter_Steps - 1) then
						r_Filter_Counter.Ones <= r_Filter_Counter.Ones + 1;
					end if;

					if (r_Filter_Counter.Zeros > 0) then
						r_Filter_Counter.Zeros <= r_Filter_Counter.Zeros - 1;
					end if ;
				
				else

					if (r_Filter_Counter.Zeros < g_Filter_Steps - 1) then
						r_Filter_Counter.Zeros <= r_Filter_Counter.Zeros + 1;
					end if ;

					if (r_Filter_Counter.Ones > 0) then
						r_Filter_Counter.Ones <= r_Filter_Counter.Ones - 1;
					end if;
				end if;
			end if;
		end if;
	end process;	

end Behavioral;

