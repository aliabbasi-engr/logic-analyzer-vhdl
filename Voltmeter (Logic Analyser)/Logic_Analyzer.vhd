library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity Logic_Analyzer is
	generic(	g_Clock_Frequency : integer := 32_000_000;
				g_Track_Wait_Clocks : integer := 256;

				g_RX_Time_Out : integer := 100; -- in microsecond

				g_Baud_Rate : integer := 115200;
				g_Filter_Steps : integer := 10;

				g_ADC_Input_Channels : integer := 8; -- 1 to 8
				g_ADC_Resolution : integer := 12; -- 1 to 12
	
				g_LED_Blink_Time_Interval : integer := 500;
				g_LED_Number : integer := 8;

				g_Initial_Reset_Time : integer := 1_000);-- in milliseconds

    port( i_CLK : in STD_LOGIC;

			 o_PC_TX_Serial : out STD_LOGIC;
			 i_PC_RX_Serial : in  STD_LOGIC;

			 i_Switch : in  STD_LOGIC_VECTOR (2 downto 0);

			 i_ADC_MISO : in  STD_LOGIC;
			 o_ADC_MOSI : out  STD_LOGIC;
			 o_ADC_SCLK : out  STD_LOGIC;
			 o_ADC_CS   : out  STD_LOGIC;

			 o_LED : out  STD_LOGIC_VECTOR (7 downto 0);

			 o_Segment : out  STD_LOGIC_VECTOR (7 downto 0);
			 o_Display : out  STD_LOGIC_VECTOR (3 downto 0));
end Logic_Analyzer;

architecture Behavioral of Logic_Analyzer is

	signal s_CLK_32_MHz : STD_LOGIC;
	signal s_RST : STD_LOGIC;
	signal s_ADC_Data : STD_LOGIC_VECTOR(g_ADC_Resolution - 1 downto 0);
	signal s_ADC_Data_Valid : STD_LOGIC;
	signal s_Channel : STD_LOGIC_VECTOR(2 downto 0);
	signal s_Muxed_ADC_Data : STD_LOGIC_VECTOR(g_ADC_Resolution - 1 downto 0);
	signal s_Number : STD_LOGIC_VECTOR(15 downto 0);
	signal s_LED : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
	signal s_ADC_BUS : t_ADC_BUS;

begin

	s_Number <= '0' & i_Switch & s_Muxed_ADC_Data;
	o_LED <= s_LED;

	s_ADC_BUS.Valid <= s_ADC_Data_Valid;
	s_ADC_BUS.Data <= s_ADC_Data;
	s_ADC_BUS.Channel <= s_Channel;

	Communication_Center : entity work.Communication_Center
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Time_Out => g_RX_Time_Out,
					 g_Baud_Rate => g_Baud_Rate,
					 g_Filter_Steps => g_Filter_Steps)
	port map( i_CLK => s_CLK_32_MHz,
				 i_RST => s_RST,
				 o_PC_TX_Serial => o_PC_TX_Serial,
				 i_PC_RX_Serial => i_PC_RX_Serial,
				 i_LED => s_LED,
				 i_ADC_BUS => s_ADC_BUS,
				 i_Switch => i_Switch);

	ADC128S102_Driver: entity work.ADC128S102_Driver  
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Track_Wait_Clocks => g_Track_Wait_Clocks,
					 g_ADC_Input_Channels => g_ADC_Input_Channels, -- 1 to 8
					 g_ADC_Resolution => g_ADC_Resolution) -- 1 to 12
	port map( i_CLK => s_CLK_32_MHz,
				 i_RST => s_RST,
				 o_MOSI => o_ADC_MOSI,
				 o_SCLK => o_ADC_SCLK,
				 o_CS => o_ADC_CS,
				 i_MISO => i_ADC_MISO,
				 o_ADC_Data => s_ADC_Data,
				 o_ADC_Data_Valid => s_ADC_Data_Valid,
				 o_Channel => s_Channel);

	ADC_Data_Multiplexer: entity work.ADC_Data_Multiplexer
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_ADC_Resolution => g_ADC_Resolution)
	port map( i_CLK => s_CLK_32_MHz,
				 i_RST => s_RST,
				 i_Selected_Channel => i_Switch,
				 i_ADC_Data_Valid => s_ADC_Data_Valid,
				 i_ADC_Data => s_ADC_Data,
				 i_ADC_Channel => s_Channel,
				 o_Muxed_ADC_Data => s_Muxed_ADC_Data);

	LED_Driver: entity work.LED_Driver 
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Blink_Time_Interval => g_LED_Blink_Time_Interval, -- in milliseconds --
					 g_LED_Number => g_LED_Number)
	port map( i_CLK => s_CLK_32_MHz,
				 i_RST => s_RST,
				 o_LED => s_LED);

	Multi_7_Segment_Driver: entity work.Multi_7_Segment_Driver 
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Digits_Number => 4)
	port map( i_CLK => s_CLK_32_MHz,
				 i_RST => s_RST,
				 i_Number => s_Number,
				 o_Display => o_Display,
				 o_Segment => o_Segment);

	Start_UP_Handler: entity work.Start_UP_Handler 
	generic map( g_Clock_Frequency => g_Clock_Frequency,
					 g_Initial_Reset_Time => g_Initial_Reset_Time) -- in milliseconds --
	port map( i_CLK => s_CLK_32_MHz,
				 o_RST => s_RST);

	Clock_Generator : entity work.Clock_Manager
	port map( i_CLK => i_CLK,
				 o_CLK_32_MHz => s_CLK_32_MHz);

end Behavioral;