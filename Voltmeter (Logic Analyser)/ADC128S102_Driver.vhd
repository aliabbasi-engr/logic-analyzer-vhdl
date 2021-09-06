library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ADC128S102_Driver is

	generic( g_Clock_Frequency : integer := 24_000_000;
			    g_Track_Wait_Clocks : integer := 256;
			    g_ADC_Input_Channels : integer := 8;
			    g_ADC_Resolution : integer := 12);

   port( i_CLK : in  STD_LOGIC;
         i_RST : in  STD_LOGIC;
         o_MOSI : out STD_LOGIC;
         o_SCLK : out STD_LOGIC;
         o_CS   : out STD_LOGIC;
         i_MISO : in  STD_LOGIC;
         o_ADC_Data : out  STD_LOGIC_VECTOR (g_ADC_Resolution - 1 downto 0);
         o_ADC_Data_Valid : out  STD_LOGIC;
         o_Channel : out  STD_LOGIC_VECTOR (2 downto 0));
end ADC128S102_Driver;

architecture Behavioral of ADC128S102_Driver is

	type t_ADC_Channel is record
		Current : STD_LOGIC_VECTOR(2 downto 0);
		Next_CH : STD_LOGIC_VECTOR(2 downto 0);
	end record t_ADC_Channel ;
	signal r_ADC_Channel : t_ADC_Channel := ( Current => "000", Next_CH => "000");

	signal r_SCLK : STD_LOGIC := '1';
	signal r_CS : STD_LOGIC := '1';
	signal r_Bit_Counter : integer range 0 to 15 := 0;
	signal r_Input_Data_Buffer : STD_LOGIC_VECTOR(15 downto 0);
	signal r_First_Time_Flag : STD_LOGIC := '0';

begin

	process (i_CLK)
	begin
	
		if (rising_edge(i_CLK)) then
			if (i_RST = '1') then
				r_SCLK <= '1';
			else
				if (r_CS = '0') then
					r_SCLK <= not r_SCLK;
				else
					r_SCLK <= '1';
				end if ;
			end if ;
		end if ;

		if (falling_edge(i_CLK)) then
			if (i_RST = '1') then

				r_ADC_Channel.Current <= "000";
				r_ADC_Channel.Next_CH <= "000";
				r_Bit_Counter <= 0;
				r_CS <= '1';
				r_First_Time_Flag <= '0';

			else
				o_ADC_Data_Valid <= '0';

				if (r_CS = '1') then
					r_CS <= '0';

					if (r_ADC_Channel.Next_CH = STD_LOGIC_VECTOR(TO_UNSIGNED(g_ADC_Input_Channels - 1, 3))) then
						r_ADC_Channel.Next_CH <= "000";
					else
						r_ADC_Channel.Next_CH <= r_ADC_Channel.Next_CH + 1;
					end if ;

					r_ADC_Channel.Current <= r_ADC_Channel.Next_CH;

					o_ADC_Data_Valid <= r_First_Time_Flag;
					o_ADC_Data <= r_Input_Data_Buffer(11 downto 12 - g_ADC_Resolution);
					o_Channel <= r_ADC_Channel.Current;

				else

					if (r_SCLK = '1') then

						if (r_Bit_Counter < 15) then
							r_Bit_Counter <= r_Bit_Counter + 1;
						else
							r_Bit_Counter <= 0;
							r_CS <= '1';
							r_First_Time_Flag <= '1';
						end if ;

						r_Input_Data_Buffer(15 - r_Bit_Counter) <= i_MISO;

						if (r_Bit_Counter >= 1 and r_Bit_Counter <= 3) then
							o_MOSI <= r_ADC_Channel.Next_CH(3 - r_Bit_Counter);
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	o_SCLK <= r_SCLK;
	o_CS <= r_CS;

end Behavioral;