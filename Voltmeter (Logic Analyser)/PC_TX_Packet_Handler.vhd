library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_TX_Packet_Handler is
	port( i_CLK : in STD_LOGIC;
			i_RST : in STD_LOGIC;
			i_LED : in STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			i_ADC_BUS : in t_ADC_BUS;
			i_Switch : in STD_LOGIC_VECTOR(2 downto 0);
			i_Command_BUS : in t_Command_BUS;
			o_Buffer_WR_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
			o_Buffer_WR_PORT_Data : out STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			o_Buffer_WR_PORT_WR_EN : out STD_LOGIC;
			o_Packet_Ready	: out STD_LOGIC;
			o_Packet_Ending_Pointer : out STD_LOGIC_VECTOR(5 downto 0);
			i_Transmitter_Busy : in  STD_LOGIC;
			i_Transmitter_Done : in  STD_LOGIC);
end entity PC_TX_Packet_Handler;

architecture Behavioral of PC_TX_Packet_Handler is

	type t_Main_State_Machine is ( State_IDLE,
								   State_Send_ADC_Channel_Value,
								   State_Send_Swtich_States,
								   State_Send_LED_States,
								   State_Send_Diag,
								   State_Send_Packet_Error,
								   State_Clean_UP);
	type t_ADC_Data_Buffer is array (0 to 7) of STD_LOGIC_VECTOR(11 downto 0);

	signal r_Main_State : t_Main_State_Machine := State_IDLE;
	signal r_Buffer_WR_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_Buffer_WR_PORT_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) := (Others => '0');
	signal r_Buffer_WR_PORT_WR_EN : STD_LOGIC := '0';
	signal r_Packet_Ready : STD_LOGIC := '0';
	signal r_Packet_Ending_Pointer : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_Command_Data : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) := (Others => '0');
	signal r_Command_Type : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) := (Others => '0');
	signal r_Packet_Pointer : integer range 0 to 63 := 0;
	signal r_ADC_Channel_Value : t_ADC_Data_Buffer := (Others => (Others => '0'));


begin

	o_Buffer_WR_PORT_Adress <= r_Buffer_WR_PORT_Adress;
	o_Buffer_WR_PORT_Data <= r_Buffer_WR_PORT_Data;
	o_Buffer_WR_PORT_WR_EN <= r_Buffer_WR_PORT_WR_EN;
	o_Packet_Ready	<= r_Packet_Ready;
	o_Packet_Ending_Pointer <= r_Packet_Ending_Pointer;

	ADC_Data_Buffer_Process : process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then
			if (i_ADC_BUS.Valid = '1') then
				r_ADC_Channel_Value(TO_INTEGER(UNSIGNED(i_ADC_BUS.Channel))) <= i_ADC_BUS.Data;
			end if;
		end if;
	end process ADC_Data_Buffer_Process;

	Communication_Process : process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_Buffer_WR_PORT_WR_EN <= '0';
			r_Packet_Ready <= '0';

			if (i_RST = '1') then
				r_Main_State <= State_IDLE;
				r_Packet_Pointer <= 0;
				
			else	
				Case r_Main_State is
				
					when State_IDLE =>

						if (i_Command_BUS.Valid = '1') then
							r_Command_Type <= i_Command_BUS.Command((8 * 2) - 1 downto (8 * 1));
							r_Command_Data <= i_Command_BUS.Command((8 * 1) - 1 downto (8 * 0));
							
							if (i_Command_BUS.Errored = '1') then
								r_Main_State <= State_Send_Packet_Error;
							
							else
								Case i_Command_BUS.Command((8 * 2) - 1 downto (8 * 1)) is
								
									when c_Command_Value.Return_LEDs_States => r_Main_State <= State_Send_LED_States;
									when c_Command_Value.Return_Switches_States => r_Main_State <= State_Send_Swtich_States;
									when c_Command_Value.Return_ADC_Channel => r_Main_State <= State_Send_ADC_Channel_Value;
									when c_Command_Value.Return_Diag => r_Main_State <= State_Send_Diag;
									when Others => r_Main_State <= State_Send_Packet_Error;
								end Case;
							end if;
						end if;

					when State_Send_LED_States =>

						Case r_Packet_Pointer is
						
							when 0 to 3 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Header(r_Packet_Pointer);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 4 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_Command_Type;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 5 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= i_LED;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1'; 

							when 6 to 9 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Footer(r_Packet_Pointer - 6);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 10 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Packet_Ready <= '1';
								r_Packet_Ending_Pointer <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer - 1, 6));

							when Others =>

								if (i_Transmitter_Done = '1') then
									r_Main_State <= State_Clean_UP;
								end if;

						end Case;

					when State_Send_Swtich_States =>

						Case r_Packet_Pointer is
						
							when 0 to 3 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Header(r_Packet_Pointer);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 4 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_Command_Type;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 5 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= "00000" & i_Switch;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 6 to 9 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Footer(r_Packet_Pointer - 6);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 10 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Packet_Ready <= '1';
								r_Packet_Ending_Pointer <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer - 1, 6));

							when Others =>

								if (i_Transmitter_Done = '1') then
									r_Main_State <= State_Clean_UP;
								end if;
						end Case;

					when State_Send_ADC_Channel_Value =>

						Case r_Packet_Pointer is
					
							when 0 to 3 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Header(r_Packet_Pointer);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 4 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_Command_Type;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 5 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= '0' & r_Command_Data(2 downto 0) &
															r_ADC_Channel_Value(TO_INTEGER(UNSIGNED(r_Command_Data(2 downto 0))))(11 downto 8);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 6 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(TO_INTEGER(UNSIGNED(r_Command_Data(2 downto 0))))((8 * 1) - 1 downto 0);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 7 to 10 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Footer(r_Packet_Pointer - 7);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 11 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Packet_Ready <= '1';
								r_Packet_Ending_Pointer <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer - 1, 6));

							when Others =>

								if (i_Transmitter_Done = '1') then
									r_Main_State <= State_Clean_UP;
								end if;
						end Case;

					when State_Send_Diag =>

						Case r_Packet_Pointer is
						
							when 0 to 3 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Header(r_Packet_Pointer);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 4 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_Command_Type;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 5 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= i_LED;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 6 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= '0' & i_Switch & r_ADC_Channel_Value(7)(11 downto 8);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 7 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(7)((8 * 1) - 1 downto 0);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 8 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(6)(11 downto 4);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 9 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(6)(3 downto 0) & r_ADC_Channel_Value(5)(11 downto 8);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 10 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(5)((8 * 1) - 1 downto 0);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 11 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(4)(11 downto 4);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 12 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(4)(3 downto 0) & r_ADC_Channel_Value(3)(11 downto 8);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 13 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(3)((8 * 1) - 1 downto 0);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 14 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(2)(11 downto 4);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 15 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(2)(3 downto 0) & r_ADC_Channel_Value(1)(11 downto 8); 
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 16 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(1)((8 * 1) - 1 downto 0);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 17 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(0)(11 downto 4);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 18 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= r_ADC_Channel_Value(0)(3 downto 0) & "0000";
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 19 to 22 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Footer(r_Packet_Pointer - 19);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 23 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Packet_Ready <= '1';
								r_Packet_Ending_Pointer <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer - 1, 6));

							when Others =>

								if (i_Transmitter_Done = '1') then
									r_Main_State <= State_Clean_UP;
								end if;								
						end Case;

					when State_Send_Packet_Error =>

						Case r_Packet_Pointer is
						
							when 0 to 3 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Header(r_Packet_Pointer);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 4 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Command_Value.Packet_Error;
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 5 to 8 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Buffer_WR_PORT_Data <= c_Packet_Footer(r_Packet_Pointer - 5);
								r_Buffer_WR_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_Buffer_WR_PORT_WR_EN <= '1';

							when 9 =>

								r_Packet_Pointer <= r_Packet_Pointer + 1;
								r_Packet_Ready <= '1';
								r_Packet_Ending_Pointer <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer - 1, 6));

							when Others =>

								if (i_Transmitter_Done = '1') then
									r_Main_State <= State_Clean_UP;
								end if;								
						end Case;
						
					when State_Clean_UP =>

						r_Main_State <= State_IDLE;
						r_Packet_Pointer <= 0;					
				end Case;
			end if;
		end if;
	end process Communication_Process;

end Behavioral;

