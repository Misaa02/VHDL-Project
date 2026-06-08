library ieee;
use ieee.std_logic_1164.all;


entity lprs1_zad3_tb is
end entity;
 
architecture Test of lprs1_zad3_tb is
	--Inputs
   signal sCLK : std_logic := '0';
   signal sRST : std_logic := '0';
   signal sRUN : std_logic := '1';
	signal sNIGHT : std_logic := '0';
  
 	--Outputs
   signal sRED    : std_logic;
   signal sYELLOW : std_logic;
	signal sGREEN  : std_logic;
	
	signal sDIS  : std_logic_vector(1 downto 0);
	signal s7SEGM : std_logic_vector(6 downto 0);
	
	constant iCLK_PERIOD : time := 10 ns;
	
   component lprs1_zad3 is  
		port (
			iCLK 		: in  std_logic;
			iRST 		: in  std_logic;
			iRUN     : in  std_logic;
			
			oRED    : out std_logic;
			oYELLOW : out std_logic;
			oGREEN  : out std_logic;
				
			oDIS  : out std_logic_vector(1 downto 0);
			o7SEGM : out std_logic_vector(6 downto 0)
		);
   end component;

begin

   uut: lprs1_zad3 port map (
         iCLK => sCLK,
         iRST => sRST,
         iRUN => sRUN,
         oRED => sRED,

         oYELLOW => sYELLOW,
         oGREEN => sGREEN,
			oDIS => sDIS,
			o7SEGM => s7SEGM
        );
	
	--takt process
	clk_proc : process
	begin
		sCLK <= '1';
		wait for iCLK_PERIOD / 2;
		sCLK <= '0';
		wait for iCLK_PERIOD / 2;
	end process;
	
   stimulus : process
   begin

	
--reset sistema	
	sRUN <= '0';
	sRST <= '1';
	wait for 3.25 * iCLK_period;
	sRST <= '0';
		

--aktiviranje semafora
		
		sRUN <= '1';
		wait for iCLK_period;
		sRUN <= '0';
		


-- 2. ciklusa
		wait for 19 * 13 * iCLK_period;			-- RED 																																	
		wait for 1 * 13 * iCLK_period;			-- Treba uračunati još jednu sekundu gde je displej 00 pre promene stanja															
		wait for 1.5 * 12 * iCLK_period;			-- YELLOW traje 1.5s 																																
		wait for 2 * iCLK_period;					-- Vreme kada je YELLOW brojač na nuli je dva perioda takta, jer brojač dolazi do nule dva puta (prvi put kada broji sekundu, drugi kada broji pola)
		wait for 29 * 13 * iCLK_period;			-- GREEN traje 29s																																	
		wait for 1 * 12 * iCLK_period;			-- + 1s																																					
		wait for iCLK_period;						-- + 1 period takta
		wait for iCLK_period;						-- IDLE traje jedan period takta
		
		wait for 19 * 13 * iCLK_period;																																			
		wait for 1 * 13 * iCLK_period;														
		wait for 1.5 * 12 * iCLK_period;																																		
		wait for 2 * iCLK_period;					
		wait for 29 * 13 * iCLK_period;																																	
		wait for 1 * 12 * iCLK_period;																																				
		wait for iCLK_period;						
		wait for iCLK_period;						
			
--	reset sistema

		sRST <= '1';	
		wait;

		
	wait;
	
   end process;
end architecture;