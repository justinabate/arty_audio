--! @title LED Magnitude Driver
--! @file led_magnitude_driver.vhd 
--! @author JA 
--! @version 0.01
--! @date 05/28/2021
--! @details
--! - Examines audio stream input on S AXIS port
--! - Stores right channel sample when s_axis_valid and s_axis_last are both high
--! - Stores left channel sample when s_axis_valid is high and s_axis_last is low
--! - Translates each signed sample to an unsigned signal magnitude
--! - Outputs LED vector for each channel based on signal magnitude
--! - Latency = 3 cycles = 1 store + 1 translate + 1 output


library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity led_magnitude_driver is
    generic (
        g_data_width : natural := 24
    );
    port (
          ila_clk : in std_logic
        ; clk : in std_logic

        ; s_axis_data : in std_logic_vector(g_data_width-1 downto 0)
        ; s_axis_valid : in std_logic
        ; s_axis_last : in std_logic

        ; o_led_l : out std_logic_vector(3 downto 0)
        ; o_led_r : out std_logic_vector(3 downto 0)
    );
end led_magnitude_driver;


architecture rtl of led_magnitude_driver is


    --! store signed samples from S AXIS port
    signal r_sample_l : std_logic_vector(g_data_width-1 downto 0);
    signal r_sample_r : std_logic_vector(g_data_width-1 downto 0);

    --! registers for magnitude of current sample on each channel
    signal r_mag_l : std_logic_vector(g_data_width-1 downto 0);
    signal r_mag_r : std_logic_vector(g_data_width-1 downto 0);

    -- fractions of input magnitude with respect to full scale
    constant c_full_scale_mag : std_logic_vector(23 downto 0) := x"800000"; -- 
    -- 1.00: 1000_0000_0000_0000_0000_0000: 100% of full scale; 24 bits
    constant c_100_sf : std_logic_vector(g_data_width-1 downto 0) := c_full_scale_mag;
    -- 0.50:  100_0000_0000_0000_0000_0000:  50% of full scale; 23 bits
    constant c_050_sf : std_logic_vector(g_data_width-2 downto 0) := c_100_sf(c_100_sf'high downto c_100_sf'low+1);
    -- 0.25:   10_0000_0000_0000_0000_0000:  25% of full scale; 22 bits
    constant c_025_sf : std_logic_vector(g_data_width-3 downto 0) := c_050_sf(c_050_sf'high downto c_050_sf'low+1);
    -- 0.12:    1_0000_0000_0000_0000_0000:  12% of full scale; 21 bits
    constant c_012_sf : std_logic_vector(g_data_width-4 downto 0) := c_025_sf(c_025_sf'high downto c_025_sf'low+1);

    -- 0.37:   11_0000_0000_0000_0000_0000:  37% of full scale; 22 bits
    constant c_037_sf : std_logic_vector(g_data_width-3 downto 0) := c_025_sf + c_012_sf;
    -- 0.62:  101_0000_0000_0000_0000_0000:  62% of full scale; 23 bits
    constant c_062_sf : std_logic_vector(g_data_width-2 downto 0) := c_050_sf + c_012_sf;
    -- 0.75:  110_0000_0000_0000_0000_0000:  75% of full scale; 23 bits
    constant c_075_sf : std_logic_vector(g_data_width-2 downto 0) := c_050_sf + c_025_sf;
    -- 0.87:  111_0000_0000_0000_0000_0000:  87% of full scale; 23 bits
    constant c_087_sf : std_logic_vector(g_data_width-2 downto 0) := c_075_sf + c_012_sf;

    --! registers for LED output 
    signal r_led_l : std_logic_vector(o_led_l'high downto 0);
    signal r_led_r : std_logic_vector(o_led_r'high downto 0);


begin


    --! pull left channel and right channel samples from S AXIS port
    p_fetch_samples : process(clk) begin
        if rising_edge(clk) then

            if (s_axis_valid = '1' and s_axis_last = '0') then
                r_sample_l <= s_axis_data;
            end if;

            if (s_axis_valid = '1' and s_axis_last = '1') then
                r_sample_r <= s_axis_data;
            end if;

        end if;
    end process;


    --! check high bit of sample for the amplitude polarity
    --!    for (+) samples, magnitude = sample value 
    --!    for (-) samples, magnitude = two's complement of sample value 
    p_left_channel_magnitude : process(clk) begin
        if rising_edge(clk) then

            if (r_sample_l(r_sample_l'high) = '0') then
                r_mag_l <= r_sample_l;
            else
                r_mag_l <= not(r_sample_l - '1');
            end if;

            if (r_sample_r(r_sample_r'high) = '0') then
                r_mag_r <= r_sample_r;
            else
                r_mag_r <= not(r_sample_r - '1');
            end if;

        end if;
    end process; 


    p_assign_led : process(clk) begin
        if rising_edge(clk) then

            -- set left channel LEDs
            if (r_mag_l > c_050_sf) then 
                r_led_l <= "1111";
            elsif(r_mag_l > c_037_sf) then 
                r_led_l <= "0111";
            elsif(r_mag_l > c_025_sf) then 
                r_led_l <= "0011";
            elsif(r_mag_l > c_012_sf) then 
                r_led_l <= "0001";
            else 
                r_led_l <= "0000";
            end if;

            -- set right channel LEDs
            if (r_mag_r > c_050_sf) then 
                r_led_r <= "1111";
            elsif(r_mag_r > c_037_sf) then 
                r_led_r <= "0111";
            elsif(r_mag_r > c_025_sf) then 
                r_led_r <= "0011";
            elsif(r_mag_r > c_012_sf) then 
                r_led_r <= "0001";
            else 
                r_led_r <= "0000";
            end if;
            
        end if;
    end process;


    --! wires
    o_led_l <= r_led_l;
    o_led_r <= r_led_r;


--    inst_ila : entity work.ila_1 
--    port map (
--          clk     => ila_clk                         -- : IN STD_LOGIC;
--
--        , probe0  => (0 => clk) -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1; 
--        , probe1  => x"0000"             -- : IN STD_LOGIC_VECTOR(15 DOWNTO 0; 16
--
--        , probe2  => s_axis_data         -- : IN STD_LOGIC_VECTOR(23 DOWNTO 0; 24
--        , probe3  => (0 => s_axis_valid)  -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--        , probe4  => (0 => '0') -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--        , probe5  => (0 => s_axis_last)  -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--
--        , probe6  => r_mag_l         -- : IN STD_LOGIC_VECTOR(23 DOWNTO 0; 24
--        , probe7  => (0 => w_pol_l) -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--        , probe8  => (0 => w_pol_r) -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--        , probe9  => (0 => '0')     -- : IN STD_LOGIC_VECTOR(0  DOWNTO 0;  1
--
--        , probe10 => (24 downto 12 => '0') & (11 downto 0 => std_logic_vector(to_unsigned(r_sf_l, 12)) ) -- : IN STD_LOGIC_VECTOR(24 DOWNTO 0); 25 
--        , probe11 => (17 downto 2*r_led_l'length => '0') & (7 downto 4 => r_led_l) & (3 downto 0 => r_led_r) -- : IN STD_LOGIC_VECTOR(17 DOWNTO 0); 18
--        , probe12 => (42 downto 0 => '0')                                                    -- : IN STD_LOGIC_VECTOR(42 DOWNTO 0); 43
--    );

end architecture;