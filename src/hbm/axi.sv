`ifndef AXI_INTERFACE
`define AXI_INTERFACE

interface axi4_t #(
  parameter int unsigned AXI_ADDR_WIDTH =  64,
  parameter int unsigned AXI_DATA_WIDTH = 256
);

  logic [AXI_ADDR_WIDTH-1:0]    awaddr;
  logic [8-1:0]                 awlen;
  logic [2:0]                   awsize;
  logic [1:0]                   awburst;
  logic                         awvalid;
  logic                         awready;

  logic [AXI_DATA_WIDTH-1:0]    wdata;
  logic [AXI_DATA_WIDTH/8-1:0]  wstrb;
  logic                         wlast;
  logic                         wvalid;
  logic                         wready;

  logic                         bvalid;
  logic                         bready;

  logic [AXI_ADDR_WIDTH-1:0]    araddr;
  logic [8-1:0]                 arlen;
  logic [2:0]                   arsize;
  logic [1:0]                   arburst;
  logic                         arvalid;
  logic                         arready;

  logic [AXI_DATA_WIDTH-1:0]    rdata;
  logic                         rlast;
  logic                         rvalid;
  logic                         rready;

  modport master (
    output awaddr, awlen, awsize, awburst, awvalid, input awready,
    output wdata, wstrb, wlast, wvalid, input wready,
    output bready, input bvalid,
    output araddr, arlen, arsize, arburst, arvalid, input arready,
    output rready, input rdata, rlast, rvalid
  );

  modport slave (
    input awaddr, awlen, awsize, awburst, awvalid, output awready,
    input wdata, wstrb, wlast, wvalid, output wready,
    input bready, output bvalid,
    input araddr, arlen, arsize, arburst, arvalid, output arready,
    input rready, output rdata, rlast, rvalid
  );

endinterface : axi4_t

`endif
