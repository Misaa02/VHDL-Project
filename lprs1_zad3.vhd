-------------------------------------------------------------
-- Ime i prezime: Milos Vukosavljevic 
-- Broj indeksa: RA213/2024
-- Grupa na vežbama: 13
-- Asistent: Teodora Novkovic
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;

entity lprs1_zad3 is
	port (	
				iCLK	  : in  std_logic;
				iRST    : in  std_logic;
				iRUN    : in  std_logic;
				
				oRED    : out std_logic;
				oYELLOW : out std_logic;
				oGREEN  : out std_logic;
				
				oDIS    : out std_logic_vector(1 downto 0);
				o7SEGM  : out std_logic_vector(6 downto 0)
		);
end entity;

architecture Behavioral of lprs1_zad3 is

type tSTATE is (IDLE, RED,  YELLOW, GREEN, ERROR);
signal sSTATE, sNEXT_STATE : tSTATE;

signal sRED_UNITS_CNT	: std_logic_vector(3 downto 0);
signal sRED_TENS_CNT		: std_logic_vector(3 downto 0);
signal sRED_PREV_CNT		: std_logic_vector(3 downto 0);
signal sRED_TENS_EN		: std_logic;
signal sRED_DONE			: std_logic;

signal sGREEN_UNITS_CNT	: std_logic_vector(3 downto 0);
signal sGREEN_TENS_CNT	: std_logic_vector(3 downto 0);
signal sGREEN_PREV_CNT	: std_logic_vector(3 downto 0);
signal sGREEN_TENS_EN	: std_logic;
signal sGREEN_DONE		: std_logic;

constant cSECOND			: std_logic_vector(23 downto 0):="000000000000000000001100"; --  --000000000000000000001100 101101110001101100000000

signal sRED_TIMER			: std_logic_vector(23 downto 0);
signal sRED_COUNT_EN		: std_logic;

signal sGREEN_TIMER		: std_logic_vector(23 downto 0);
signal sGREEN_COUNT_EN	: std_logic;

signal sYELLOW_CNT		: std_logic_vector(23 downto 0);
signal sYELLOW_TC			: std_logic;
constant cYELLOW_TIME 	: std_logic_vector(23 downto 0) := cSECOND + ('0' & cSECOND(23 downto 1)); -- 1 i po sekunda

signal sYELLOW_FROM_GREEN		: std_logic; -- '1' ako smo u YELLOW usli iz GREEN, inace iz RED

signal sRUN					: std_logic;
signal sCURRENT_STATE	: std_logic;
signal sPREV_STATE		: std_logic;

-- ==================== PRIKAZ NA DISPLAJU ====================
signal sTC					: std_logic;  -- dozvole za displej
signal sDIS_SEL 			: std_logic_vector(1 downto 0);
signal sDIS_CNT 			: std_logic_vector(14 downto 0);
constant cDIS_MAX			: std_logic_vector(14 downto 0) := "111111111111111";

signal sDISPLAY_0			: std_logic_vector(6 downto 0);
signal sDISPLAY_1			: std_logic_vector(6 downto 0);
signal sDISPLAY_2			: std_logic_vector(6 downto 0);
signal sDISPLAY_3			: std_logic_vector(6 downto 0);

-- ukoliko je brojač neaktivan da li se njegova vrijednost šalje na prikaz ili je displej isključen
signal sRED_TENS_DISPLAY	: std_logic_vector(3 downto 0); 
signal sRED_UNITS_DISPLAY	: std_logic_vector(3 downto 0); 
signal sGREEN_TENS_DISPLAY	: std_logic_vector(3 downto 0);
signal sGREEN_UNITS_DISPLAY	: std_logic_vector(3 downto 0);

signal sRED_UNITS_EN : std_logic;
signal sGREEN_UNITS_EN : std_logic;
signal sYELLOW_COUNT_EN : std_logic;

begin
-- sPrev state registar
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sPREV_STATE <= '0';
		elsif(rising_edge(iCLK)) then
			sPREV_STATE <= iRUN;
		end if;
	end process;
	
	sRUN <= '1' when (sPREV_STATE = '0' and iRUN = '1') else '0';

-- sCurrent state registar
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sCURRENT_STATE <= '0';
		elsif(rising_edge(iCLK)) then
			if(sRUN = '1') then
				sCURRENT_STATE <= sRUN;
			else
				sCURRENT_STATE <= sCURRENT_STATE;
			end if;
		end if;
	end process;
	
-- Dozvola za crvenog svetlo
	sRED_COUNT_EN <= '1' when (sCURRENT_STATE = '1' and sSTATE = RED) else '0';
	
-- Red timer
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sRED_TIMER <= (others => '0');
		elsif(rising_edge(iCLK)) then
			if(sRED_COUNT_EN = '1') then
				if(sRED_TIMER = cSECOND - 1) then
					sRED_TIMER <= (others => '0');
				else
					sRED_TIMER <= sRED_TIMER + 1;
				end if;
			else
				sRED_TIMER <= (others => '0');
			end if;
		end if;
	end process;
	
	sRED_UNITS_EN <= '1' when sRED_TIMER = cSECOND else '0';
	
	sGREEN_COUNT_EN <= '1' when (sCURRENT_STATE = '1' and sSTATE = GREEN) else '0'; 
	
-- Green timer
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sGREEN_TIMER <= (others => '0');
		elsif(rising_edge(iCLK)) then
			if(sGREEN_COUNT_EN = '1') then
				if(sGREEN_TIMER = cSECOND - 1) then
					sGREEN_TIMER <= (others => '0');
				else
					sGREEN_TIMER <= sGREEN_TIMER + 1;
				end if;
			else
				sGREEN_TIMER <= (others => '0');
			end if;
		end if;
	end process;
	
	sGREEN_UNITS_EN <= '1' when sGREEN_TIMER = cSECOND else '0';
	
-- Brojac jedinica crvenog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sRED_UNITS_CNT <= "1001";
		elsif(rising_edge(iCLK)) then
			if((sSTATE /= RED) and (sNEXT_STATE = RED)) then
				sRED_UNITS_CNT <= "1001";
			elsif(sRED_UNITS_EN = '1') then
				if(sRED_UNITS_CNT = "0000") then
					sRED_UNITS_CNT <= "1001";
				else
					sRED_UNITS_CNT <= sRED_UNITS_CNT - 1;
				end if;
			end if;
		end if;
	end process;
	
-- Brojac desetica crvenog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sRED_TENS_CNT <= "0001";
		elsif(rising_edge(iCLK)) then
			if((sSTATE /= RED) and (sNEXT_STATE = RED)) then
				sRED_TENS_CNT <= "0001";
			elsif(sRED_TENS_EN = '1') then
				if(sRED_TENS_CNT = "0000") then
					sRED_TENS_CNT <= "0001";
				else
					sRED_TENS_CNT <= sRED_TENS_CNT - 1;
				end if;
			end if;
		end if;
	end process;
	
-- Uslov isteka odbrojavanja crvenog svetla
	sRED_DONE <= '1' when (sRED_UNITS_CNT = 0 and sRED_TENS_CNT = "0000") else '0';
	
-- Registar prethodne vrednosti jedinica crveog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sRED_PREV_CNT <= (others => '0');
		elsif(rising_edge(iCLK)) then
			if(sSTATE = IDLE) then
				sRED_PREV_CNT <= "1001";
			else
				sRED_PREV_CNT <= sRED_UNITS_CNT;
			end if;
		end if;
	end process;
	
-- Dozvola za brojac desetica crvenog svetla
	sRED_TENS_EN <= '1' when (sRED_PREV_CNT = "0000" and sRED_UNITS_CNT = "1001") else '0';

-- Brojac jedinica zelenog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sGREEN_UNITS_CNT <= "1001";
		elsif(rising_edge(iCLK)) then
			if(sSTATE = IDLE) then
				sGREEN_UNITS_CNT <= "1001";
			elsif(sGREEN_UNITS_EN = '1') then
				if(sGREEN_UNITS_CNT = "0000") then
					sGREEN_UNITS_CNT <= "1001";
				elsif(sGREEN_DONE = '0') then
					sGREEN_UNITS_CNT <= sGREEN_UNITS_CNT - 1;
				end if;
			end if;
		end if;
	end process;
	
-- Registar prethodne vrednosti jedinica zelenog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sGREEN_PREV_CNT <= (others => '0');
		elsif(rising_edge(iCLK)) then
			sGREEN_PREV_CNT <= sGREEN_UNITS_CNT;
		end if;
	end process;
	
-- Dozvola za brojac desetica zelenog svetla
	sGREEN_TENS_EN <= '1' when (sGREEN_PREV_CNT = "0000" and sGREEN_UNITS_CNT = "1001") else '0';
	

	
-- Brojac desetica zelenog svetla
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sGREEN_TENS_CNT <= "0010";
		elsif(rising_edge(iCLK)) then
			if(sSTATE = IDLE) then
				sGREEN_TENS_CNT <= "0010";
			elsif(sGREEN_TENS_EN = '1') then
				if(sGREEN_TENS_CNT = "0000") then
					sGREEN_TENS_CNT <= "0010";
				else
					sGREEN_TENS_CNT <= sGREEN_TENS_CNT - 1;
				end if;
			end if;
		end if;
	end process;
	
-- Uslov isteka odbrojavanja zelenog svetla
	sGREEN_DONE <= '1' when (sGREEN_TENS_CNT = "0000" and sGREEN_UNITS_CNT = "0000") else '0';
	
	sYELLOW_COUNT_EN <= '1' when (sCURRENT_STATE = '1' and sSTATE = YELLOW) else '0';
	
	
-- Yellow timer
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sYELLOW_CNT <= (others => '0');
		elsif(rising_edge(iCLK)) then
			if(sYELLOW_COUNT_EN = '1') then
				if(sYELLOW_CNT = cYELLOW_TIME - 1) then
					sYELLOW_CNT <= (others => '0');
				else
					sYELLOW_CNT <= sYELLOW_CNT + 1;
				end if;
			else
				sYELLOW_CNT <= (others => '0');
			end if;
		end if;
	end process;
	
	sYELLOW_TC <= '1' when sYELLOW_CNT = cYELLOW_TIME else '0';
	
-- Registar stanja
	process(iCLK, iRST) begin
		 if iRST = '1' then
			  sSTATE <= IDLE;
		 elsif rising_edge(iCLK) then
			  sSTATE <= sNEXT_STATE;
		 end if;
	end process;
	
-- Funkcija prelaza stanja
	process(sSTATE, sCURRENT_STATE, sRED_DONE, sGREEN_DONE, sYELLOW_TC) begin
		sNEXT_STATE <= sSTATE;
		
		case sSTATE is
			when IDLE =>
				if(sCURRENT_STATE = '1') then
					sNEXT_STATE <= RED;
				else
					sNEXT_STATE <= sSTATE;
				end if;
			
			when RED =>
				if(sRED_DONE = '1') then
					sNEXT_STATE <= YELLOW;
				else
					sNEXT_STATE <= sSTATE;
				end if;
				
			when GREEN =>
				if(sGREEN_DONE = '1') then
					sNEXT_STATE <= IDLE;
				else
					sNEXT_STATE <= sSTATE;
				end if;
				
			when YELLOW =>
				if(sYELLOW_TC = '1') then
						sNEXT_STATE <= GREEN;
				else
					sNEXT_STATE <= sSTATE;
				end if;
		
			when others =>
				sNEXT_STATE <= ERROR;
		end case;
	end process;
	
-- Dekoder za 7-segmentni displej
	
process(iCLK, iRST) 
begin
    if sRED_UNITS_DISPLAY = "0000" then 
		  sDISPLAY_0 <= "0000001";
    elsif sRED_UNITS_DISPLAY = "0001" then
        sDISPLAY_0 <= "1001111";
    elsif sRED_UNITS_DISPLAY = "0010" then
        sDISPLAY_0 <= "0010010";
    elsif sRED_UNITS_DISPLAY = "0011" then
        sDISPLAY_0 <= "0000110";
    elsif sRED_UNITS_DISPLAY = "0100" then
        sDISPLAY_0 <= "1001100";
    elsif sRED_UNITS_DISPLAY = "0101" then
        sDISPLAY_0 <= "0100100";
    elsif sRED_UNITS_DISPLAY = "0110" then
        sDISPLAY_0 <= "0100000";
    elsif sRED_UNITS_DISPLAY = "0111" then
        sDISPLAY_0 <= "0001111";
    elsif sRED_UNITS_DISPLAY = "1000" then
        sDISPLAY_0 <= "0000000";
    elsif sRED_UNITS_DISPLAY = "1001" then
        sDISPLAY_0 <= "0000100";
    else
        sDISPLAY_0 <= "1111111";  -- default za nevalidne ulaze
    end if;
end process;

	
	
	process(iCLK, iRST) 
begin
    if sRED_UNITS_DISPLAY = "0000" then
        sDISPLAY_1 <= "0000001";
    elsif sRED_UNITS_DISPLAY = "0001" then
        sDISPLAY_1 <= "1001111";
    elsif sRED_UNITS_DISPLAY = "0010" then
        sDISPLAY_1 <= "0010010";
    elsif sRED_UNITS_DISPLAY = "0011" then
        sDISPLAY_1 <= "0000110";
    elsif sRED_UNITS_DISPLAY = "0100" then
        sDISPLAY_1 <= "1001100";
    elsif sRED_UNITS_DISPLAY = "0101" then
        sDISPLAY_1 <= "0100100";
    elsif sRED_UNITS_DISPLAY = "0110" then
        sDISPLAY_1 <= "0100000";
    elsif sRED_UNITS_DISPLAY = "0111" then
        sDISPLAY_1 <= "0001111";
    elsif sRED_UNITS_DISPLAY = "1000" then
        sDISPLAY_1 <= "0000000";
    elsif sRED_UNITS_DISPLAY = "1001" then
        sDISPLAY_1 <= "0000100";
    else
        sDISPLAY_1 <= "1111111";  -- default za nevalidne ulaze
    end if;
end process;

	
	process(iCLK, iRST) 
begin
    if sRED_UNITS_DISPLAY = "0000" then
        sDISPLAY_2 <= "0000001";
    elsif sRED_UNITS_DISPLAY = "0001" then
        sDISPLAY_2 <= "1001111";
    elsif sRED_UNITS_DISPLAY = "0010" then
        sDISPLAY_2 <= "0010010";
    elsif sRED_UNITS_DISPLAY = "0011" then
        sDISPLAY_2 <= "0000110";
    elsif sRED_UNITS_DISPLAY = "0100" then
        sDISPLAY_2 <= "1001100";
    elsif sRED_UNITS_DISPLAY = "0101" then
        sDISPLAY_2 <= "0100100";
    elsif sRED_UNITS_DISPLAY = "0110" then
        sDISPLAY_2 <= "0100000";
    elsif sRED_UNITS_DISPLAY = "0111" then
        sDISPLAY_2 <= "0001111";
    elsif sRED_UNITS_DISPLAY = "1000" then
        sDISPLAY_2 <= "0000000";
    elsif sRED_UNITS_DISPLAY = "1001" then
        sDISPLAY_2 <= "0000100";
    else
        sDISPLAY_2 <= "1111111";  -- default za nevalidne ulaze
    end if;
end process;

	
process(iCLK, iRST) 
begin
    if sRED_UNITS_DISPLAY = "0000" then
        sDISPLAY_3 <= "0000001";
    elsif sRED_UNITS_DISPLAY = "0001" then
        sDISPLAY_3 <= "1001111";
    elsif sRED_UNITS_DISPLAY = "0010" then
        sDISPLAY_3 <= "0010010";
    elsif sRED_UNITS_DISPLAY = "0011" then
        sDISPLAY_3 <= "0000110";
    elsif sRED_UNITS_DISPLAY = "0100" then
        sDISPLAY_3 <= "1001100";
    elsif sRED_UNITS_DISPLAY = "0101" then
        sDISPLAY_3 <= "0100100";
    elsif sRED_UNITS_DISPLAY = "0110" then
        sDISPLAY_3 <= "0100000";
    elsif sRED_UNITS_DISPLAY = "0111" then
        sDISPLAY_3 <= "0001111";
    elsif sRED_UNITS_DISPLAY = "1000" then
        sDISPLAY_3 <= "0000000";
    elsif sRED_UNITS_DISPLAY = "1001" then
        sDISPLAY_3 <= "0000100";
    else
        sDISPLAY_3 <= "1111111";  -- default za nevalidne ulaze
    end if;
end process;

	
-- vrednosti koje idu na displej	
	sRED_UNITS_DISPLAY <= sRED_UNITS_CNT when sSTATE = RED else "0000";
	sRED_TENS_DISPLAY <= sRED_TENS_CNT when sSTATE = RED else "0000";
	sGREEN_UNITS_DISPLAY <= sGREEN_UNITS_CNT when sSTATE = GREEN else "0000";
	sGREEN_TENS_DISPLAY <= sGREEN_TENS_CNT when sSTATE = GREEN else "0000";
	
-- Brojac za multipleksiranje
	process(iCLK, iRST) begin
		if(iRST = '1') then
        sDIS_CNT <= (others => '0');
		elsif(rising_edge(iCLK)) then
        if(sDIS_CNT = cDIS_MAX - 1) then
            sDIS_CNT <= (others => '0');
        else
            sDIS_CNT <= sDIS_CNT + 1;
        end if;
		end if;
	end process;
	
	sTC <= '1' when sDIS_CNT = cDIS_MAX else '0';
	
-- Izbor aktivnog displeja
	process(iCLK, iRST) begin
		if(iRST = '1') then
			sDIS_SEL <= "00";
		elsif(rising_edge(iCLK)) then
			if(sTC = '1') then
				if(sDIS_SEL = "11") then
					sDIS_SEL <= "00";
				else
					sDIS_SEL <= sDIS_SEL + 1;
				end if;
			end if;
		end if;
	end process;
	
-- Multiplekser za izbor 7-segmentnog displeja
process(sDIS_SEL, sDISPLAY_0, sDISPLAY_1, sDISPLAY_2, sDISPLAY_3) 
begin
    oDIS <= sDIS_SEL;

	 
    if sDIS_SEL = "00" then
        o7SEGM <= sDISPLAY_3;  -- GREEN desetice
    elsif sDIS_SEL = "01" then
        o7SEGM <= sDISPLAY_2;  -- GREEN jedinice
    elsif sDIS_SEL = "10" then
        o7SEGM <= sDISPLAY_1;  -- RED desetice
    elsif sDIS_SEL = "11" then
        o7SEGM <= sDISPLAY_0;  -- RED jedinice
    else
        o7SEGM <= "1111111";   -- default stanje
    end if;
end process;
	
	
	
	oRED <= '1' when sSTATE = RED else '0';
	oYELLOW <= '1' when sSTATE = YELLOW else '0';
	oGREEN <= '1' when sSTATE = GREEN else '0';
	
end Behavioral;
