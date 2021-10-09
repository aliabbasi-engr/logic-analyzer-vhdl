-----------------------------------------------
-- __     __     ______     _                --
-- \ \   / /    |___  /    | |               --
--  \ \_/ /_ _     / / __ _| |__  _ __ __ _  --
--   \   / _` |   / / / _` | '_ \| '__/ _` | --
--    | | (_| |  / /_| (_| | | | | | | (_| | --
--    |_|\__,_| /_____\__,_|_| |_|_|  \__,_| --
--                                           --
-----------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package Project_Package is

	type t_Command_Value is record

		Return_LEDs_States     : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;
		Return_Switches_States : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;
		Return_ADC_Channel     : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;
		Return_Diag 		   : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;
		Packet_Error 		   : STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;

	end record t_Command_Value ;

	type t_Command_BUS is record

		Command : STD_LOGIC_VECTOR((8 * 2) - 1 downto 0) ;
		Valid   : STD_LOGIC ;
		Errored : STD_LOGIC ;

	end record t_Command_BUS ;

	type t_Packet_Error is record

		Size    : STD_LOGIC ;
		Header  : STD_LOGIC ;
		Footer  : STD_LOGIC ;

	end record t_Packet_Error ;

	type t_ADC_BUS is record

		Data    : STD_LOGIC_VECTOR(11 downto 0) ;
		Channel : STD_LOGIC_VECTOR(2  downto 0) ;
		Valid   : STD_LOGIC ;

	end record t_ADC_BUS ;

	type t_Header_Footer_Type is array (0 to 3) of STD_LOGIC_VECTOR((8 * 1) - 1 downto 0) ;

	constant c_Packet_Header : t_Header_Footer_Type := (X"48", X"65", X"61", X"64") ;
	----------------------------------------------------- 'H' -- 'e' -- 'a' -- 'd' -
	constant c_Packet_Footer : t_Header_Footer_Type := (X"46", X"6f", X"6f", X"74") ;
	----------------------------------------------------- 'F' -- 'o' -- 'o' -- 't' -

	constant c_Command_Value : t_Command_Value := ( Return_LEDs_States     => X"11",
													Return_Switches_States => X"22",
													Return_ADC_Channel     => X"33",
													Return_Diag 		   => X"44",
													Packet_Error 		   => X"EE"
												  );

	type t_RD_RAM_State_Machine is ( State_Set_Address,
									 State_Wait_For_Data,
									 State_Read_Data
								   );

end Project_Package;

package body Project_Package is
 
end Project_Package;
