library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_RX is
	generic(	g_Clock_Frequency : integer := 50_000_000;
				g_Baud_Rate : integer := 115200;
				g_Filter_Steps : integer := 10);
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			i_UART_RX_Serial : in STD_LOGIC;
			o_UART_Byte : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			o_Data_Valid : out STD_LOGIC;
			o_Busy : out STD_LOGIC);
end entity UART_RX;

architecture Behavioral of UART_RX is

	constant c_Clock_Per_Bit : integer := g_Clock_Frequency / g_Baud_Rate; 

	type t_Main_State_Machine is ( State_IDLE, State_Start_Bit, State_Receiving, State_Clean_UP);
	signal r_Main_State : t_Main_State_Machine := State_IDLE;
	signal r_Byte_Buffer : STD_LOGIC_VECTOR(8 downto 0) := (Others => '0');
	signal r_Baud_Counter : integer range 0 to c_Clock_Per_Bit - 1 := 0;
	signal r_Bit_Counter : integer range 0 to 8 := 0;
	signal r_Data_Valid : STD_LOGIC := '0';
	signal r_Busy : STD_LOGIC := '0';
	signal s_Clean_UART_RX_Serial : STD_LOGIC;

begin

	o_Busy <= r_Busy;
	o_Data_Valid <= r_Data_Valid;
	o_UART_Byte  <= r_Byte_Buffer((8 * 1) - 1 downto 0);

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_Data_Valid <= '0';

			if (i_RST = '1') then

				r_Baud_Counter <= 0;
				r_Bit_Counter <= 0;
				r_Busy <= '0';
				r_Main_State <= State_IDLE;
				
			else
	
				Case r_Main_State is
					when State_IDLE =>
					
						if (s_Clean_UART_RX_Serial = '0') then
							r_Main_State <= State_Start_Bit;
							r_Busy <= '1';
						end if;

					when State_Start_Bit =>

						if (r_Baud_Counter < (c_Clock_Per_Bit / 2) - 1) then
							r_Baud_Counter <= r_Baud_Counter + 1;
						else
							r_Baud_Counter <= 0;

							if (s_Clean_UART_RX_Serial = '0') then
								r_Main_State <= State_Receiving;
							else
								r_Main_State <= State_IDLE;
							end if;
						end if;

					when State_Receiving =>

						if (r_Baud_Counter < c_Clock_Per_Bit - 1) then
							r_Baud_Counter <= r_Baud_Counter + 1;
						else
							r_Baud_Counter <= 0;
							r_Byte_Buffer <= s_Clean_UART_RX_Serial & r_Byte_Buffer(8 downto 1);

							if (r_Bit_Counter < 8) then
								r_Bit_Counter <= r_Bit_Counter + 1;
							else
								r_Bit_Counter <= 0;
								r_Main_State <= State_Clean_UP;
							end if;
						end if;

					when State_Clean_UP =>

						r_Busy <= '0';
						r_Data_Valid <= '1';
						r_Main_State <= State_IDLE;

				end Case;
				
			end if;
		end if;
	end process;

	UART_Filter_Module : entity work.UART_Filter
	generic map ( g_Clock_Frequency => g_Clock_Frequency,
					  g_Filter_Steps => g_Filter_Steps)
	port map ( i_CLK => i_CLK,
				  i_RST => i_RST,
				  i_RAW_UART_RX_Serial => i_UART_RX_Serial,
				  o_Clean_UART_RX_Serial => s_Clean_UART_RX_Serial);
				  
end Behavioral;

