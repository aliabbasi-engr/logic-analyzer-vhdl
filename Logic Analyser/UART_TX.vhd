library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_TX is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Baud_Rate : integer := 115_200);
	port(	i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			o_TX_Serial : out STD_LOGIC;
			i_TX_Data_Byte : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_TX_Data_Valid : in STD_LOGIC;
			o_Done : out STD_LOGIC;
			o_Busy : out STD_LOGIC);
end entity UART_TX;

architecture Behavioral of UART_TX is

	constant c_Clocks_Per_Bit : integer := g_Clock_Frequency / g_Baud_Rate; 

	type t_Main_State_Machine is ( State_IDLE, State_Transmit_Bits, State_Clean_UP );

	signal r_Main_State : t_Main_State_Machine := State_IDLE;
	signal r_TX_Buffer : STD_LOGIC_VECTOR(9 downto 0) := "1000000000";
	signal r_TX_Bit_Counter : integer range 0 to 9 := 0;
	signal r_Baud_Counter : integer range 0 to c_Clocks_Per_Bit - 1 := 0;
	signal r_Done : STD_LOGIC := '0';
	signal r_Busy : STD_LOGIC := '1';
	signal r_TX_Serial : STD_LOGIC := '1';

begin

	o_Busy <= r_Busy;
	o_Done <= r_Done;
	o_TX_Serial <= r_TX_Serial;

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_Done <= '0';

			if (i_RST = '1') then

				r_Main_State <= State_IDLE;
				r_TX_Bit_Counter <= 0;
				r_Baud_Counter <= 0;
				r_Busy <= '1';	
				r_TX_Serial <= '1';
				
			else
				Case r_Main_State is
				
					when State_IDLE =>
					
						r_Busy <= '0';
						if (i_TX_Data_Valid = '1') then
							r_Busy <= '1';
							r_TX_Buffer(8 downto 1) <= i_TX_Data_Byte;
							r_Main_State <= State_Transmit_Bits;
						end if ;

					when State_Transmit_Bits =>

						r_TX_Serial <= r_TX_Buffer(r_TX_Bit_Counter);
						if (r_Baud_Counter < c_Clocks_Per_Bit - 1) then
							r_Baud_Counter <= r_Baud_Counter + 1;
						else
							r_Baud_Counter <= 0;
							if (r_TX_Bit_Counter < 9) then
								r_TX_Bit_Counter <= r_TX_Bit_Counter + 1;
							else
								r_Main_State <= State_Clean_UP;
							end if;
						end if;

					when State_Clean_UP =>

						r_Done <= '1';
						r_TX_Bit_Counter <= 0;
						r_Main_State <= State_IDLE;
				
				end Case;
			end if;
		end if;
	end process;

end Behavioral;