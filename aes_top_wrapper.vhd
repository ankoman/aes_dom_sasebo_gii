----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/11 23:21:30
-- Design Name: 
-- Module Name: aes_top_wrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.masked_aes_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aes_top_wrapper_vhdl is
  generic (
    N                     : integer := 0       -- Protection order >= 0
    );
  port (
    ClkxCI   : in std_logic;
    RstxBI   : in std_logic;
    --- Inputs:
    -- Plaintext shares
    PTxDI    : in std_logic_vector((N+1)*8-1 downto 0);
    -- Key shares
    KxDI     : in std_logic_vector((N+1)*8-1 downto 0);
    -- Randomnes for remasking
    Zmul1xDI : in std_logic_vector(3 downto 0);  -- for y1 * y0 ### Works only for N=1
    Zmul2xDI : in std_logic_vector(3 downto 0);  -- for O * y1  ### Works only for N=1
    Zmul3xDI : in std_logic_vector(3 downto 0);  -- for O * y0  ### Works only for N=1
    Zinv1xDI : in std_logic_vector(1 downto 0);  -- for inverter    ### Works only for N=1
    Zinv2xDI : in std_logic_vector(1 downto 0);  -- ...         ### Works only for N=1
    Zinv3xDI : in std_logic_vector(1 downto 0);  -- ...         ### Works only for N=1
    -- Blinding values for Y0*Y1 and Inverter
    Bmul1xDI : in std_logic_vector((N+1)*4-1 downto 0);
    Binv1xDI : in std_logic_vector((N+1)*2-1 downto 0);
    Binv2xDI : in std_logic_vector((N+1)*2-1 downto 0);
    Binv3xDI : in std_logic_vector((N+1)*2-1 downto 0);
    -- Control signals
    StartxSI : in  std_logic; -- Start the core
    --- Output:
    DonexSO  : out std_logic; -- ciphertext is ready
    -- Cyphertext C
    CxDO     : out  std_logic_vector((N+1)*8-1 downto 0)
    );
end aes_top_wrapper_vhdl;

architecture Behavioral of aes_top_wrapper_vhdl is
    signal PTxDI_wrapper : t_shared_gf8(N downto 0);
    signal KxDI_wrapper : t_shared_gf8(N downto 0);
    signal CxDO_wrapper : t_shared_gf8(N downto 0);
    signal Zmul1xDI_wrapper : t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for y1 * y0
    signal Zmul2xDI_wrapper : t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y1
    signal Zmul3xDI_wrapper : t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y0
    signal Zinv1xDI_wrapper : t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- for inverter
    signal Zinv2xDI_wrapper : t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
    signal Zinv3xDI_wrapper : t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
    signal Bmul1xDI_wrapper : t_shared_gf4(N downto 0);              -- for y1 * y0
    signal Binv1xDI_wrapper : t_shared_gf2(N downto 0);              -- for inverter
    signal Binv2xDI_wrapper : t_shared_gf2(N downto 0);              -- ...
    signal Binv3xDI_wrapper : t_shared_gf2(N downto 0);              -- ...
begin
    gen: for i in 0 to N generate
        PTxDI_wrapper(i) <= PTxDI((i+1)*8-1 downto i*8);
        KxDI_wrapper(i) <= KxDI((i+1)*8-1 downto i*8);
        Bmul1xDI_wrapper(i) <= Bmul1xDI((i+1)*4-1 downto i*4);
        Binv1xDI_wrapper(i) <= Binv1xDI((i+1)*2-1 downto i*2);
        Binv2xDI_wrapper(i) <= Binv2xDI((i+1)*2-1 downto i*2);
        Binv3xDI_wrapper(i) <= Binv3xDI((i+1)*2-1 downto i*2);
    end generate gen;

--    Zmul1xDI_wrapper(0) <=  Zmul1xDI;     -- Comment out when N = 0
--    Zmul2xDI_wrapper(0) <=  Zmul2xDI;     -- Comment out when N = 0
--    Zmul3xDI_wrapper(0) <=  Zmul3xDI;     -- Comment out when N = 0
--    Zinv1xDI_wrapper(0) <= Zinv1xDI;      -- Comment out when N = 0
--    Zinv2xDI_wrapper(0) <= Zinv2xDI;      -- Comment out when N = 0
--    Zinv3xDI_wrapper(0) <= Zinv3xDI;      -- Comment out when N = 0

    CxDO <= CxDO_wrapper(0);    -- N = 0 case
    -- CxDO <= CxDO_wrapper(0) & CxDO_wrapper(1);    -- N = 1 case

    inst_aes: entity work.aes_top
        port map (
            ClkxCI  => ClkxCI,
            RstxBI  => RstxBI,
            PTxDI   => PTxDI_wrapper,
            KxDI    => KxDI_wrapper,
            Zmul1xDI => Zmul1xDI_wrapper,
            Zmul2xDI  => Zmul2xDI_wrapper,
            Zmul3xDI  => Zmul3xDI_wrapper,
            Zinv1xDI  => Zinv1xDI_wrapper,
            Zinv2xDI  => Zinv2xDI_wrapper,
            Zinv3xDI  => Zinv3xDI_wrapper,
            Bmul1xDI  => Bmul1xDI_wrapper,
            Binv1xDI  => Binv1xDI_wrapper,
            Binv2xDI  => Binv2xDI_wrapper,
            Binv3xDI  => Binv3xDI_wrapper,
            StartxSI => StartxSI,
            DonexSO => DonexSO,
            CxDO => CxDO_wrapper
        );
end Behavioral;
