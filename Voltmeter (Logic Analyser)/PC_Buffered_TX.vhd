library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_Buffered_TX is
	generic( g_Clock_Frequency : integer := 50_000_000 ;
				g_Baud_Rate : integer := 115_200);
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			o_TX_Serial : out STD_LOGIC;
			i_Buffer_WR_PORT_Adress : in STD_LOGIC_VECTOR(5 downto 0);
			i_Buffer_WR_PORT_Data : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_Buffer_WR_PORT_WR_EN : in STD_LOGIC;
			i_Packet_Ready : in STD_LOGIC;
			i_Packet_Ending_Pointer : in STD_LOGIC_VECTOR(5 downto 0);
			o_Transmitter_Busy : out STD_LOGIC;
			o_Transmitter_Done : out STD_LOGIC);
end entity PC_Buffered_TX;

architecture Behavioral of PC_Buffered_TX is

	signal s_UART_TX_Data_Valid : STD_LOGIC;
	signal s_UART_TX_Data_Byte : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_UART_TX_Done : STD_LOGIC;
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

	UART_TX_Buffer_Controller : entity work.UART_TX_Buffer_Controller
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 o_UART_TX_Data_Valid => s_UART_TX_Data_Valid,
				 o_UART_TX_Data_Byte  => s_UART_TX_Data_Byte,
				 i_UART_TX_Done       => s_UART_TX_Done,
				 o_RAM_RD_PORT_Adress => s_RAM_RD_PORT_Adress,
				 i_RAM_RD_PORT_Data   => s_RAM_RD_PORT_Data,
				 o_RAM_WR_PORT_Adress => s_RAM_WR_PORT_Adress,
				 o_RAM_WR_PORT_Data   => s_RAM_WR_PORT_Data,
				 o_RAM_WR_PORT_WR_EN  => s_RAM_WR_PORT_WR_EN,
				 i_Buffer_WR_PORT_Adress => i_Buffer_WR_PORT_Adress,
				 i_Buffer_WR_PORT_Data   => i_Buffer_WR_PORT_Data,
				 i_Buffer_WR_PORT_WR_EN  => i_Buffer_WR_PORT_WR_EN,
				 i_Packet_Ready          => i_Packet_Ready,
				 i_Packet_Ending_Pointer => i_Packet_Ending_Pointer,
				 o_Transmitter_Busy      => o_Transmitter_Busy,
				 o_Transmitter_Done      => o_Transmitter_Done);

	UART_TX : entity work.UART_TX
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Baud_Rate => g_Baud_Rate)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 o_TX_Serial => o_TX_Serial,
				 i_TX_Data_Byte => s_UART_TX_Data_Byte,
				 i_TX_Data_Valid => s_UART_TX_Data_Valid,
				 o_Done => s_UART_TX_Done,
				 o_Busy => open);

end Behavioral;

