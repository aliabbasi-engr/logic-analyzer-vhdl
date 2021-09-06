library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity UART_TX_Buffer_Controller is
	Port ( i_CLK : in  STD_LOGIC;
			 i_RST : in  STD_LOGIC;
			 o_UART_TX_Data_Valid : out STD_LOGIC;
			 o_UART_TX_Data_Byte : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			 i_UART_TX_Done : in  STD_LOGIC;

			 o_RAM_RD_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
			 i_RAM_RD_PORT_Data : in  STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);

			 o_RAM_WR_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
			 o_RAM_WR_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			 o_RAM_WR_PORT_WR_EN : out STD_LOGIC ;

			 i_Buffer_WR_PORT_Adress : in  STD_LOGIC_VECTOR(5 downto 0);
			 i_Buffer_WR_PORT_Data : in  STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_Buffer_WR_PORT_WR_EN : in  STD_LOGIC;
			 i_Packet_Ready : in  STD_LOGIC;
			 i_Packet_Ending_Pointer : in  STD_LOGIC_VECTOR(5 downto 0);
			 o_Transmitter_Busy : out STD_LOGIC;
			 o_Transmitter_Done : out STD_LOGIC);
end entity UART_TX_Buffer_Controller;

architecture Behavioral of UART_TX_Buffer_Controller is

	type t_Main_State_Machine is ( State_IDLE, State_Transmitting, State_Clean_UP );

	signal r_Main_State : t_Main_State_Machine := State_IDLE;

	signal r_Transmitter_Busy : STD_LOGIC := '1';
	signal r_Transmitter_Done : STD_LOGIC := '0';
	signal r_Packet_Ending_Pointer : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_RAM_RD_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_UART_TX_Data_Valid : STD_LOGIC := '0';
	signal r_UART_TX_Data_Byte : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) := (Others => '0');

begin

	o_Transmitter_Busy <= r_Transmitter_Busy;
	o_Transmitter_Done <= r_Transmitter_Done ;

	o_UART_TX_Data_Valid <= r_UART_TX_Data_Valid;
	o_UART_TX_Data_Byte <= r_UART_TX_Data_Byte;

	o_RAM_RD_PORT_Adress <= r_RAM_RD_PORT_Adress;

	o_RAM_WR_PORT_Adress <= i_Buffer_WR_PORT_Adress;
	o_RAM_WR_PORT_Data <= i_Buffer_WR_PORT_Data;
	o_RAM_WR_PORT_WR_EN <= i_Buffer_WR_PORT_WR_EN;

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_UART_TX_Data_Valid <= '0';
			r_Transmitter_Done   <= '0';

			if (i_RST = '1') then
			
				r_Main_State <= State_IDLE;
				r_RAM_RD_PORT_Adress <= (Others => '0');
				r_Transmitter_Busy <= '1';
				
			else
	
				Case r_Main_State is
				
					when State_IDLE =>

						r_Transmitter_Busy <= '0';
						if (i_Packet_Ready = '1') then
							if (i_Packet_Ending_Pointer = "000000") then
								r_Main_State <= State_Clean_UP;
							else
								r_Main_State <= State_Transmitting;
							end if;
							r_Transmitter_Busy <= '1';
							r_Packet_Ending_Pointer <= i_Packet_Ending_Pointer;
							r_UART_TX_Data_Byte <= i_RAM_RD_PORT_Data;
							r_UART_TX_Data_Valid <= '1';
							r_RAM_RD_PORT_Adress <= r_RAM_RD_PORT_Adress + 1;
						end if;

					when State_Transmitting =>

						if (i_UART_TX_Done = '1') then
							r_UART_TX_Data_Byte <= i_RAM_RD_PORT_Data;
							r_UART_TX_Data_Valid <= '1';
							r_RAM_RD_PORT_Adress <= r_RAM_RD_PORT_Adress + 1;
							if (r_RAM_RD_PORT_Adress = r_Packet_Ending_Pointer) then
								r_Main_State <= State_Clean_UP;
							end if;
						end if;

					when State_Clean_UP =>

						if (i_UART_TX_Done = '1') then
							r_Main_State <= State_IDLE;
							r_RAM_RD_PORT_Adress <= (Others => '0');
							r_Transmitter_Done <= '1';
						end if;						
				end Case;
			end if;
		end if;
	end process;
	
end Behavioral;

