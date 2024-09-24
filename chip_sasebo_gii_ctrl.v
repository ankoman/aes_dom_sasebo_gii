/*-------------------------------------------------------------------------
 SASEBO-GII controller (for FPGA cryptographic module)
 
 File name   : chip_sasebo_gii_ctrl.v
 Version     : 1.3
 Created     : APR/02/2012
 Last update : APR/11/2012
 Desgined by : Toshihiro Katashita
 
 
 Copyright (C) 2012 AIST
 
 By using this code, you agree to the following terms and conditions.
 
 This code is copyrighted by AIST ("us").
 
 Permission is hereby granted to copy, reproduce, redistribute or
 otherwise use this code as long as: there is no monetary profit gained
 specifically from the use or reproduction of this code, it is not sold,
 rented, traded or otherwise marketed, and this copyright notice is
 included prominently in any copy made.
 
 We shall not be liable for any damages, including without limitation
 direct, indirect, incidental, special or consequential damages arising
 from the use of this code.
 
 When you publish any results arising from the use of this code, we will
 appreciate it if you can cite our webpage.
 (http://www.aist.go.jp/aist_e/research_results/publications/synthesiology_e/vol3_no1/vol03_01_p86_p95.pdf)
 -------------------------------------------------------------------------*/ 

// Cryptographic FPGA clock = 24 MHz / 8 = 3 MHz
`define CLOCK_DIVIDE 2


//================================================ CHIP_SASEBO_GII_CTRL
module CHIP_SASEBO_GII_CTRL(cfg_din, cfg_mosi, cfg_fcsb, cfg_cclk, 
								cfg_progn, cfg_csn, cfg_initn, cfg_rdwrn, cfg_busy, 
								cfg_done, cfg_done_alt, led, clkin, rstnin, uart_rx,
								uart_tx, run, trg);
localparam len_din = 128*2; // N = 0
localparam len_dout = 128;  // N = 0

   //------------------------------------------------
   // SelectMap configuration
   input         cfg_din, cfg_mosi, cfg_fcsb, cfg_cclk;
   input         cfg_progn, cfg_csn, cfg_initn, cfg_rdwrn, cfg_busy;
   input         cfg_done, cfg_done_alt;

   // LED, dip switch, clock and reset
   output [7:0]  led;
   //input [3:0]   dipsw;
   input         clkin;
   input         rstnin; // Push SW (SW8)
   
   // For AES DOM
   input uart_rx;
   output uart_tx, run, trg;

   //------------------------------------------------
   // Internal clock
   wire          clk, rst;
     
   // etc
   reg [23:0]    cnt;
  
   //------------------------------------------------
   assign led[0] = ~cnt[23];
   assign led[1] = ~rst;
   assign led[2] = ~(cfg_done & cfg_done_alt);
   assign led[3] = ~(cfg_initn | cfg_progn | cfg_csn | cfg_rdwrn | cfg_busy);
   assign led[4] = ~cfg_din;
   assign led[5] = ~cfg_mosi;
   assign led[6] = ~cfg_fcsb;
   assign led[7] = ~cfg_cclk;

   always @(posedge clk or posedge rst) 
     if (rst) cnt <= 24'h0;
     else     cnt <= cnt + 24'h1;

   //------------------------------------------------   
   // AES DOM

    wire extin_en, done, rst_n, run;
    wire [7:0] BRAM_addr_for_extin, BRAM_addr_for_extout;
    wire [len_dout - 1:0] extout_data;
    wire[len_din - 1:0] extin_data;
    reg [7:0] trg_delay, cnt_trg;
    reg [14:0] cnt_15;
    wire [7:0] pin, kin, cout;
    reg [127:0] ptxt, key, sreg_ptxt, sreg_key, ctxt;
    assign rst_n = !rst;
    assign trg = (cnt_trg == 8'h01) ? 1'b1 : 1'b0;

    UART_CTRL #(.len_din(len_din), .len_dout(len_dout)) uart_module (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .BRAM_addr_for_extin(BRAM_addr_for_extin),
    .BRAM_addr_for_extout(),
    .extout_data(ctxt),
    .extin_data(extin_data),
    .extin_en(extin_en),
	  .swrst(),
    .run(run)
    );

    always @(posedge clk) begin
        if(!rst_n) begin
            cnt_trg <= 0;
        end
        else if(run) begin
            cnt_trg <= trg_delay;
        end
        else if (|cnt_trg) begin
            cnt_trg <= cnt_trg - 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin
            ptxt <= 128'd0;
            key <= 128'd0;
            trg_delay <= 0;
        end
        else begin
            if(extin_en) begin
                if(BRAM_addr_for_extin[1:0] == 2'b01) begin
                    ptxt <= extin_data[127:0];
                    key <= extin_data[255:128];
                end
                else if(BRAM_addr_for_extin[1:0] == 2'b10) begin
                    trg_delay <= extin_data[7:0];
                end
            end
        end
    end
    
    
    VerilogAESWrapper DUT(
        .ClkxCI(clk),
        .RstxBI(rst_n),
        .PTxDI(pin),
        .KxDI(kin),
        .Zmul1xDI(4'd0), // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for y1 * y0
        .Zmul2xDI(4'd0), // : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y1
        .Zmul3xDI(4'd0), //  : in t_shared_gf4((N*(N+1)/2)-1 downto 0);  -- for O * y0
        .Zinv1xDI(2'd0), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- for inverter
        .Zinv2xDI(2'd0), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
        .Zinv3xDI(2'd0), //  : in t_shared_gf2((N*(N+1)/2)-1 downto 0);  -- ...
        //-- Blinding values for Y0*Y1 and Inverter
        .Bmul1xDI(4'd0), //  : in t_shared_gf4(N downto 0);              -- for y1 * y0
        .Binv1xDI(2'd0), //  : in t_shared_gf2(N downto 0);              -- for inverter
        .Binv2xDI(2'd0), //  : in t_shared_gf2(N downto 0);              -- ...
        .Binv3xDI(2'd0), //  : in t_shared_gf2(N downto 0);              -- ...
        .StartxSI(run),
        .DonexSO(done),
        .CxDO(cout)
        );
        
    assign pin = sreg_ptxt[127:120];
    assign kin = sreg_key[127:120];
    
    always @(posedge clk) begin
        if(!rst_n) begin
            cnt_15 <= 0;
        end
        else if (done) begin
            cnt_15[0] <= 1'b1;
        end
        else begin
            cnt_15 <= {cnt_15[13:0], 1'b0};
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            ctxt <= 128'd0;
        end
        else begin
            if (|cnt_15 || done) begin
                ctxt <= {ctxt[119:0], cout};
            end
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            sreg_ptxt <= 128'd0;
            sreg_key <= 128'd0;
        end 
        else if(run) begin
            sreg_ptxt <= ptxt;
            sreg_key <= key;
        end
        else begin
            sreg_ptxt <= {sreg_ptxt[119:0], 8'd0};
            sreg_key <= {sreg_key[119:0], 8'd0};
        end
    end

   
   //------------------------------------------------
   MK_EXTCLKRST mk_clkrst  (.clkin(clkin), .rstnin(rstnin),
                         .cfg_done(cfg_done & cfg_done_alt),
                         .clk(clk), .rst(rst));
   
endmodule // CHIP_SASEBO_GII_CTRL

//================================================ MK_CLKRST
module MK_EXTCLKRST (clkin, rstnin, cfg_done, clk, rst);
   //synthesis attribute keep_hierarchy of MK_CLKRST is no;
   
   //------------------------------------------------
   input  clkin, rstnin, cfg_done;
   output clk, rst;
   
   //------------------------------------------------
   wire   rst_itrl, rst_dll;
   wire   refclk;
   wire   clk1x, clk1x_dcm, clkdv_dcm, locked;

   //------------------------------------------------ dll reset
   INTERNAL_RST u00 (.clk(refclk), .rst(rst_itrl));
   assign rst_dll = rst_itrl | ~rstnin;

   //------------------------------------------------ clock
   IBUFG u10 (.I(clkin), .O(refclk)); 
   BUFG  u13 (.I(refclk), .O(clk));

   //------------------------------------------------ reset
   MK_RST u20 (.locked(rstnin&cfg_done), .clk(clk),  .rst(rst));
endmodule // MK_CLKRST


//================================================ MK_CLKRST
module MK_CLKRST (clkin, rstnin, cfg_done, clk, rst);
   //synthesis attribute keep_hierarchy of MK_CLKRST is no;
   
   //------------------------------------------------
   input  clkin, rstnin, cfg_done;
   output clk, rst;
   
   //------------------------------------------------
   wire   rst_itrl, rst_dll;
   wire   refclk;
   wire   clk1x, clk1x_dcm, clkdv_dcm, locked;

   //------------------------------------------------ dll reset
   INTERNAL_RST u00 (.clk(refclk), .rst(rst_itrl));
   assign rst_dll = rst_itrl | ~rstnin;

   //------------------------------------------------ clock
   IBUFG u10 (.I(clkin), .O(refclk)); 

   DCM_SP #(.CLKIN_PERIOD(41.666),  // Source clock: 24 MHz
            .CLKDV_DIVIDE(`CLOCK_DIVIDE), // 24 / 8 = 3 MHz
            .CLK_FEEDBACK("1X"))
   u11 (.CLKIN(refclk), .CLKFB(clk1x), .RST(rst_dll),
        .PSEN(1'b0), .PSINCDEC (1'b0), .PSCLK(1'b0), .DSSEN(1'b0),
        .CLK0(clk1x_dcm),     .CLKDV(clkdv_dcm),
        .CLK90(), .CLK180(), .CLK270(),
        .CLK2X(), .CLK2X180(), .CLKFX(), .CLKFX180(),
        .STATUS(), .LOCKED(locked), .PSDONE());
   
   BUFG  u12 (.I(clk1x_dcm), .O(clk1x));
   BUFG  u13 (.I(clkdv_dcm), .O(clk));

   //------------------------------------------------ reset
   MK_RST u20 (.locked(locked&rstnin&cfg_done), .clk(clk),  .rst(rst));
endmodule // MK_CLKRST



//================================================ INTERNAL_RST
module INTERNAL_RST (clk, rst);
   //synthesis attribute keep_hierarchy of INTERNAL_RST is no;

   //------------------------------------------------
   input  clk;
   output rst;

   //------------------------------------------------
   wire   rst_srl;
   
   //------------------------------------------------
   SRL16 # (.INIT(16'hFFFF))
   u00 (.D(1'b0),    .CLK(clk), .Q(rst_srl),
	.A3(1'b1), .A2(1'b1), .A1(1'b1), .A0(1'b1));

   SRL16 # (.INIT(16'hFFFF))
   u01 (.D(rst_srl), .CLK(clk), .Q(rst),
	.A3(1'b1), .A2(1'b1), .A1(1'b1), .A0(1'b1));
endmodule // INTERNAL_RST



//================================================ MK_RST
module MK_RST (locked, clk, rst);
   //synthesis attribute keep_hierarchy of MK_RST is no;
   
   //------------------------------------------------
   input  locked, clk;
   output rst;

   //------------------------------------------------
   reg [19:0] cnt;
   
   //------------------------------------------------
   always @(posedge clk or negedge locked) 
     if (~locked)    cnt <= 20'h0;
     else if (~&cnt) cnt <= cnt + 20'h1;

   assign rst = ~&cnt;
endmodule // MK_RST
