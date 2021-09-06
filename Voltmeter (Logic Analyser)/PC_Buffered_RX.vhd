library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_Buffered_RX is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Time_Out : integer := 100 ; -- in microsecond
				g_Baud_Rate : integer := 115200 ;
				g_Filter_Steps : integer := 10);
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			i_PC_RX_Serial : in STD_LOGIC;
			i_Buffer_RD_PORT_Adress : in STD_LOGIC_VECTOR(5 downto 0);
			o_Buffer_RD_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			o_Packet_Received : out STD_LOGIC;
			o_Packet_Size : out STD_LOGIC_VECTOR(5 downto 0));
end entity PC_Buffered_RX;

architecture Behavioral of PC_Buffered_RX is

	signal s_UART_RX_Data_Valid : STD_LOGIC ;
	signal s_UART_RX_Data_Byte : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_RAM_RD_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0);
	signal s_RAM_RD_PORT_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_RAM_WR_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0);
	signal s_RAM_WR_PORT_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_RAM_WR_PORT_WR_EN : STD_LOGIC;

begin

	Buffer_RAM_64 : entity work.Buffer_RAM_64
	port map( i_CLK => i_CLK,
				 i_RD_PORT_Adress => s_RAM_RD_PORT_Adress,
				 o_RD_PORT_Data   => s_RAM_RD_PORT_Data,
				 i_WR_PORT_Adress => s_RAM_WR_PORT_Adress,
				 i_WR_PORT_Data   => s_RAM_WR_PORT_Data,
				 i_WR_PORT_WR_EN  => s_RAM_WR_PORT_WR_EN);

	UART_RX_Buffer_Controller : entity work.UART_RX_Buffer_Controller
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Time_Out => g_Time_Out)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 i_UART_RX_Data_Valid => s_UART_RX_Data_Valid,
				 i_UART_RX_Data_Byte => s_UART_RX_Data_Byte,
				 o_RAM_RD_PORT_Adress => s_RAM_RD_PORT_Adress,
				 i_RAM_RD_PORT_Data => s_RAM_RD_PORT_Data,
				 o_RAM_WR_PORT_Adress => s_RAM_WR_PORT_Adress,
				 o_RAM_WR_PORT_Data => s_RAM_WR_PORT_Data,
				 o_RAM_WR_PORT_WR_EN => s_RAM_WR_PORT_WR_EN,
				 i_Buffer_RD_PORT_Adress => i_Buffer_RD_PORT_Adress,
				 o_Buffer_RD_PORT_Data => o_Buffer_RD_PORT_Data,
				 o_Packet_Received => o_Packet_Received,
				 o_Packet_Size => o_Packet_Size);

	UART_RX : entity work.UART_RX
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Baud_Rate => g_Baud_Rate,
					 g_Filter_Steps => g_Filter_Steps)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 i_UART_RX_Serial => i_PC_RX_Serial,
				 o_UART_Byte => s_UART_RX_Data_Byte,
				 o_Data_Valid => s_UART_RX_Data_Valid,
				 o_Busy => open);

end Behavioral;

