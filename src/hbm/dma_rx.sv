`timescale 1 ns / 1 ps

`include "axi.sv"

module dma_rx #(
  parameter integer C_M_AXI_ADDR_WIDTH =  64 ,
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
  output wire                                  dma_data_valid,
  output wire [$clog2(C_M_AXI_TX_LEN)    -1:0] dma_data_counter,
  output wire [       C_M_AXI_DATA_WIDTH -1:0] dma_data,

  // Custom Interfacing Signals
  input  wire                                  dma_start,
  output wire                                  dma_done,
  input  wire [64-1:0]                         dma_address
  );

  // ---------------------------------------------------------------------------
  // Internal Signals
  // ---------------------------------------------------------------------------

  localparam dma_burst_count = C_M_AXI_BURST_LEN - 1;

  reg [$clog2(C_M_AXI_TX_LEN)-1:0] rx_counter = 'b0;

  // ---------------------------------------------------------------------------
  // AXI Master State Machine
  // ---------------------------------------------------------------------------

  typedef enum reg[2:0] {
    S_IDLE    = 3'b001, // Idle       - Waiting for command
    S_RD      = 3'b010, // Read       - Sending read address req.   (arvalid)
    S_RDDATA  = 3'b100  // Read Data  - Waiting for read data       ( rvalid)
  } t_state;

  (* fsm_encoding = "none" *) t_state state = S_IDLE;
  t_state next_state = S_IDLE;

  always_comb begin
    case (state)
      S_IDLE   : next_state <= (dma_start           ) ? S_RD     : S_IDLE   ;
      S_RD     : next_state <= (m_axi.arready       ) ? S_RDDATA : S_RD     ;
      S_RDDATA : next_state <= (m_axi.rlast &
                                m_axi.rvalid        ) ? S_IDLE   : S_RDDATA ;
      default  : next_state <=  S_IDLE;
    endcase
  end

  always_ff @(posedge ap_clk)
    state <= (!ap_rst_n) ? S_IDLE : next_state;

  // State nets
  wire is_state_idle    = (state == S_IDLE  );
  wire is_state_rd      = (state == S_RD    );
  wire is_state_rd_data = (state == S_RDDATA);

  // ---------------------------------------------------------------------------
  // Transfer Counter
  // ---------------------------------------------------------------------------

  always_ff @(posedge ap_clk)
    if      (dma_start)                   rx_counter <= 'b0;
    else if (m_axi.rvalid & m_axi.rready) rx_counter <= rx_counter + 1;

  // ---------------------------------------------------------------------------
  // Status Signals
  // ---------------------------------------------------------------------------

  reg dma_done_q = 1'b0;
  always_ff @(posedge ap_clk)
    if      (dma_start)                                 dma_done_q <= 1'b0;
    else if (m_axi.rready & m_axi.rvalid & m_axi.rlast) dma_done_q <= 1'b1;

  assign dma_done = dma_done_q;

  // ---------------------------------------------------------------------------
  // AXI Bus Connections
  // ---------------------------------------------------------------------------

  // Write Address
  assign m_axi.awaddr  = 'b0;
  assign m_axi.awlen   = 'b0;
  assign m_axi.awsize  = 'b0;
  assign m_axi.awburst = 'b0;
  assign m_axi.awvalid = 'b0;

  // Write Data
  assign m_axi.wdata   = 'b0;
  assign m_axi.wstrb   = 'b0;
  assign m_axi.wlast   = 'b0;
  assign m_axi.wvalid  = 'b0;

  // Write Response
  assign m_axi.bready  = 'b0;

  // Read Address
  assign m_axi.araddr  = dma_address;
  assign m_axi.arlen   = dma_burst_count; // Num of bursts
  assign m_axi.arsize  = 3'b101;          // 32-bytes (256-bit) per transfer
  assign m_axi.arburst = 2'b01;           // Incremental burst
  assign m_axi.arvalid = is_state_rd;

  // Read Data
  assign m_axi.rready  = is_state_rd_data;

  // ---------------------------------------------------------------------------
  // Received Data
  // ---------------------------------------------------------------------------

  reg                                  dma_data_valid_r   = 'b0;
  reg [$clog2(C_M_AXI_TX_LEN    )-1:0] dma_data_counter_r = 'b0;
  reg [       C_M_AXI_DATA_WIDTH -1:0] dma_data_r         = 'b0;

  always_ff @(posedge ap_clk) begin
    dma_data_valid_r    <= m_axi.rvalid & m_axi.rready;
    dma_data_counter_r  <= rx_counter;
    dma_data_r          <= m_axi.rdata;
  end

  assign dma_data_valid   = dma_data_valid_r;
  assign dma_data_counter = dma_data_counter_r;
  assign dma_data         = dma_data_r;

endmodule