`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/13 19:49:19
// Design Name: 
// Module Name: VerilogAESWrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module VerilogAESWrapper #(
parameter N_share = 0)
(
    input ClkxCI,
    input RstxBI,
    //--- Inputs:
    // -- Plaintext shares
    input [8*(N_share+1)-1:0] PTxDI,
    input [8*(N_share+1)-1:0] KxDI,
    //    -- Randomnes for remasking
    input [3:0] Zmul1xDI, // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for y1 * y0     ### Works only for N=1
    input [3:0] Zmul2xDI, // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y1      ### Works only for N=1
    input [3:0] Zmul3xDI, //  : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y0     ### Works only for N=1
    input [1:0] Zinv1xDI, //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- for inverter   ### Works only for N=1
    input [1:0] Zinv2xDI, //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...            ### Works only for N=1
    input [1:0] Zinv3xDI, //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...            ### Works only for N=1
    //-- Blinding values for Y0*Y1 and Inverter
    input [4*(N_share+1)-1:0] Bmul1xDI,
    input [2*(N_share+1)-1:0] Binv1xDI,
    input [2*(N_share+1)-1:0] Binv2xDI,
    input [2*(N_share+1)-1:0] Binv3xDI,
   // -- Control signals
    input StartxSI, 
    //--- Output:
    output DonexSO,
    //-- Cyphertext C
    output [8*(N_share+1)-1:0] CxDO
);

    aes_top_wrapper_vhdl DUT(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        //--- Inputs:
        // -- Plaintext shares
        .PTxDI(PTxDI), // : in t_shared_gf8(N downto 0);
        .KxDI(KxDI), // : in t_shared_gf8(N downto 0);
        //    -- Randomnes for remasking
        .Zmul1xDI(Zmul1xDI), // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for y1 * y0
        .Zmul2xDI(Zmul2xDI), // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y1
        .Zmul3xDI(Zmul3xDI), //  : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y0
        .Zinv1xDI(Zinv1xDI), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- for inverter
        .Zinv2xDI(Zinv2xDI), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
        .Zinv3xDI(Zinv3xDI), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
        //-- Blinding values for Y0*Y1 and Inverter
        .Bmul1xDI(Bmul1xDI), //  : in t_shared_gf4(N downto 0);              -- for y1 * y0
        .Binv1xDI(Binv1xDI), //  : in t_shared_gf2(N downto 0);              -- for inverter
        .Binv2xDI(Binv2xDI), //  : in t_shared_gf2(N downto 0);              -- ...
        .Binv3xDI(Binv3xDI), //  : in t_shared_gf2(N downto 0);              -- ...
       // -- Control signals
        .StartxSI(StartxSI), //  : in  std_logic; -- Start the core
        //--- Output:
        .DonexSO(DonexSO), //   : out std_logic; -- ciphertext is ready
        //-- Cyphertext C
        .CxDO(CxDO) //      : out  t_shared_gf8(N downto 0)
    );
endmodule