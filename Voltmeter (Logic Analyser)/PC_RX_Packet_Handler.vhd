library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.Project_Package.ALL;

entity PC_RX_Packet_Handler is
	Port ( i_CLK : in STD_LOGIC;
			 i_RST : in STD_LOGIC;
			 o_Command_BUS : out t_Command_BUS;
			 o_Buffer_RD_PORT_Adress : out STD_LOGIC_VECTOR(5 downto 0);
			 i_Buffer_RD_PORT_Data : in  STD_LOGIC_VECTOR((8 * 1) - 1 downto 0);
			 i_Packet_Received : in STD_LOGIC;
			 i_Packet_Size : in STD_LOGIC_VECTOR(5 downto 0));
end entity PC_RX_Packet_Handler;

architecture Behavioral of PC_RX_Packet_Handler is

	type t_Main_State_Machine is ( State_IDLE, State_Check_Header, State_Check_Footer, State_Extract_Command, State_Clean_UP);

	signal r_Main_State : t_Main_State_Machine := State_IDLE;
	signal r_RD_RAM_State : t_RD_RAM_State_Machine := State_Set_Address;
	signal r_Packet_Error : t_Packet_Error := ( Size => '0', Header => '0', Footer => '0');
	signal r_Buffer_RD_PORT_Adress : STD_LOGIC_VECTOR(5 downto 0) := (Others => '0');
	signal r_Packet_Pointer : integer range 0 to 63 := 0;
	signal r_Command_BUS : t_Command_BUS := ( Command => (Others => '0'), Valid => '0', Errored => '0' );


begin

	o_Buffer_RD_PORT_Adress <= r_Buffer_RD_PORT_Adress;
	o_Command_BUS <= r_Command_BUS;

	process (i_CLK)
	begin
		if (rising_edge(i_CLK)) then

			r_Command_BUS.Valid <= '0';

			if (i_RST = '1') then
			
				r_Main_State <= State_IDLE;
				r_Packet_Error <= ( Size => '0', Header => '0', Footer => '0' );
				r_RD_RAM_State <= State_Set_Address;
				r_Packet_Pointer <= 0;
				
			else
	
				Case r_Main_State is
				
					when State_IDLE =>

						if (i_Packet_Received = '1') then
							r_Main_State <= State_Check_Header;
							if (i_Packet_Size /= 10) then
								r_Packet_Error.Size <= '1';
							end if;
						end if;
						
					when State_Check_Header =>

						Case r_RD_RAM_State is
						
							when State_Set_Address =>

								r_Buffer_RD_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_RD_RAM_State <= State_Wait_For_Data;

							when State_Wait_For_Data =>

								r_RD_RAM_State <= State_Read_Data;

							when State_Read_Data =>

								r_RD_RAM_State <= State_Set_Address;
								if r_Packet_Pointer < 3 then
									r_Packet_Pointer <= r_Packet_Pointer + 1;
								else
									r_Main_State <= State_Check_Footer;
									r_Packet_Pointer <= 6;
								end if;

								if (i_Buffer_RD_PORT_Data /= c_Packet_Header(r_Packet_Pointer)) then
									r_Packet_Error.Header <= '1';
								end if;
						end Case;

					when State_Check_Footer =>

						Case r_RD_RAM_State is
						
							when State_Set_Address =>

								r_Buffer_RD_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_RD_RAM_State <= State_Wait_For_Data;

							when State_Wait_For_Data =>

								r_RD_RAM_State <= State_Read_Data;

							when State_Read_Data =>

								r_RD_RAM_State <= State_Set_Address;
								if (r_Packet_Pointer < 9) then

									r_Packet_Pointer <= r_Packet_Pointer + 1;
								else
									r_Main_State <= State_Extract_Command;
									r_Packet_Pointer <= 4;
								end if;
								if (i_Buffer_RD_PORT_Data /= c_Packet_Footer(r_Packet_Pointer - 6)) then
									r_Packet_Error.Footer <= '1';
								end if;
						end Case;

					when State_Extract_Command =>

						Case r_RD_RAM_State is
						
							when State_Set_Address =>

								r_Buffer_RD_PORT_Adress <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Packet_Pointer, 6));
								r_RD_RAM_State <= State_Wait_For_Data;

							when State_Wait_For_Data =>

								r_RD_RAM_State <= State_Read_Data;

							when State_Read_Data =>

								r_RD_RAM_State <= State_Set_Address;

								if (r_Packet_Pointer < 5) then

									r_Packet_Pointer <= r_Packet_Pointer + 1;
								else
									r_Main_State <= State_Clean_UP;
								end if;

								Case r_Packet_Pointer is
								
									when 4 => r_Command_BUS.Command((8 * 2) - 1 downto (8 * 1)) <= i_Buffer_RD_PORT_Data;
									when 5 => r_Command_BUS.Command((8 * 1) - 1 downto (8 * 0)) <= i_Buffer_RD_PORT_Data;
									when Others => null;
								
								end Case;
						end Case;
						
					when State_Clean_UP =>

						r_Command_BUS.Valid <= '1';
						r_Command_BUS.Errored <= r_Packet_Error.Header or r_Packet_Error.Footer or r_Packet_Error.Size;
						r_Packet_Error <= ( Header => '0', Footer => '0', Size => '0' );
						r_Packet_Pointer <= 0;
						r_Main_State <= State_IDLE;
				
				end Case;
			end if;
		end if;
	end process;

end Behavioral;

