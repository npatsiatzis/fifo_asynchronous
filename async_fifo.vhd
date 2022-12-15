--Asynchronous FIFO used to transfer data across asynchronous (non-related) clock domains.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo is 
generic(
	g_stages : natural :=2;
	g_width  : natural :=4;
	g_depth  : natural :=2);
port(
	i_clkW : in std_ulogic;
	i_arstnW : in std_ulogic;
	i_wren : in std_ulogic;
	i_dataW : in std_ulogic_vector(g_width -1 downto 0);
	i_clkR : in std_ulogic;
	i_arstnR : in std_ulogic;
	i_ren : in std_ulogic;
	o_dataR : out std_ulogic_vector(g_width -1 downto 0);
	o_empty : out std_ulogic;
	o_full : out std_ulogic);
end async_fifo;

architecture rtl of async_fifo is
	type mem is array(0 to 2**g_depth-1) of std_ulogic_vector(g_width -1 downto 0);
	signal memory : mem :=(others => (others => '0'));

	--control pointers. 1 extra bit than what required to address the memory to
	--calculate the full/empty conditions
	signal gray_r, gray_r_next : std_ulogic_vector(g_depth downto 0) :=(others => '0');
	signal bin_r, bin_r_next  : unsigned(g_depth downto 0) :=(others => '0');
	signal gray_w,gray_w_next : std_ulogic_vector(g_depth downto 0) :=(others => '0');
	signal bin_w,bin_w_next  : unsigned(g_depth downto 0) :=(others => '0');
	--memory address pointers (used to address memory for write/read operations)
	--exclude MSB of control pointers
	signal addr_w,addr_r : std_ulogic_vector(g_depth-1 downto 0) :=(others => '0');

	type two_stage is array(0 to 1) of std_ulogic_vector(g_depth downto 0);
	signal gray_r_2_w : two_stage;
	signal gray_w_2_r : two_stage;

	signal o_full_next : std_ulogic;
	signal o_empty_next : std_ulogic;

begin

	--WRITE DOMAIN

	--Cross the read gray pointer into the write domain
	cdc_gray_r_2_w : process(i_clkW,i_arstnW) is
	begin
		if(i_arstnW = '0') then
			gray_r_2_w <= (others => (others => '0'));
		elsif (rising_edge(i_clkW)) then
			gray_r_2_w(1) <= gray_r_2_w(0);
			gray_r_2_w(0) <= gray_r;
		end if;		
	end process; -- cdc_gray_r_2_w 

	--Calculate the next write addres(bin) and the next gray write pointer
	w_addr_calc : process(all)
	begin
		if(i_wren = '1' and (o_full = '0'))then
			bin_w_next <= bin_w + 1;
		end if;
	end process; -- w_addr_calc
	addr_w <= std_ulogic_vector(bin_w(g_depth-1 downto 0));
	gray_w_next <= std_ulogic_vector(shift_right(bin_w_next,1)) xor std_ulogic_vector(bin_w_next);


	reg_write_address : process(i_clkW,i_arstnW)
	begin
		if(i_arstnW = '0') then
			gray_w <= (others => '0');
			bin_w <= (others => '0');
		elsif (rising_edge(i_clkW)) then
			if(i_wren and (not o_full))then
				gray_w <= gray_w_next;
				bin_w <= bin_w_next;
			end if;
		end if;
	end process; -- reg_write_address

	--Calculate whether the FIFO will be full on the next cycle
	calc_full : process(all) 
	begin
		--FIFO full when next write pointer = synchronized read pointer 
		--(except for [MSB:MSB-1] which must be different)
		if(gray_w_next = (not (gray_r_2_w(1)(g_depth)) & not (gray_r_2_w(1)(g_depth-1)) & gray_r_2_w(1)(g_depth-2 downto 0)))then
			o_full_next <= '1';
		else
			o_full_next <= '0';
		end if;
	end process; -- calc_full

	reg_full : process(i_clkW,i_arstnW)
	begin
		if(i_arstnW ='0') then
			o_full <= '0';
		elsif(rising_edge(i_clkW)) then
			o_full <= o_full_next;
		end if;
	end process; -- reg_full

	--Write to the FIFO 
	fifo_write : process(i_clkW)
	begin
		if(rising_edge(i_clkW)) then
			if(i_wren = '1' and (o_full = '0')) then
				memory(to_integer(unsigned(addr_w))) <= i_dataW;
			end if;
		end if;
	end process; -- fifo_write



	--READ DOMAIN

	--Cross the write gray pointer into the read domain
	cdc_gray_w_2_r : process(i_clkR,i_arstnR) is
	begin
		if(i_arstnR = '0') then
			gray_w_2_r <= (others => (others => '0'));
		elsif (rising_edge(i_clkR)) then
			gray_w_2_r(1) <= gray_w_2_r(0);
			gray_w_2_r(0) <= gray_w;
		end if;
	end process; -- cdc_gray_w_2_r

	--Calculate the next read address(bin) and the next gray read pointer
	r_addr_calc : process(all)
	begin
		if(i_ren = '1' and (o_empty = '0')) then
			bin_r_next <= bin_r + '1'; 
		end if;
	end process; -- r_addr_calc

	addr_r <= std_ulogic_vector(bin_r(g_depth-1 downto 0));
	gray_r_next <= std_ulogic_vector(shift_right(bin_r_next,1)) xor std_ulogic_vector(bin_r_next);

	reg_read_addr : process(i_clkR,i_arstnR)
	begin
		if(i_arstnR = '0') then
			gray_r <= (others => '0');
			bin_r <= (others => '0');
		elsif (rising_edge(i_clkR)) then
			gray_r <= gray_r_next;
			bin_r <= bin_r_next;
		end if;
	end process; -- reg_read_addr

	--Determine if the FIFO will be empty on the next clock
	calc_empty : process(all)
	begin
		--FIFO empty when next read pointer = synchronized write pointer or on reset
		if(gray_r_next = gray_w_2_r(1)) then
			o_empty_next <= '1';
		else
			o_empty_next <= '0';
		end if;
	end process; -- calc_empty

	reg_empty : process(i_clkR,i_arstnR)
	begin
		if(i_arstnR = '0') then
			o_empty <= '1';
		else
			o_empty <= o_empty_next;
		end if;
	end process; -- reg_empty

	--Read from the memory
	o_dataR <= memory(to_integer(unsigned(addr_r)));

	--fifo_read : process(i_clkR)
	--begin
	--	if(i_arstnR = '0') then
	--		o_dataR <= (others => '0');
	--	elsif(rising_edge(i_clkR)) then
	--		if(i_ren = '1' and (o_empty = '0')) then
	--			o_dataR <= memory(to_integer(unsigned(addr_r)));
	--		end if;
	--	end if;
	--end process; -- fifo_read

end rtl;