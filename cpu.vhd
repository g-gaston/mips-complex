library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity cpu is
	port (	clk : in std_logic;
			address : out std_logic_vector (ADDRESS_WIDTH-1 downto 0);
			data_in : in std_logic_vector (DATA_WIDTH-1 downto 0);
			data_out : out std_logic_vector (DATA_WIDTH-1 downto 0);
			rw_cache : out std_logic; 		--1: read, 0: write
			i_d_cache : out std_logic; 		--1: Instruction, 0: Data
			cache_enable : out std_logic;
			data_cache_ready : in std_logic;
			PC_out : out std_logic_vector (ADDRESS_WIDTH-1 downto 0);
			IR_out : out std_logic_vector (ADDRESS_WIDTH-1 downto 0);
			MDR_out : out std_logic_vector (DATA_WIDTH-1 downto 0));
end cpu;

architecture behavioral of cpu is
signal PC : std_logic_vector (ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal IR : std_logic_vector (ADDRESS_WIDTH-1 downto 0);
signal MDR : std_logic_vector (DATA_WIDTH-1 downto 0);
signal registers : regs := (others => (others => '0'));
signal rs, rt, rd : std_logic_vector (4 downto 0);
signal inm : std_logic_vector (15 downto 0);
signal inmj : std_logic_vector (25 downto 0);

begin
	IR_out <= IR;
	PC_out <= PC;
	MDR_out <= MDR;

	process
	begin
		wait until clk='1';
		address <= PC;
		rw_cache <= '1';
		i_d_cache <= '1';
		cache_enable <= '1';
		wait until data_cache_ready='1';
		IR <= data_in;
		cache_enable <= '0';
		PC <= PC + 4;
		wait until clk='1';
		case IR(31 downto 26) is
			when "100011" =>		--LOAD
				rs <= IR(25 downto 21);
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				address <= (registers(to_integer(unsigned(rs))) + to_integer(unsigned(inm)));
				rw_cache <= '1';
				i_d_cache <= '0';
				cache_enable <= '1';
				wait until data_cache_ready='1'; --Wait until cache brings the data
				MDR <= data_in;
				wait until clk='1';
				registers(to_integer(unsigned(rt))) <= MDR;
				cache_enable <= '0';
			when "101011" =>		--STORE
				rs <= IR(25 downto 21);
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				rw_cache <= '0';
				address <= (registers(to_integer(unsigned(rs))) + to_integer(unsigned(inm)));
				data_out <= registers(to_integer(unsigned(rt)));
				i_d_cache <= '0';
				cache_enable <= '1';
				wait until data_cache_ready='1'; --Wait until cache finishes writing the data
				cache_enable <= '0';
			when "000000" =>
				if ieee.std_logic_unsigned."=" (IR(5 downto 0), "100000") then	--ADD
					rs <= IR(25 downto 21);
					rt <= IR(20 downto 16);
					rd <= IR(15 downto 11);
					wait until clk='1';
					registers(to_integer(unsigned(rd))) <= (registers(to_integer(unsigned(rs))) + registers(to_integer(unsigned(rt))));

				elsif ieee.std_logic_unsigned."=" (IR(5 downto 0), "001000") then	--JR
					rs <= IR(25 downto 21);
					wait until clk='1';
					PC <= registers(to_integer(unsigned(rs)));
				end if;

			when "000100" => --BEQ
				rs <= IR(25 downto 21);
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				if ieee.std_logic_unsigned."=" (registers(to_integer(unsigned(rs))), registers(to_integer(unsigned(rt)))) then
					PC <= PC + (to_integer(unsigned(inm))*4);
				end if;

			when "001101" => --XORI (ALU inm)
				rs <= IR(25 downto 21);
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				registers(to_integer(unsigned(rt))) <= registers(to_integer(unsigned(rs))) xor (x"0000" & inm);

			when "000010"=>	--J
				inmj <= IR(25 downto 0);
				wait until clk='1';
				PC <= PC (31 downto 28) & inmj & "00";

			when "001000" => --ADDI
				rs <= IR(25 downto 21);
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				registers(to_integer(unsigned(rt))) <= (registers(to_integer(unsigned(rs))) + to_integer(unsigned(inm)));

			when "001111" => --LUI
				rt <= IR(20 downto 16);
				inm <= IR(15 downto 0);
				wait until clk='1';
				registers(to_integer(unsigned(rt))) (31 downto 16) <= inm;

			when others => --Should not happen. If so, go to first instruction
				wait until clk='1';
				PC <= (others => '0');
		end case;
	end process;
end behavioral;
