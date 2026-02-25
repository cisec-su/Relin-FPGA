`timescale 1ns/1ps

// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// ==============================================================

module csrs
#(parameter
  C_S_AXI_ADDR_WIDTH = 12,
  C_S_AXI_DATA_WIDTH = 32
)(
  input  wire                             ACLK,
  input  wire                             ARESET,
  input  wire                             ACLK_EN,
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]    AWADDR,
  input  wire                             AWVALID,
  output wire                             AWREADY,
  input  wire [C_S_AXI_DATA_WIDTH-1:0]    WDATA,
  input  wire [C_S_AXI_DATA_WIDTH/8-1:0]  WSTRB,
  input  wire                             WVALID,
  output wire                             WREADY,
  output wire [1:0]                       BRESP,
  output wire                             BVALID,
  input  wire                             BREADY,
  input  wire [C_S_AXI_ADDR_WIDTH-1:0]    ARADDR,
  input  wire                             ARVALID,
  output wire                             ARREADY,
  output wire [C_S_AXI_DATA_WIDTH-1:0]    RDATA,
  output wire [1:0]                       RRESP,
  output wire                             RVALID,
  input  wire                             RREADY,
  output wire                             interrupt,
  output wire                             ap_start,
  input  wire                             ap_done,
  input  wire                             ap_ready,
  input  wire                             ap_idle,
  // Custom Ap Control/Status Ports:
  output wire [32-1:0]                    ap_control,
  input  wire [32-1:0]                    ap_status,
  input  wire [32-1:0]                    ap_debug,
  input  wire [32-1:0]                    ap_timing,
  // DMA Control Ports:
  output wire [32-1:0]                    hbm_params_0,
  output wire [32-1:0]                    hbm_params_1,
  output wire [64-1:0]                    hbm_address00,
  output wire [64-1:0]                    hbm_address01,
  output wire [64-1:0]                    hbm_address02,
  output wire [64-1:0]                    hbm_address03,
  output wire [64-1:0]                    hbm_address04,
  output wire [64-1:0]                    hbm_address05,
  output wire [64-1:0]                    hbm_address06,
  output wire [64-1:0]                    hbm_address07,
  output wire [64-1:0]                    hbm_address08,
  output wire [64-1:0]                    hbm_address09,
  output wire [64-1:0]                    hbm_address10,
  output wire [64-1:0]                    hbm_address11,
  output wire [64-1:0]                    hbm_address12,
  output wire [64-1:0]                    hbm_address13,
  output wire [64-1:0]                    hbm_address14,
  output wire [64-1:0]                    hbm_address15,
  output wire [64-1:0]                    hbm_address16,
  output wire [64-1:0]                    hbm_address17,
  output wire [64-1:0]                    hbm_address18,
  output wire [64-1:0]                    hbm_address19,
  output wire [64-1:0]                    hbm_address20,
  output wire [64-1:0]                    hbm_address21,
  output wire [64-1:0]                    hbm_address22,
  output wire [64-1:0]                    hbm_address23,
  output wire [64-1:0]                    hbm_address24,
  output wire [64-1:0]                    hbm_address25,
  output wire [64-1:0]                    hbm_address26,
  output wire [64-1:0]                    hbm_address27,
  output wire [64-1:0]                    hbm_address28,
  output wire [64-1:0]                    hbm_address29,
  output wire [64-1:0]                    hbm_address30,
  output wire [64-1:0]                    hbm_address31,
  input  wire [32-1:0]                    ap_debug2,
  input  wire [32-1:0]                    ap_debug3,
  input  wire [32-1:0]                    ap_debug4,
  input  wire [32-1:0]                    ap_debug5,
  input  wire [32-1:0]                    ap_debug6,
  input  wire [32-1:0]                    ap_debug7,
  input  wire [32-1:0]                    ap_debug8,
  input  wire [32-1:0]                    ap_debug9,
  input  wire [32-1:0]                    ap_debug10,
  input  wire [32-1:0]                    ap_debug11,
  input  wire [32-1:0]                    ap_debug12,
  input  wire [32-1:0]                    ap_debug13,
  input  wire [32-1:0]                    ap_debug14,
  input  wire [32-1:0]                    ap_debug15,
  input  wire [32-1:0]                    ap_debug16,
  input  wire [32-1:0]                    ap_debug17,
  input  wire [32-1:0]                    ap_debug18,
  input  wire [32-1:0]                    ap_debug19,
  input  wire [32-1:0]                    ap_debug20,
  input  wire [32-1:0]                    ap_debug21,
  input  wire [32-1:0]                    ap_debug22,
  input  wire [32-1:0]                    ap_debug23,
  input  wire [32-1:0]                    ap_debug24,
  input  wire [32-1:0]                    ap_debug25,
  input  wire [32-1:0]                    ap_debug26,
  input  wire [32-1:0]                    ap_debug27,
  input  wire [32-1:0]                    ap_debug28,
  input  wire [32-1:0]                    ap_debug29,
  input  wire [32-1:0]                    ap_debug30,
  input  wire [32-1:0]                    ap_debug31

);
  //------------------------Address Info-------------------
  // 0x00 : Control signals
  //        bit 0  - ap_start (Read/Write/COH)
  //        bit 1  - ap_done (Read/COR)
  //        bit 2  - ap_idle (Read)
  //        bit 3  - ap_ready (Read)
  //        bit 7  - auto_restart (Read/Write)
  //        others - reserved
  //
  // 0x04 : Global Interrupt Enable Register
  //        bit 0  - Global Interrupt Enable (Read/Write)
  //        others - reserved
  //
  // 0x08 : IP Interrupt Enable Register (Read/Write)
  //        bit 0  - Channel 0 (ap_done)
  //        bit 1  - Channel 1 (ap_ready)
  //        others - reserved
  //
  // 0x0c : IP Interrupt Status Register (Read/TOW)
  //        bit 0  - Channel 0 (ap_done)
  //        bit 1  - Channel 1 (ap_ready)
  //        others - reserved

  // SC  = Self Clear
  // COR = Clear on Read
  // TOW = Toggle on Write
  // COH = Clear on Handshake


  //------------------------Parameter----------------------
  localparam
    ADDR_AP_CTRL         = 9'h000,
    ADDR_GIE             = 9'h004,
    ADDR_IER             = 9'h008,
    ADDR_ISR             = 9'h00c,
    ADDR_AP_CONTROL      = 9'h010,
    ADDR_AP_STATUS       = 9'h014,
    ADDR_AP_DEBUG        = 9'h018,
    ADDR_AP_TIMING       = 9'h01c,
    ADDR_HBM_PARAMS_0    = 9'h020,
    ADDR_HBM_PARAMS_1    = 9'h024,
    ADDR_HBM_ADDR00_0    = 9'h028,
    ADDR_HBM_ADDR00_1    = 9'h02c,
    ADDR_HBM_ADDR01_0    = 9'h030,
    ADDR_HBM_ADDR01_1    = 9'h034,
    ADDR_HBM_ADDR02_0    = 9'h038,
    ADDR_HBM_ADDR02_1    = 9'h03c,
    ADDR_HBM_ADDR03_0    = 9'h040,
    ADDR_HBM_ADDR03_1    = 9'h044,
    ADDR_HBM_ADDR04_0    = 9'h048,
    ADDR_HBM_ADDR04_1    = 9'h04c,
    ADDR_HBM_ADDR05_0    = 9'h050,
    ADDR_HBM_ADDR05_1    = 9'h054,
    ADDR_HBM_ADDR06_0    = 9'h058,
    ADDR_HBM_ADDR06_1    = 9'h05c,
    ADDR_HBM_ADDR07_0    = 9'h060,
    ADDR_HBM_ADDR07_1    = 9'h064,
    ADDR_HBM_ADDR08_0    = 9'h068,
    ADDR_HBM_ADDR08_1    = 9'h06c,
    ADDR_HBM_ADDR09_0    = 9'h070,
    ADDR_HBM_ADDR09_1    = 9'h074,
    ADDR_HBM_ADDR10_0    = 9'h078,
    ADDR_HBM_ADDR10_1    = 9'h07c,
    ADDR_HBM_ADDR11_0    = 9'h080,
    ADDR_HBM_ADDR11_1    = 9'h084,
    ADDR_HBM_ADDR12_0    = 9'h088,
    ADDR_HBM_ADDR12_1    = 9'h08c,
    ADDR_HBM_ADDR13_0    = 9'h090,
    ADDR_HBM_ADDR13_1    = 9'h094,
    ADDR_HBM_ADDR14_0    = 9'h098,
    ADDR_HBM_ADDR14_1    = 9'h09c,
    ADDR_HBM_ADDR15_0    = 9'h0a0,
    ADDR_HBM_ADDR15_1    = 9'h0a4,
    ADDR_HBM_ADDR16_0    = 9'h0a8,
    ADDR_HBM_ADDR16_1    = 9'h0ac,
    ADDR_HBM_ADDR17_0    = 9'h0b0,
    ADDR_HBM_ADDR17_1    = 9'h0b4,
    ADDR_HBM_ADDR18_0    = 9'h0b8,
    ADDR_HBM_ADDR18_1    = 9'h0bc,
    ADDR_HBM_ADDR19_0    = 9'h0c0,
    ADDR_HBM_ADDR19_1    = 9'h0c4,
    ADDR_HBM_ADDR20_0    = 9'h0c8,
    ADDR_HBM_ADDR20_1    = 9'h0cc,
    ADDR_HBM_ADDR21_0    = 9'h0d0,
    ADDR_HBM_ADDR21_1    = 9'h0d4,
    ADDR_HBM_ADDR22_0    = 9'h0d8,
    ADDR_HBM_ADDR22_1    = 9'h0dc,
    ADDR_HBM_ADDR23_0    = 9'h0e0,
    ADDR_HBM_ADDR23_1    = 9'h0e4,
    ADDR_HBM_ADDR24_0    = 9'h0e8,
    ADDR_HBM_ADDR24_1    = 9'h0ec,
    ADDR_HBM_ADDR25_0    = 9'h0f0,
    ADDR_HBM_ADDR25_1    = 9'h0f4,
    ADDR_HBM_ADDR26_0    = 9'h0f8,
    ADDR_HBM_ADDR26_1    = 9'h0fc,
    ADDR_HBM_ADDR27_0    = 9'h100,
    ADDR_HBM_ADDR27_1    = 9'h104,
    ADDR_HBM_ADDR28_0    = 9'h108,
    ADDR_HBM_ADDR28_1    = 9'h10c,
    ADDR_HBM_ADDR29_0    = 9'h110,
    ADDR_HBM_ADDR29_1    = 9'h114,
    ADDR_HBM_ADDR30_0    = 9'h118,
    ADDR_HBM_ADDR30_1    = 9'h11c,
    ADDR_HBM_ADDR31_0    = 9'h120,
    ADDR_HBM_ADDR31_1    = 9'h124,
    ADDR_AP_DEBUG2       = 9'h128,
    ADDR_AP_DEBUG3       = 9'h12C,
    ADDR_AP_DEBUG4       = 9'h130,
    ADDR_AP_DEBUG5       = 9'h134,
    ADDR_AP_DEBUG6       = 9'h138,
    ADDR_AP_DEBUG7       = 9'h13C,
    ADDR_AP_DEBUG8       = 9'h140,
    ADDR_AP_DEBUG9       = 9'h144,
    ADDR_AP_DEBUG10      = 9'h148,
    ADDR_AP_DEBUG11      = 9'h14C,
    ADDR_AP_DEBUG12      = 9'h150,
    ADDR_AP_DEBUG13      = 9'h154,
    ADDR_AP_DEBUG14      = 9'h158,
    ADDR_AP_DEBUG15      = 9'h15C,
    ADDR_AP_DEBUG16      = 9'h160,
    ADDR_AP_DEBUG17      = 9'h164,
    ADDR_AP_DEBUG18      = 9'h168,
    ADDR_AP_DEBUG19      = 9'h16C,
    ADDR_AP_DEBUG20      = 9'h170,
    ADDR_AP_DEBUG21      = 9'h174,
    ADDR_AP_DEBUG22      = 9'h178,
    ADDR_AP_DEBUG23      = 9'h17C,
    ADDR_AP_DEBUG24      = 9'h180,
    ADDR_AP_DEBUG25      = 9'h184,
    ADDR_AP_DEBUG26      = 9'h188,
    ADDR_AP_DEBUG27      = 9'h18C,
    ADDR_AP_DEBUG28      = 9'h190,
    ADDR_AP_DEBUG29      = 9'h194,
    ADDR_AP_DEBUG30      = 9'h198,
    ADDR_AP_DEBUG31      = 9'h19C,

    WRIDLE               = 2'd0,
    WRDATA               = 2'd1,
    WRRESP               = 2'd2,
    WRRESET              = 2'd3,
    RDIDLE               = 2'd0,
    RDDATA               = 2'd1,
    RDRESET              = 2'd2,
    ADDR_BITS            = 9;

  //------------------------Local signal-------------------
  reg  [1:0]           wstate = WRRESET;
  reg  [1:0]           wnext;
  reg  [ADDR_BITS-1:0] waddr;
  wire [31:0]          wmask;
  wire                 aw_hs;
  wire                 w_hs;
  reg  [1:0]           rstate = RDRESET;
  reg  [1:0]           rnext;
  reg  [31:0]          rdata;
  wire                 ar_hs;
  wire [ADDR_BITS-1:0] raddr;

  wire                 int_ap_idle;
  wire                 int_ap_ready;
  wire                 int_ap_done;

  // internal registers
  reg                  int_ap_done_q = 1'b0;
  reg                  int_ap_start = 1'b0;
  reg                  int_auto_restart = 1'b0;
  reg                  int_gie = 1'b0;
  reg  [ 1:0]          int_ier = 2'b0;
  reg  [ 1:0]          int_isr = 2'b0;
  reg  [31:0]          int_ap_control = 32'b0;
  reg  [31:0]          int_ap_status = 32'b0;
  reg  [31:0]          int_ap_debug = 32'b0;
  reg  [31:0]          int_ap_debug2  = 32'b0;
  reg  [31:0]          int_ap_debug3  = 32'b0;
  reg  [31:0]          int_ap_debug4  = 32'b0;
  reg  [31:0]          int_ap_debug5  = 32'b0;
  reg  [31:0]          int_ap_debug6  = 32'b0;
  reg  [31:0]          int_ap_debug7  = 32'b0;
  reg  [31:0]          int_ap_debug8  = 32'b0;
  reg  [31:0]          int_ap_debug9  = 32'b0;
  reg  [31:0]          int_ap_debug10 = 32'b0;
  reg  [31:0]          int_ap_debug11 = 32'b0;
  reg  [31:0]          int_ap_debug12 = 32'b0;
  reg  [31:0]          int_ap_debug13 = 32'b0;
  reg  [31:0]          int_ap_debug14 = 32'b0;
  reg  [31:0]          int_ap_debug15 = 32'b0;
  reg  [31:0]          int_ap_debug16 = 32'b0;
  reg  [31:0]          int_ap_debug17 = 32'b0;
  reg  [31:0]          int_ap_debug18 = 32'b0;
  reg  [31:0]          int_ap_debug19 = 32'b0;
  reg  [31:0]          int_ap_debug20 = 32'b0;
  reg  [31:0]          int_ap_debug21 = 32'b0;
  reg  [31:0]          int_ap_debug22 = 32'b0;
  reg  [31:0]          int_ap_debug23 = 32'b0;
  reg  [31:0]          int_ap_debug24 = 32'b0;
  reg  [31:0]          int_ap_debug25 = 32'b0;
  reg  [31:0]          int_ap_debug26 = 32'b0;
  reg  [31:0]          int_ap_debug27 = 32'b0;
  reg  [31:0]          int_ap_debug28 = 32'b0;
  reg  [31:0]          int_ap_debug29 = 32'b0;
  reg  [31:0]          int_ap_debug30 = 32'b0;
  reg  [31:0]          int_ap_debug31 = 32'b0;
  reg  [31:0]          int_ap_timing = 32'b0;
  reg  [31:0]          int_hbm_params_0 = 32'b0;
  reg  [31:0]          int_hbm_params_1 = 32'b0;
  reg  [63:0]          int_hbm_address00;
  reg  [63:0]          int_hbm_address01;
  reg  [63:0]          int_hbm_address02;
  reg  [63:0]          int_hbm_address03;
  reg  [63:0]          int_hbm_address04;
  reg  [63:0]          int_hbm_address05;
  reg  [63:0]          int_hbm_address06;
  reg  [63:0]          int_hbm_address07;
  reg  [63:0]          int_hbm_address08;
  reg  [63:0]          int_hbm_address09;
  reg  [63:0]          int_hbm_address10;
  reg  [63:0]          int_hbm_address11;
  reg  [63:0]          int_hbm_address12;
  reg  [63:0]          int_hbm_address13;
  reg  [63:0]          int_hbm_address14;
  reg  [63:0]          int_hbm_address15;
  reg  [63:0]          int_hbm_address16;
  reg  [63:0]          int_hbm_address17;
  reg  [63:0]          int_hbm_address18;
  reg  [63:0]          int_hbm_address19;
  reg  [63:0]          int_hbm_address20;
  reg  [63:0]          int_hbm_address21;
  reg  [63:0]          int_hbm_address22;
  reg  [63:0]          int_hbm_address23;
  reg  [63:0]          int_hbm_address24;
  reg  [63:0]          int_hbm_address25;
  reg  [63:0]          int_hbm_address26;
  reg  [63:0]          int_hbm_address27;
  reg  [63:0]          int_hbm_address28;
  reg  [63:0]          int_hbm_address29;
  reg  [63:0]          int_hbm_address30;
  reg  [63:0]          int_hbm_address31;

  //------------------------Instantiation------------------

  //------------------------AXI write fsm------------------
  assign AWREADY = (wstate == WRIDLE);
  assign WREADY  = (wstate == WRDATA);
  assign BRESP   = 2'b00;  // OKAY
  assign BVALID  = (wstate == WRRESP);
  assign wmask   = {{8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}}};
  assign aw_hs   = AWVALID & AWREADY;
  assign w_hs    = WVALID & WREADY;

  // wstate
  always @(posedge ACLK) begin
    if (ARESET)
      wstate <= WRRESET;
    else if (ACLK_EN)
      wstate <= wnext;
  end

  // wnext
  always @(*) begin
    case (wstate)
      WRIDLE:
        if (AWVALID)
          wnext = WRDATA;
        else
          wnext = WRIDLE;
      WRDATA:
        if (WVALID)
          wnext = WRRESP;
        else
          wnext = WRDATA;
      WRRESP:
        if (BREADY)
          wnext = WRIDLE;
        else
          wnext = WRRESP;
      default:
        wnext = WRIDLE;
    endcase
  end

  // waddr
  always @(posedge ACLK) begin
    if (ACLK_EN) begin
      if (aw_hs)
        waddr <= AWADDR[ADDR_BITS-1:0];
    end
  end

  //------------------------AXI read fsm-------------------
  assign ARREADY = (rstate == RDIDLE);
  assign RDATA   = rdata;
  assign RRESP   = 2'b00;  // OKAY
  assign RVALID  = (rstate == RDDATA);
  assign ar_hs   = ARVALID & ARREADY;
  assign raddr   = ARADDR[ADDR_BITS-1:0];

  // rstate
  always @(posedge ACLK) begin
    if (ARESET)
      rstate <= RDRESET;
    else if (ACLK_EN)
      rstate <= rnext;
  end

  // rnext
  always @(*) begin
    case (rstate)
      RDIDLE:
        if (ARVALID)
          rnext = RDDATA;
        else
          rnext = RDIDLE;
      RDDATA:
        if (RREADY & RVALID)
          rnext = RDIDLE;
        else
          rnext = RDDATA;
      default:
        rnext = RDIDLE;
    endcase
  end

  // rdata
  always @(posedge ACLK) begin
    if (ACLK_EN) begin
      if (ar_hs) begin
        rdata <= 1'b0;
        case (raddr)
          ADDR_AP_CTRL: begin
            rdata[0] <= int_ap_start;
            rdata[1] <= int_ap_done;
            rdata[2] <= int_ap_idle;
            rdata[3] <= int_ap_ready;
            rdata[7] <= int_auto_restart;
            end
          ADDR_GIE          : rdata <= int_gie;
          ADDR_IER          : rdata <= int_ier;
          ADDR_ISR          : rdata <= int_isr;
          ADDR_AP_CONTROL   : rdata <= int_ap_control;
          ADDR_AP_STATUS    : rdata <= int_ap_status;
          ADDR_AP_DEBUG     : rdata <= int_ap_debug;
          ADDR_AP_TIMING    : rdata <= int_ap_timing;
          ADDR_HBM_PARAMS_0 : rdata <= int_hbm_params_0;
          ADDR_HBM_PARAMS_1 : rdata <= int_hbm_params_1;
          ADDR_HBM_ADDR00_0 : rdata <= 'b0; // int_hbm_address00[31: 0];
          ADDR_HBM_ADDR00_1 : rdata <= 'b0; // int_hbm_address00[63:32];
          ADDR_HBM_ADDR01_0 : rdata <= 'b0; // int_hbm_address01[31: 0];
          ADDR_HBM_ADDR01_1 : rdata <= 'b0; // int_hbm_address01[63:32];
          ADDR_HBM_ADDR02_0 : rdata <= 'b0; // int_hbm_address02[31: 0];
          ADDR_HBM_ADDR02_1 : rdata <= 'b0; // int_hbm_address02[63:32];
          ADDR_HBM_ADDR03_0 : rdata <= 'b0; // int_hbm_address03[31: 0];
          ADDR_HBM_ADDR03_1 : rdata <= 'b0; // int_hbm_address03[63:32];
          ADDR_HBM_ADDR04_0 : rdata <= 'b0; // int_hbm_address04[31: 0];
          ADDR_HBM_ADDR04_1 : rdata <= 'b0; // int_hbm_address04[63:32];
          ADDR_HBM_ADDR05_0 : rdata <= 'b0; // int_hbm_address05[31: 0];
          ADDR_HBM_ADDR05_1 : rdata <= 'b0; // int_hbm_address05[63:32];
          ADDR_HBM_ADDR06_0 : rdata <= 'b0; // int_hbm_address06[31: 0];
          ADDR_HBM_ADDR06_1 : rdata <= 'b0; // int_hbm_address06[63:32];
          ADDR_HBM_ADDR07_0 : rdata <= 'b0; // int_hbm_address07[31: 0];
          ADDR_HBM_ADDR07_1 : rdata <= 'b0; // int_hbm_address07[63:32];
          ADDR_HBM_ADDR08_0 : rdata <= 'b0; // int_hbm_address08[31: 0];
          ADDR_HBM_ADDR08_1 : rdata <= 'b0; // int_hbm_address08[63:32];
          ADDR_HBM_ADDR09_0 : rdata <= 'b0; // int_hbm_address09[31: 0];
          ADDR_HBM_ADDR09_1 : rdata <= 'b0; // int_hbm_address09[63:32];
          ADDR_HBM_ADDR10_0 : rdata <= 'b0; // int_hbm_address10[31: 0];
          ADDR_HBM_ADDR10_1 : rdata <= 'b0; // int_hbm_address10[63:32];
          ADDR_HBM_ADDR11_0 : rdata <= 'b0; // int_hbm_address11[31: 0];
          ADDR_HBM_ADDR11_1 : rdata <= 'b0; // int_hbm_address11[63:32];
          ADDR_HBM_ADDR12_0 : rdata <= 'b0; // int_hbm_address12[31: 0];
          ADDR_HBM_ADDR12_1 : rdata <= 'b0; // int_hbm_address12[63:32];
          ADDR_HBM_ADDR13_0 : rdata <= 'b0; // int_hbm_address13[31: 0];
          ADDR_HBM_ADDR13_1 : rdata <= 'b0; // int_hbm_address13[63:32];
          ADDR_HBM_ADDR14_0 : rdata <= 'b0; // int_hbm_address14[31: 0];
          ADDR_HBM_ADDR14_1 : rdata <= 'b0; // int_hbm_address14[63:32];
          ADDR_HBM_ADDR15_0 : rdata <= 'b0; // int_hbm_address15[31: 0];
          ADDR_HBM_ADDR15_1 : rdata <= 'b0; // int_hbm_address15[63:32];
          ADDR_HBM_ADDR16_0 : rdata <= 'b0; // int_hbm_address16[31: 0];
          ADDR_HBM_ADDR16_1 : rdata <= 'b0; // int_hbm_address16[63:32];
          ADDR_HBM_ADDR17_0 : rdata <= 'b0; // int_hbm_address17[31: 0];
          ADDR_HBM_ADDR17_1 : rdata <= 'b0; // int_hbm_address17[63:32];
          ADDR_HBM_ADDR18_0 : rdata <= 'b0; // int_hbm_address18[31: 0];
          ADDR_HBM_ADDR18_1 : rdata <= 'b0; // int_hbm_address18[63:32];
          ADDR_HBM_ADDR19_0 : rdata <= 'b0; // int_hbm_address19[31: 0];
          ADDR_HBM_ADDR19_1 : rdata <= 'b0; // int_hbm_address19[63:32];
          ADDR_HBM_ADDR20_0 : rdata <= 'b0; // int_hbm_address20[31: 0];
          ADDR_HBM_ADDR20_1 : rdata <= 'b0; // int_hbm_address20[63:32];
          ADDR_HBM_ADDR21_0 : rdata <= 'b0; // int_hbm_address21[31: 0];
          ADDR_HBM_ADDR21_1 : rdata <= 'b0; // int_hbm_address21[63:32];
          ADDR_HBM_ADDR22_0 : rdata <= 'b0; // int_hbm_address22[31: 0];
          ADDR_HBM_ADDR22_1 : rdata <= 'b0; // int_hbm_address22[63:32];
          ADDR_HBM_ADDR23_0 : rdata <= 'b0; // int_hbm_address23[31: 0];
          ADDR_HBM_ADDR23_1 : rdata <= 'b0; // int_hbm_address23[63:32];
          ADDR_HBM_ADDR24_0 : rdata <= 'b0; // int_hbm_address24[31: 0];
          ADDR_HBM_ADDR24_1 : rdata <= 'b0; // int_hbm_address24[63:32];
          ADDR_HBM_ADDR25_0 : rdata <= 'b0; // int_hbm_address25[31: 0];
          ADDR_HBM_ADDR25_1 : rdata <= 'b0; // int_hbm_address25[63:32];
          ADDR_HBM_ADDR26_0 : rdata <= 'b0; // int_hbm_address26[31: 0];
          ADDR_HBM_ADDR26_1 : rdata <= 'b0; // int_hbm_address26[63:32];
          ADDR_HBM_ADDR27_0 : rdata <= 'b0; // int_hbm_address27[31: 0];
          ADDR_HBM_ADDR27_1 : rdata <= 'b0; // int_hbm_address27[63:32];
          ADDR_HBM_ADDR28_0 : rdata <= 'b0; // int_hbm_address28[31: 0];
          ADDR_HBM_ADDR28_1 : rdata <= 'b0; // int_hbm_address28[63:32];
          ADDR_HBM_ADDR29_0 : rdata <= 'b0; // int_hbm_address29[31: 0];
          ADDR_HBM_ADDR29_1 : rdata <= 'b0; // int_hbm_address29[63:32];
          ADDR_HBM_ADDR30_0 : rdata <= 'b0; // int_hbm_address30[31: 0];
          ADDR_HBM_ADDR30_1 : rdata <= 'b0; // int_hbm_address30[63:32];
          ADDR_HBM_ADDR31_0 : rdata <= 'b0; // int_hbm_address31[31: 0];
          ADDR_HBM_ADDR31_1 : rdata <= 'b0; // int_hbm_address31[63:32];
          ADDR_AP_DEBUG2     : rdata <= int_ap_debug2;
          ADDR_AP_DEBUG3     : rdata <= int_ap_debug3;
          ADDR_AP_DEBUG4     : rdata <= int_ap_debug4;
          ADDR_AP_DEBUG5     : rdata <= int_ap_debug5;
          ADDR_AP_DEBUG6     : rdata <= int_ap_debug6;
          ADDR_AP_DEBUG7     : rdata <= int_ap_debug7;
          ADDR_AP_DEBUG8     : rdata <= int_ap_debug8;
          ADDR_AP_DEBUG9     : rdata <= int_ap_debug9;
          ADDR_AP_DEBUG10    : rdata <= int_ap_debug10;
          ADDR_AP_DEBUG11    : rdata <= int_ap_debug11;
          ADDR_AP_DEBUG12    : rdata <= int_ap_debug12;
          ADDR_AP_DEBUG13    : rdata <= int_ap_debug13;
          ADDR_AP_DEBUG14    : rdata <= int_ap_debug14;
          ADDR_AP_DEBUG15    : rdata <= int_ap_debug15;
          ADDR_AP_DEBUG16    : rdata <= int_ap_debug16;
          ADDR_AP_DEBUG17    : rdata <= int_ap_debug17;
          ADDR_AP_DEBUG18    : rdata <= int_ap_debug18;
          ADDR_AP_DEBUG19    : rdata <= int_ap_debug19;
          ADDR_AP_DEBUG20    : rdata <= int_ap_debug20;
          ADDR_AP_DEBUG21    : rdata <= int_ap_debug21;
          ADDR_AP_DEBUG22    : rdata <= int_ap_debug22;
          ADDR_AP_DEBUG23    : rdata <= int_ap_debug23;
          ADDR_AP_DEBUG24    : rdata <= int_ap_debug24;
          ADDR_AP_DEBUG25    : rdata <= int_ap_debug25;
          ADDR_AP_DEBUG26    : rdata <= int_ap_debug26;
          ADDR_AP_DEBUG27    : rdata <= int_ap_debug27;
          ADDR_AP_DEBUG28    : rdata <= int_ap_debug28;
          ADDR_AP_DEBUG29    : rdata <= int_ap_debug29;
          ADDR_AP_DEBUG30    : rdata <= int_ap_debug30;
          ADDR_AP_DEBUG31    : rdata <= int_ap_debug31;
        endcase
      end
    end
  end

  //------------------------Register logic-----------------

  assign interrupt     = int_gie & (|int_isr);
  assign ap_start      = int_ap_start;

  assign ap_control    = int_ap_control;
  // inputs: ap_status
  // inputs: ap_debug
  // inputs: ap_timing
  assign hbm_params_0  = int_hbm_params_0;
  assign hbm_params_1  = int_hbm_params_1;
  assign hbm_address00 = int_hbm_address00;
  assign hbm_address01 = int_hbm_address01;
  assign hbm_address02 = int_hbm_address02;
  assign hbm_address03 = int_hbm_address03;
  assign hbm_address04 = int_hbm_address04;
  assign hbm_address05 = int_hbm_address05;
  assign hbm_address06 = int_hbm_address06;
  assign hbm_address07 = int_hbm_address07;
  assign hbm_address08 = int_hbm_address08;
  assign hbm_address09 = int_hbm_address09;
  assign hbm_address10 = int_hbm_address10;
  assign hbm_address11 = int_hbm_address11;
  assign hbm_address12 = int_hbm_address12;
  assign hbm_address13 = int_hbm_address13;
  assign hbm_address14 = int_hbm_address14;
  assign hbm_address15 = int_hbm_address15;
  assign hbm_address16 = int_hbm_address16;
  assign hbm_address17 = int_hbm_address17;
  assign hbm_address18 = int_hbm_address18;
  assign hbm_address19 = int_hbm_address19;
  assign hbm_address20 = int_hbm_address20;
  assign hbm_address21 = int_hbm_address21;
  assign hbm_address22 = int_hbm_address22;
  assign hbm_address23 = int_hbm_address23;
  assign hbm_address24 = int_hbm_address24;
  assign hbm_address25 = int_hbm_address25;
  assign hbm_address26 = int_hbm_address26;
  assign hbm_address27 = int_hbm_address27;
  assign hbm_address28 = int_hbm_address28;
  assign hbm_address29 = int_hbm_address29;
  assign hbm_address30 = int_hbm_address30;
  assign hbm_address31 = int_hbm_address31;

  // int_ap_start
  always @(posedge ACLK) begin
    if (ARESET)
      int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
      if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0] && WDATA[0])
        int_ap_start <= 1'b1;
      else if (ap_ready)
        int_ap_start <= int_auto_restart; // clear on handshake/auto restart
    end
  end

  assign int_ap_done = ap_done | int_ap_done_q;
  // int_ap_done_q
  always @(posedge ACLK) begin
    if (ARESET)
      int_ap_done_q <= 1'b0;
    else if (ACLK_EN) begin
      if (ap_done)
        int_ap_done_q <= 1'b1;
      else if (ar_hs && raddr == ADDR_AP_CTRL)
        int_ap_done_q <= 1'b0; // clear on read
    end
  end

  assign int_ap_idle = ap_idle;

  assign int_ap_ready = ap_ready;

  // int_auto_restart
  always @(posedge ACLK) begin
    if (ARESET)
      int_auto_restart <= 1'b0;
    else if (ACLK_EN) begin
      if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0])
        int_auto_restart <=  WDATA[7];
    end
  end

  // int_gie
  always @(posedge ACLK) begin
    if (ARESET)
      int_gie <= 1'b0;
    else if (ACLK_EN) begin
      if (w_hs && waddr == ADDR_GIE && WSTRB[0])
        int_gie <= WDATA[0];
    end
  end

  // int_ier
  always @(posedge ACLK) begin
    if (ARESET)
      int_ier <= 1'b0;
    else if (ACLK_EN) begin
      if (w_hs && waddr == ADDR_IER && WSTRB[0])
        int_ier <= WDATA[1:0];
    end
  end

  // int_isr[0]
  always @(posedge ACLK) begin
    if (ARESET)
      int_isr[0] <= 1'b0;
    else if (ACLK_EN) begin
      if (int_ier[0] & ap_done)
        int_isr[0] <= 1'b1;
      else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
        int_isr[0] <= int_isr[0] ^ WDATA[0]; // toggle on write
    end
  end

  // int_isr[1]
  always @(posedge ACLK) begin
    if (ARESET)
      int_isr[1] <= 1'b0;
    else if (ACLK_EN) begin
      if (int_ier[1] & ap_ready)
        int_isr[1] <= 1'b1;
      else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
        int_isr[1] <= int_isr[1] ^ WDATA[1]; // toggle on write
    end
  end

  // int_dma_*
  always @(posedge ACLK) begin
    if (ARESET) begin
      int_ap_control    <= 'b0;
      int_ap_status     <= 'b0;
      int_ap_debug      <= 'b0;
      int_ap_debug2      <= 'b0;
      int_ap_debug3      <= 'b0;
      int_ap_debug4      <= 'b0;
      int_ap_debug5      <= 'b0;
      int_ap_debug6      <= 'b0;
      int_ap_debug7      <= 'b0;
      int_ap_debug8      <= 'b0;
      int_ap_debug9      <= 'b0;
      int_ap_debug10     <= 'b0;
      int_ap_debug11     <= 'b0;
      int_ap_debug12     <= 'b0;
      int_ap_debug13     <= 'b0;
      int_ap_debug14     <= 'b0;
      int_ap_debug15     <= 'b0;
      int_ap_debug16     <= 'b0;
      int_ap_debug17     <= 'b0;
      int_ap_debug18     <= 'b0;
      int_ap_debug19     <= 'b0;
      int_ap_debug20     <= 'b0;
      int_ap_debug21     <= 'b0;
      int_ap_debug22     <= 'b0;
      int_ap_debug23     <= 'b0;
      int_ap_debug24     <= 'b0;
      int_ap_debug25     <= 'b0;
      int_ap_debug26     <= 'b0;
      int_ap_debug27     <= 'b0;
      int_ap_debug28     <= 'b0;
      int_ap_debug29     <= 'b0;
      int_ap_debug30     <= 'b0;
      int_ap_debug31     <= 'b0;
      int_ap_timing     <= 'b0;
      int_hbm_params_0  <= 'b0;
      int_hbm_params_1  <= 'b0;
      int_hbm_address00 <= 'b0;
      int_hbm_address01 <= 'b0;
      int_hbm_address02 <= 'b0;
      int_hbm_address03 <= 'b0;
      int_hbm_address04 <= 'b0;
      int_hbm_address05 <= 'b0;
      int_hbm_address06 <= 'b0;
      int_hbm_address07 <= 'b0;
      int_hbm_address08 <= 'b0;
      int_hbm_address09 <= 'b0;
      int_hbm_address10 <= 'b0;
      int_hbm_address11 <= 'b0;
      int_hbm_address12 <= 'b0;
      int_hbm_address13 <= 'b0;
      int_hbm_address14 <= 'b0;
      int_hbm_address15 <= 'b0;
      int_hbm_address16 <= 'b0;
      int_hbm_address17 <= 'b0;
      int_hbm_address18 <= 'b0;
      int_hbm_address19 <= 'b0;
      int_hbm_address20 <= 'b0;
      int_hbm_address21 <= 'b0;
      int_hbm_address22 <= 'b0;
      int_hbm_address23 <= 'b0;
      int_hbm_address24 <= 'b0;
      int_hbm_address25 <= 'b0;
      int_hbm_address26 <= 'b0;
      int_hbm_address27 <= 'b0;
      int_hbm_address28 <= 'b0;
      int_hbm_address29 <= 'b0;
      int_hbm_address30 <= 'b0;
      int_hbm_address31 <= 'b0;
      
    end
    else if (ACLK_EN) begin
      if (w_hs && waddr == ADDR_AP_CONTROL   ) int_ap_control           <= (WDATA[31:0] & wmask) | (int_ap_control           & ~wmask);
      int_ap_status <= ap_status;
      int_ap_debug  <= ap_debug;
      int_ap_debug2  <= ap_debug2;
      int_ap_debug3  <= ap_debug3;
      int_ap_debug4  <= ap_debug4;
      int_ap_debug5  <= ap_debug5;
      int_ap_debug6  <= ap_debug6;
      int_ap_debug7  <= ap_debug7;
      int_ap_debug8  <= ap_debug8;
      int_ap_debug9  <= ap_debug9;
      int_ap_debug10 <= ap_debug10;
      int_ap_debug11 <= ap_debug11;
      int_ap_debug12 <= ap_debug12;
      int_ap_debug13 <= ap_debug13;
      int_ap_debug14 <= ap_debug14;
      int_ap_debug15 <= ap_debug15;
      int_ap_debug16 <= ap_debug16;
      int_ap_debug17 <= ap_debug17;
      int_ap_debug18 <= ap_debug18;
      int_ap_debug19 <= ap_debug19;
      int_ap_debug20 <= ap_debug20;
      int_ap_debug21 <= ap_debug21;
      int_ap_debug22 <= ap_debug22;
      int_ap_debug23 <= ap_debug23;
      int_ap_debug24 <= ap_debug24;
      int_ap_debug25 <= ap_debug25;
      int_ap_debug26 <= ap_debug26;
      int_ap_debug27 <= ap_debug27;
      int_ap_debug28 <= ap_debug28;
      int_ap_debug29 <= ap_debug29;
      int_ap_debug30 <= ap_debug30;
      int_ap_debug31 <= ap_debug31;
      int_ap_timing <= ap_timing;
      if (w_hs && waddr == ADDR_HBM_PARAMS_0 ) int_hbm_params_0         <= (WDATA[31:0] & wmask) | (int_hbm_params_0         & ~wmask);
      if (w_hs && waddr == ADDR_HBM_PARAMS_1 ) int_hbm_params_1         <= (WDATA[31:0] & wmask) | (int_hbm_params_1         & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR00_0 ) int_hbm_address00[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address00[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR00_1 ) int_hbm_address00[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address00[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR01_0 ) int_hbm_address01[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address01[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR01_1 ) int_hbm_address01[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address01[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR02_0 ) int_hbm_address02[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address02[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR02_1 ) int_hbm_address02[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address02[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR03_0 ) int_hbm_address03[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address03[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR03_1 ) int_hbm_address03[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address03[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR04_0 ) int_hbm_address04[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address04[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR04_1 ) int_hbm_address04[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address04[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR05_0 ) int_hbm_address05[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address05[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR05_1 ) int_hbm_address05[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address05[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR06_0 ) int_hbm_address06[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address06[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR06_1 ) int_hbm_address06[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address06[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR07_0 ) int_hbm_address07[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address07[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR07_1 ) int_hbm_address07[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address07[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR08_0 ) int_hbm_address08[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address08[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR08_1 ) int_hbm_address08[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address08[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR09_0 ) int_hbm_address09[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address09[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR09_1 ) int_hbm_address09[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address09[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR10_0 ) int_hbm_address10[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address10[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR10_1 ) int_hbm_address10[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address10[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR11_0 ) int_hbm_address11[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address11[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR11_1 ) int_hbm_address11[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address11[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR12_0 ) int_hbm_address12[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address12[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR12_1 ) int_hbm_address12[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address12[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR13_0 ) int_hbm_address13[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address13[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR13_1 ) int_hbm_address13[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address13[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR14_0 ) int_hbm_address14[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address14[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR14_1 ) int_hbm_address14[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address14[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR15_0 ) int_hbm_address15[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address15[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR15_1 ) int_hbm_address15[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address15[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR16_0 ) int_hbm_address16[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address16[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR16_1 ) int_hbm_address16[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address16[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR17_0 ) int_hbm_address17[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address17[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR17_1 ) int_hbm_address17[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address17[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR18_0 ) int_hbm_address18[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address18[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR18_1 ) int_hbm_address18[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address18[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR19_0 ) int_hbm_address19[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address19[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR19_1 ) int_hbm_address19[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address19[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR20_0 ) int_hbm_address20[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address20[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR20_1 ) int_hbm_address20[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address20[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR21_0 ) int_hbm_address21[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address21[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR21_1 ) int_hbm_address21[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address21[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR22_0 ) int_hbm_address22[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address22[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR22_1 ) int_hbm_address22[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address22[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR23_0 ) int_hbm_address23[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address23[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR23_1 ) int_hbm_address23[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address23[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR24_0 ) int_hbm_address24[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address24[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR24_1 ) int_hbm_address24[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address24[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR25_0 ) int_hbm_address25[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address25[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR25_1 ) int_hbm_address25[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address25[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR26_0 ) int_hbm_address26[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address26[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR26_1 ) int_hbm_address26[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address26[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR27_0 ) int_hbm_address27[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address27[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR27_1 ) int_hbm_address27[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address27[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR28_0 ) int_hbm_address28[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address28[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR28_1 ) int_hbm_address28[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address28[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR29_0 ) int_hbm_address29[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address29[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR29_1 ) int_hbm_address29[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address29[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR30_0 ) int_hbm_address30[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address30[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR30_1 ) int_hbm_address30[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address30[63:32] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR31_0 ) int_hbm_address31[31: 0] <= (WDATA[31:0] & wmask) | (int_hbm_address31[31: 0] & ~wmask);
      if (w_hs && waddr == ADDR_HBM_ADDR31_1 ) int_hbm_address31[63:32] <= (WDATA[31:0] & wmask) | (int_hbm_address31[63:32] & ~wmask);
    end
  end


//------------------------Memory logic-------------------

endmodule