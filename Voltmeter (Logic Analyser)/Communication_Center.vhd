library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity Communication_Center is
	generic( g_Clock_Frequency : integer := 50_000_000;
				g_Time_Out : integer := 100; -- in microsecond
				g_Baud_Rate : integer := 115200;
				g_Filter_Steps : integer := 10);
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			o_PC_TX_Serial : out STD_LOGIC;
			i_PC_RX_Serial : in STD_LOGIC;
			i_LED : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_ADC_BUS : in t_ADC_BUS;
			i_Switch : in STD_LOGIC_VECTOR(2 downto 0));
end entity Communication_Center;

architecture Behavioral of Communication_Center is

	signal s_Command_BUS : t_Command_BUS;

begin

	PC_TX_Module : entity work.PC_TX_Module
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Baud_Rate => g_Baud_Rate)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 o_PC_TX_Serial => o_PC_TX_Serial,
				 i_LED => i_LED,
				 i_ADC_BUS => i_ADC_BUS,
				 i_Switch => i_Switch,
				 i_Command_BUS => s_Command_BUS);

	PC_RX_Module : entity work.PC_RX_Module
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Time_Out => g_Time_Out,
					 g_Baud_Rate => g_Baud_Rate,
					 g_Filter_Steps => g_Filter_Steps)
	port map( i_CLK => i_CLK,
				 i_RST => i_RST,
				 i_PC_RX_Serial => i_PC_RX_Serial,
				 o_Command_BUS => s_Command_BUS);
	
end Behavioral;

