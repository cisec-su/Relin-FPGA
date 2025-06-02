`timescale 1 ns / 1 ps

`include "axi.sv"

module dma_tx #(
  parameter integer C_M_AXI_ADDR_WIDTH =   64,
  parameter integer C_M_AXI_DATA_WIDTH =  256,
  parameter integer C_M_AXI_BURST_LEN  =  128,
  parameter integer C_M_AXI_TX_LEN     =  C_M_AXI_BURST_LEN
)
(
  // System Signals
  input  wire          ap_clk,
  input  wire          ap_rst_n,

  // AXI4 master interface m_axi
  axi4_t.master        m_axi,

  // Data connection
  input  wire                           dma_data_valid,
  input  wire [C_M_AXI_DATA_WIDTH -1:0] dma_data,

  input  wire                           dma_start,
  output wire                           dma_done,
  input  wire [64-1:0]                  dma_address,
  output wire                           dma_err_fifo_full,

  input  wire                           fifo_reset
  );

  // ---------------------------------------------------------------------------
  // Internal Signals
  // ---------------------------------------------------------------------------

  localparam dma_burst_count = C_M_AXI_BURST_LEN - 1;

  reg [$clog2(C_M_AXI_TX_LEN)-1:0] tx_counter = 'b0;

  wire         FIFOo_wren;
  wire [255:0] FIFOo_din;
  wire         FIFOo_rden;
  wire [255:0] FIFOo_dout;
  wire         FIFOo_empty;
  wire         FIFOo_full;

  fifo_sync FIFOo (
    .clk                ( ap_clk      ),
    .srst               ( fifo_reset  ),
    .wr_en              ( FIFOo_wren  ),
    .din                ( FIFOo_din   ),
    .rd_en              ( FIFOo_rden  ),
    .dout               ( FIFOo_dout  ),
    .full               ( FIFOo_full  ),
    .empty              ( FIFOo_empty )
  );

  // ---------------------------------------------------------------------------
  // AXI Master State Machine
  // ---------------------------------------------------------------------------

  typedef enum reg[3:0] {
    S_IDLE    = 4'b0001, // Idle       - Waiting for command
    S_WR      = 4'b0010, // Write      - Sending write addr. request (awvalid)
    S_WRDATA  = 4'b0100, // Write Data - Sending write data          ( wvalid)
    S_WRRESP  = 4'b1000  // Write Resp - Waiting for write resp.     ( bvalid)
  } t_state;

  (* fsm_encoding = "none" *) t_state state = S_IDLE;
  t_state next_state = S_IDLE;

  always_comb begin
    case (state)
      S_IDLE   : next_state <= (dma_start     ) ? S_WR     : S_IDLE   ;
      S_WR     : next_state <= (m_axi.awready ) ? S_WRDATA : S_WR     ;
      S_WRDATA : next_state <= (m_axi.wlast &
                                m_axi.wready  ) ? S_WRRESP : S_WRDATA ;
      S_WRRESP : next_state <= (m_axi.bvalid  ) ? S_IDLE   : S_WRRESP ;
      default  : next_state <=  S_IDLE;
    endcase
  end

  always_ff @(posedge ap_clk)
    state <= (!ap_rst_n) ? S_IDLE : next_state;

  // State nets
  wire is_state_idle    = (state == S_IDLE  );
  wire is_state_wr      = (state == S_WR    );
  wire is_state_wr_data = (state == S_WRDATA);
  wire is_state_wr_resp = (state == S_WRRESP);

  // ---------------------------------------------------------------------------
  // Transfer Counter
  // ---------------------------------------------------------------------------

  always_ff @(posedge ap_clk)
    if      (dma_start)                   tx_counter <= 'b0;
    else if (m_axi.wvalid & m_axi.wready) tx_counter <= tx_counter + 1;

  // ---------------------------------------------------------------------------
  // Status Signals
  // ---------------------------------------------------------------------------

  reg dma_done_q = 1'b0;
  always_ff @(posedge ap_clk)
    if      (dma_start)                   dma_done_q <= 1'b0;
    else if (m_axi.bready & m_axi.bvalid) dma_done_q <= 1'b1;

  assign dma_done = dma_done_q;

  // ---------------------------------------------------------------------------
  // AXI Bus Connections
  // ---------------------------------------------------------------------------

  // Write Address
  assign m_axi.awaddr  = dma_address;
  assign m_axi.awlen   = dma_burst_count; // Num of bursts
  assign m_axi.awsize  = 3'b101; // 32-bytes (256-bit) in each transfer
  assign m_axi.awburst = 2'b01; // Incremental burst
  assign m_axi.awvalid = is_state_wr;

  // Write Data
  assign m_axi.wdata   = FIFOo_dout;
  assign m_axi.wstrb   = 32'hFFFFFFFF;
  assign m_axi.wlast   = (tx_counter==dma_burst_count);
  assign m_axi.wvalid  = ~FIFOo_empty;

  // Write Response
  assign m_axi.bready  = is_state_wr_resp;

  // Read Address
  assign m_axi.araddr  = 'b0;
  assign m_axi.arlen   = 'b0;
  assign m_axi.arsize  = 'b0;
  assign m_axi.arburst = 'b0;
  assign m_axi.arvalid = 'b0;

  // Read Data
  assign m_axi.rready  = 'b0;

  //////////////////////////////////////////////////////////////////////////////
  // FIFO
  //////////////////////////////////////////////////////////////////////////////

  assign FIFOo_wren = dma_data_valid;
  assign FIFOo_din  = dma_data;

  assign FIFOo_rden = m_axi.wvalid & m_axi.wready;

  reg dma_err_fifo_full_r = 1'b0;
  always_ff @(posedge ap_clk)
    if (dma_start)
      dma_err_fifo_full_r <= 1'b0;
    else if (FIFOo_full & dma_data_valid)
      dma_err_fifo_full_r <= 1'b1;

  assign dma_err_fifo_full = dma_err_fifo_full_r;

endmodule