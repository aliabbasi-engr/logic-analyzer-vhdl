library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_TX_Module is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Baud_Rate : integer := 115_200);
	port(	i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			o_PC_TX_Serial : out STD_LOGIC;
			i_LED : in  STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_ADC_BUS : in  t_ADC_BUS;
			i_Switch : in  STD_LOGIC_VECTOR(2 downto 0);
			i_Command_BUS : in  t_Command_BUS);
end entity PC_TX_Module;

architecture Behavioral of PC_TX_Module is

	signal s_Buffer_WR_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0);
	signal s_Buffer_WR_PORT_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_Buffer_WR_PORT_WR_EN : STD_LOGIC;
	signal s_Packet_Ready : STD_LOGIC;
	signal s_Packet_Ending_Pointer : STD_LOGIC_VECTOR(5 downto 0);
	signal s_Transmitter_Busy : STD_LOGIC;
	signal s_Transmitter_Done : STD_LOGIC;

begin

	PC_TX_Packet_Handler : entity work.PC_TX_Packet_Handler
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 i_LED => i_LED,
				 i_ADC_BUS => i_ADC_BUS,
				 i_Switch => i_Switch,
				 i_Command_BUS => i_Command_BUS,
				 o_Buffer_WR_PORT_Adress => s_Buffer_WR_PORT_Adress,
				 o_Buffer_WR_PORT_Data => s_Buffer_WR_PORT_Data,
				 o_Buffer_WR_PORT_WR_EN => s_Buffer_WR_PORT_WR_EN,
				 o_Packet_Ready => s_Packet_Ready,
				 o_Packet_Ending_Pointer => s_Packet_Ending_Pointer,
				 i_Transmitter_Busy => s_Transmitter_Busy,
				 i_Transmitter_Done => s_Transmitter_Done);

	PC_Buffered_TX : entity work.PC_Buffered_TX
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Baud_Rate => g_Baud_Rate)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 o_TX_Serial => o_PC_TX_Serial,
				 i_Buffer_WR_PORT_Adress => s_Buffer_WR_PORT_Adress,
				 i_Buffer_WR_PORT_Data => s_Buffer_WR_PORT_Data,
				 i_Buffer_WR_PORT_WR_EN => s_Buffer_WR_PORT_WR_EN,
				 i_Packet_Ready => s_Packet_Ready,
				 i_Packet_Ending_Pointer => s_Packet_Ending_Pointer,
				 o_Transmitter_Busy => s_Transmitter_Busy,
				 o_Transmitter_Done => s_Transmitter_Done);

end Behavioral;

