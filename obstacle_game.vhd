LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY obstacle_game IS
    PORT (
        v_sync     : IN  STD_LOGIC;
        pixel_row  : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col  : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        player_x   : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        player_y   : IN  STD_LOGIC_VECTOR(10 DOWNTO 0);
        btnc       : IN  STD_LOGIC;  -- center button for reset
        red        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        score      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END obstacle_game;

ARCHITECTURE Behavioral OF obstacle_game IS

    CONSTANT player_size   : INTEGER := 10;
    CONSTANT max_obstacles : INTEGER := 6;
    TYPE int_array IS ARRAY (0 TO max_obstacles - 1) OF INTEGER;

    SIGNAL obs_x, obs_y       : int_array := (others => 100);
    SIGNAL score_val          : INTEGER := 0;
    SIGNAL difficulty         : INTEGER := 1;
    SIGNAL obstacle_size      : INTEGER := 20;
    SIGNAL active_obs         : INTEGER := 2;
    SIGNAL game_over          : BOOLEAN := FALSE;

BEGIN
    -- Game update process
    process(v_sync)
begin
    if rising_edge(v_sync) then
        -- Reset on button press or after game over
        if btnc = '1' or game_over then
            for i in 0 to max_obstacles - 1 loop
                obs_x(i) <= 100;
                obs_y(i) <= 0;
            end loop;
            score_val <= 0;
            difficulty <= 1;
            obstacle_size <= 20;
            active_obs <= 2;
            game_over <= false;

        elsif not game_over then
            -- Move active obstacles
            for i in 0 to max_obstacles - 1 loop
                if i < active_obs then
                    obs_y(i) <= obs_y(i) + 4 + difficulty;
                    if obs_y(i) > 480 then
                        obs_y(i) <= 0;
                        obs_x(i) <= (obs_x(i) + (i * 83 + 57)) mod 600;
                        score_val <= score_val + 1;
                    end if;
                end if;
            end loop;

            -- Increase difficulty gradually
            if (score_val mod 10 = 0) and (score_val /= 0) then
                if difficulty < 5 then
                    difficulty <= difficulty + 1;
                end if;
                if active_obs < max_obstacles then
                    active_obs <= active_obs + 1;
                end if;
                if obstacle_size < 30 then
                    obstacle_size <= obstacle_size + 1;
                end if;
            end if;
        end if;
    end if;
end process;


    -- Collision detection & drawing process
    process(pixel_row, pixel_col, obs_x, obs_y, player_x, player_y)
        VARIABLE collided : BOOLEAN := FALSE;
        VARIABLE px, py   : INTEGER;
    BEGIN
        red   <= (others => '0');
        green <= (others => '0');
        blue  <= (others => '0');
        collided := FALSE;

        px := conv_integer(player_x);
        py := conv_integer(player_y);

        -- Draw player
        IF pixel_col >= px AND pixel_col < px + player_size AND
           pixel_row >= py AND pixel_row < py + player_size THEN
            red <= (others => '1');
        END IF;

        -- Draw and check obstacles
        FOR i IN 0 TO max_obstacles - 1 LOOP
            IF i < active_obs THEN
                IF pixel_col >= obs_x(i) AND pixel_col < obs_x(i) + obstacle_size AND
                   pixel_row >= obs_y(i) AND pixel_row < obs_y(i) + obstacle_size THEN
                    blue <= (others => '1');
                END IF;

                -- Collision logic
                IF px + player_size > obs_x(i) AND px < obs_x(i) + obstacle_size AND
                   py + player_size > obs_y(i) AND py < obs_y(i) + obstacle_size THEN
                    collided := TRUE;
                END IF;
            END IF;
        END LOOP;

        -- Trigger game over
        IF collided THEN
            game_over <= TRUE;
        END IF;
    END process;

    -- Output score
    score <= conv_std_logic_vector(score_val, 16);

END Behavioral;
