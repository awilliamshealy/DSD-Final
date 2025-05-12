LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.NUMERIC_STD.ALL;
--USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY pong IS
    PORT (
        clk_in : IN STD_LOGIC; -- system clock
        VGA_red : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- VGA outputs
        VGA_green : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        btnl : IN STD_LOGIC;
        btnr : IN STD_LOGIC;
        btn0 : IN STD_LOGIC;
        btnd : IN STD_LOGIC;
        btnc : IN STD_LOGIC;
        SEG7_anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- anodes of four 7-seg displays
        SEG7_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
    ); 
END pong;

ARCHITECTURE Behavioral OF pong IS
    SIGNAL pxl_clk : STD_LOGIC := '0'; -- 25 MHz clock to VGA sync module
    -- Internal signals to connect modules
    SIGNAL S_red, S_green, S_blue : STD_LOGIC; 
    SIGNAL S_red_full, S_green_full, S_blue_full : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL S_vsync : STD_LOGIC;
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    SIGNAL player_x, player_y : STD_LOGIC_VECTOR (10 DOWNTO 0) := (others => '0');
    SIGNAL count : STD_LOGIC_VECTOR (20 DOWNTO 0); -- Counter for debouncing or movement rate control
    SIGNAL display : std_logic_vector (15 DOWNTO 0);
    SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0);
    
    COMPONENT obstacle_game IS
        PORT (
            v_sync     : IN  STD_LOGIC;
            pixel_row  : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col  : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            player_x   : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            player_y   : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
            btnc       : IN  STD_LOGIC;
            red        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            green      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            blue       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            score      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
            red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            hsync : OUT STD_LOGIC;
            vsync : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT clk_wiz_0 is
        PORT (
            clk_in1  : in std_logic;
            clk_out1 : out std_logic
        );
    END COMPONENT;
    COMPONENT leddec16 IS
        PORT (
            dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
            data : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
        );
    END COMPONENT; 
    
BEGIN

    -- Movement Process
   pos : PROCESS (clk_in)
BEGIN
    IF rising_edge(clk_in) THEN
        count <= std_logic_vector(unsigned(count) + 1);

        -- Button Debouncing and Movement Control
        IF unsigned(count) = 0 THEN
            -- Move Left
            IF (btnl = '1' AND unsigned(player_x) > 5) THEN
                player_x <= std_logic_vector(unsigned(player_x) - to_unsigned(5, player_x'length));
            -- Move Right
            ELSIF (btnr = '1' AND unsigned(player_x) < 635) THEN
                player_x <= std_logic_vector(unsigned(player_x) + to_unsigned(5, player_x'length));
            END IF;

            -- Move Up
            IF (btnd = '1' AND unsigned(player_y) > 5) THEN
                player_y <= std_logic_vector(unsigned(player_y) - to_unsigned(5, player_y'length));
            -- Move Down
            ELSIF (btn0 = '1' AND unsigned(player_y) < 475) THEN
                player_y <= std_logic_vector(unsigned(player_y) + to_unsigned(5, player_y'length));
            END IF;
        END IF;
    END IF;
END PROCESS;
    S_red_full   <= (others => S_red);   -- replicate S_red to 4 bits
    S_green_full <= (others => S_green); -- replicate S_green to 4 bits
    S_blue_full  <= (others => S_blue);  -- replicate S_blue to 4 bits
    led_mpx <= count(19 DOWNTO 17); -- 7-seg multiplexing clock    
    
    game_inst : obstacle_game
    PORT MAP(
        v_sync    => S_vsync,
        pixel_row => S_pixel_row,
        pixel_col => S_pixel_col,
        player_x  => player_x,
        player_y  => player_y,
        btnc      => btnc,
        red       => S_red_full,
        green     => S_green_full,
        blue      => S_blue_full,
        score     => display
    );
    
    vga_driver : vga_sync
    PORT MAP(--instantiate vga_sync component
        pixel_clk => pxl_clk, 
        red_in    => S_red_full,   -- Use the 4-bit red signal
        green_in  => S_green_full, -- Use the 4-bit green signal
        blue_in   => S_blue_full,  -- Use the 4-bit blue signal
        red_out => VGA_red, 
        green_out => VGA_green, 
        blue_out => VGA_blue, 
        pixel_row => S_pixel_row, 
        pixel_col => S_pixel_col, 
        hsync => VGA_hsync, 
        vsync => S_vsync
    );
    VGA_vsync <= S_vsync; --connect output vsync
        
    clk_wiz_0_inst : clk_wiz_0
    port map (
      clk_in1 => clk_in,
      clk_out1 => pxl_clk
    );
    led1 : leddec16
    PORT MAP(
      dig => led_mpx, 
      data => display, 
      anode => SEG7_anode, 
      seg => SEG7_seg
    );
END Behavioral;
