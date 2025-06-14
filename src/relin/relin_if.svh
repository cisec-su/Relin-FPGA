`ifndef RELIN_IF
`define RELIN_IF

interface relin_t
#(parameter LOGL = 30, 
  parameter LOGQ = 64, 
  parameter TP = 32, 
  parameter ID_WIDTH = 4);

// ========== Input ports ==========
logic                 i_p0_en;
logic [ID_WIDTH-1:0]  i_p0_id;
logic [LOGL-1:0]      i_p0_idx;

logic                 i_p1_en;
logic [ID_WIDTH-1:0]  i_p1_id;
logic [LOGL-1:0]      i_p1_idx;
logic [LOGL-1:0]      i_p1_idy;

logic                 i_p2_en;
logic [LOGL-1:0]      i_p2_idx;
logic [LOGL-1:0]      i_p2_idy;

logic                 o_p3_en;
logic [ID_WIDTH-1:0]  o_p3_id;
logic [LOGL-1:0]      o_p3_idx;

// ========== Output ports ==========
logic                 i_p0_valid;
logic                 i_p0_done;
logic [LOGQ-1:0]      i_p0_data [0:TP-1];

logic                 i_p1_valid;
logic                 i_p1_done;
logic [LOGQ-1:0]      i_p1_data [0:TP-1];

logic                 i_p2_valid;
logic                 i_p2_done;
logic [LOGQ-1:0]      i_p2_data [0:TP-1];

logic                 o_p3_done;
logic [LOGQ-1:0]      o_p3_data [0:TP-1];

// ========== Modports ==========
modport master (
  output i_p0_en, i_p0_id, i_p0_idx,
  output i_p1_en, i_p1_id, i_p1_idx, i_p1_idy,
  output i_p2_en, i_p2_idx, i_p2_idy,
  output o_p3_en, o_p3_id, o_p3_idx, o_p3_data,

  input  i_p0_valid, i_p0_done, i_p0_data,
  input  i_p1_valid, i_p1_done, i_p1_data,
  input  i_p2_valid, i_p2_done, i_p2_data,
  input  o_p3_done
);

modport slave (
  input  i_p0_en, i_p0_id, i_p0_idx,
  input  i_p1_en, i_p1_id, i_p1_idx, i_p1_idy,
  input  i_p2_en, i_p2_idx, i_p2_idy,
  input  o_p3_en, o_p3_id, o_p3_idx, o_p3_data,

  output i_p0_valid, i_p0_done, i_p0_data,
  output i_p1_valid, i_p1_done, i_p1_data,
  output i_p2_valid, i_p2_done, i_p2_data,
  output o_p3_done
);

endinterface

`endif