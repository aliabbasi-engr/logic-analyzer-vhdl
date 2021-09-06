library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity UART_RX_Buffer_Controller is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Time_Out : integer := 100); -- in microsecond
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;

		i_UART_RX_Data_Valid : in STD_LOGIC;
		i_UART_RX_Data_Byte : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);

		o_RAM_RD_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
		i_RAM_RD_PORT_Data : in  STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);

		o_RAM_WR_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
		o_RAM_WR_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
		o_RAM_WR_PORT_WR_EN : out STD_LOGIC;

		i_Buffer_RD_PORT_Adress : in  STD_LOGIC_VECTOR(5 downto 0);
		o_Buffer_RD_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
		o_Packet_Received : out STD_LOGIC;
		o_Packet_Size : out STD_LOGIC_VECTOR(5 downto 0));
end entity UART_RX_Buffer_Controller;

architecture Behavioral of UART_RX_Buffer_Controller is

	constant c_Clocks_Per_Timeout : integer := (g_Clock_Frequency / 1_000_000) * g_Time_Out; 

	type t_Main_State_Machine is ( State_IDLE, State_Receiving, State_Clean_UP );
	signal r_Main_State : t_Main_State_Machine := State_IDLE;

	signal r_Packet_Counter : integer range 0 to 63 := 0;

	signal r_RAM_WR_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_RAM_WR_PORT_WR_EN : STD_LOGIC := '0';

	signal r_Packet_Received : STD_LOGIC := '0';
	signal r_Packet_Size : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');

	signal r_Timeout_Counter : integer range 0 to c_Clocks_Per_Timeout - 1 := 0;

begin

	o_RAM_WR_PORT_Adress <= r_RAM_WR_PORT_Adress;
	o_RAM_WR_PORT_Data <= i_UART_RX_Data_Byte;
	o_RAM_WR_PORT_WR_EN <= r_RAM_WR_PORT_WR_EN;

	o_Packet_Size <= r_Packet_Size;
	o_Packet_Received <= r_Packet_Received;

	o_RAM_RD_PORT_Adress <= i_Buffer_RD_PORT_Adress;
	o_Buffer_RD_PORT_Data <= i_RAM_RD_PORT_Data;

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_RAM_WR_PORT_WR_EN <= '0';
			r_Packet_Received <= '0';

			if (i_RST = '1') then
				r_Main_State <= State_IDLE;
				r_Packet_Counter <= 0;
				r_Timeout_Counter <= 0;
			
			else
	
				Case r_Main_State is
				
					when State_IDLE =>

						if (i_UART_RX_Data_Valid = '1') then

							r_RAM_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Counter, 6));
							r_RAM_WR_PORT_WR_EN <= '1';
							r_Packet_Counter <= r_Packet_Counter + 1;
							r_Main_State <= State_Receiving;
							
						end if ;

					when State_Receiving =>

						if (r_Timeout_Counter < c_Clocks_Per_Timeout - 1) then
						
							if (i_UART_RX_Data_Valid = '1') then
							
								r_Timeout_Counter <= 0;
								r_RAM_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Counter, 6));
								r_RAM_WR_PORT_WR_EN <= '1';
								if (r_Packet_Counter < 63) then
									r_Packet_Counter <= r_Packet_Counter + 1;
								else
									r_Main_State <= State_Clean_UP;
								end if;
								
							else
								r_Timeout_Counter <= r_Timeout_Counter + 1;
							end if;
							
						else
							r_Main_State <= State_Clean_UP;
						end if ;

					when State_Clean_UP =>

						r_Packet_Size <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Counter, 6));
						r_Packet_Received <= '1';
						r_Main_State <= State_IDLE;
						r_Packet_Counter <= 0;
						r_Timeout_Counter <= 0;
				
				end Case ;
			end if ;
		end if ;
	end process;
	

end Behavioral;

