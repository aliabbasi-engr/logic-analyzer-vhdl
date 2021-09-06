library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_RX_Module is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Time_Out : integer := 100; -- in microsecond
				g_Baud_Rate : integer := 115200;
				g_Filter_Steps : integer := 10);
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			i_PC_RX_Serial : in STD_LOGIC;
			o_Command_BUS : out t_Command_BUS);
end entity PC_RX_Module;

architecture Behavioral of PC_RX_Module is

	signal s_Buffer_RD_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0);
	signal s_Buffer_RD_PORT_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_Packet_Received : STD_LOGIC;
	signal s_Packet_Size : STD_LOGIC_VECTOR(5 downto 0);

begin

	PC_RX_Packet_Handler : entity work.PC_RX_Packet_Handler
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 o_Command_BUS => o_Command_BUS,
				 o_Buffer_RD_PORT_Adress => s_Buffer_RD_PORT_Adress,
				 i_Buffer_RD_PORT_Data => s_Buffer_RD_PORT_Data,
				 i_Packet_Received => s_Packet_Received,
				 i_Packet_Size => s_Packet_Size);

	PC_Buffered_RX : entity work.PC_Buffered_RX
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Time_Out => g_Time_Out,
					 g_Baud_Rate => g_Baud_Rate,
					 g_Filter_Steps => g_Filter_Steps)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 i_PC_RX_Serial => i_PC_RX_Serial,
				 i_Buffer_RD_PORT_Adress => s_Buffer_RD_PORT_Adress,
				 o_Buffer_RD_PORT_Data => s_Buffer_RD_PORT_Data,
				 o_Packet_Received => s_Packet_Received,
				 o_Packet_Size => s_Packet_Size);	

end Behavioral;

