LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
library work;
use work.fonts.all;

-- on my TV, the vertical range is 38 to 470; 27 lines
-- horizontal range is 4 to 612; 38 columns

entity fpgaris is 
    port
    (
    sync_output : out std_logic;
    bw_output : out std_logic;
    main_clock : in std_logic;
    button : in std_logic
    );
attribute altera_chip_pin_lc : string;
attribute altera_chip_pin_lc of button : signal is "@144";   
attribute altera_chip_pin_lc of bw_output : signal is "@96";   
attribute altera_chip_pin_lc of sync_output : signal is "@119";   
attribute altera_attribute : string;
attribute altera_attribute of button : signal is "-name WEAK_PULL_UP_RESISTOR ON";
end fpgaris;

architecture behavioral of fpgaris is
    constant pwmBits : natural := 4;
    constant screenWidth : natural := 640;
    constant clockFrequency : real := 208.33333333e6;
    signal clock : std_logic; 
    signal req: std_logic;
    signal x : unsigned(9 downto 0);
    signal y : unsigned(8 downto 0);
    signal pixel: unsigned(pwmBits-1 downto 0) ;
    signal posX : signed(10 downto 0) := to_signed(screenWidth/2,11);
    signal vX : signed(1 downto 0) := to_signed(1,2);
    signal posY : signed(9 downto 0) := to_signed(240,10);
    signal vY : signed(1 downto 0) := to_signed(1,2);
    signal count : unsigned(6 downto 0) := to_unsigned(0,7);
    signal frame : unsigned(3 downto 0) := to_unsigned(0,4);
    signal buttonDown : std_logic := '0';
    signal buttonDownAck : std_logic := '0';

begin
    PLL_INSTANCE: entity work.pll port map(main_clock, clock);
    output: entity work.ntsc 
                generic map(clockFrequency => clockFrequency, pwmBits=>pwmBits, screenWidth=>screenWidth) 
                port map(sync_output=>sync_output, bw_output=>bw_output, clock=>clock, pixel=>pixel, req=>req, x=>x, y=>y);


    process(main_clock)
    begin
    if rising_edge(main_clock) then
        if button='0' then
            buttonDown <= '1';
        elsif buttonDownAck='1' then
            buttonDown <= '0';
        else
            buttonDown <= buttonDown;
        end if;
    end if;
    end process;
            
    process(req)

    variable xs : signed(10 downto 0);
    variable ys : signed(9 downto 0);
    variable dist2 : signed(xs'length+ys'length downto 0);
    variable distScaled : unsigned(xs'length+ys'length-11 downto 0);
    begin
        if rising_edge(req) then
            if x=screenWidth-1 and y=479 then
                if frame(frame'left) = '1' then
                    frame <= to_unsigned(0,frame'length);
                    if buttonDown='1' then
                        count <= count+1;
                        buttonDownAck <= '1';
                    else
                        count <= count;
                        buttonDownAck <= '0';
                    end if;
                else
                    frame <= frame+1;
                    count <= count;
                    buttonDownAck <= '0';
                end if;
            else
                buttonDownAck <= '0';
                if getFontBit(to_integer(to_unsigned(32,7)+count), x(8 downto 6), y(8 downto 6)) ='1' then
                    pixel <= to_unsigned(255, pixel'length);
                else
                    pixel <= to_unsigned(0, pixel'length);
                end if;
            end if;
         end if;
    end process;
end behavioral;

