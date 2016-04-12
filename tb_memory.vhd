library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;

entity tb_memory is
end entity;

architecture testbench of tb_memory is
	signal clk : std_logic := '0';
	signal enable : std_logic;
	signal rw : std_logic;
	signal address : std_logic_vector (ADDRESS_WIDTH-1 downto 0);
	signal data : std_logic_vector (DATA_WIDTH-1 downto 0);
	signal data_ready : std_logic;

	component memory
		port(	clk : in std_logic;
				enable : in std_logic;
				rw : in std_logic;
				address : in std_logic_vector (ADDRESS_WIDTH-1 downto 0);
				data : inout std_logic_vector (DATA_WIDTH-1 downto 0);
				data_ready : out std_logic);
	end component;


begin
	UUT : memory Port map (clk, enable, rw, address, data, data_ready);

	clk <= not clk after half_period;

	stim: process 
	begin
		--Write data to memory
		address <= x"00000004";
		wait for 16 ns; --
		enable <= '1';
		rw <= '0';
		data <= x"01020304";
		wait for 32 ns;
		wait for 12 ns;
		enable <= '0';
		data <= (others => 'Z');
		wait for 100 ns;

		--Write data to memory
		address <= x"00000012";
		wait for 16 ns; --
		enable <= '1';
		rw <= '0';
		data <= x"0a0b0c0d";
		wait for 32 ns;
		wait for 12 ns;
		enable <= '0';
		data <= (others => 'Z');
		wait for 100 ns;

		--Read data from memory
		address <= x"00000004";
		wait for 16 ns; --
		enable <= '1';
		rw <= '1';
		wait for 16 ns;
		wait until data_ready = '1';
		enable <= '0';

		wait for 100 ns;

		--Read data from memory
		address <= x"00000012";
		wait for 16 ns; --
		enable <= '1';
		rw <= '1';
		wait for 16 ns;
		wait until data_ready = '1';
		enable <= '0';

		wait for 100 ns;

	end process;
end testbench;