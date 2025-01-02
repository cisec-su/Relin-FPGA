`ifndef RELIN_IF
`define RELIN_IF

interface relin_t #(
        parameter LOGL  = 30  , // Number of primes
        parameter LOGQ  = 64  , // Word size
        parameter TP    = 32    // Coefficient throughput
);

  logic [LOGL-1:0]    rw_id            ;
  logic                   r_psi_inv        ;
  logic                   r_psi_start      ;
  logic                   r_psi_valid      ;
  logic [LOGQ-1:0]    r_psi    [TP-1:0]; 
  logic                   r_psi_done       ;
  logic [LOGL-1:0]    r_poly_id        ;
  logic                   r_poly_start     ;
  logic                   r_poly_valid     ;
  logic [LOGQ-1:0]    r_poly   [TP-1:0]; 
  logic                   r_poly_done      ;
  logic [LOGL-1:0]    r_rlk_id         ;
  logic                   r_rlk_start      ;
  logic                   r_rlk_valid      ;
  logic [LOGQ-1:0]    r_rlk_0  [TP-1:0]; 
  logic [LOGQ-1:0]    r_rlk_1  [TP-1:0];
  logic                   r_rlk_done       ;
  logic                   w_ready          ;
  logic [LOGQ-1:0]    w_poly   [TP-1:0];
  logic                     w_valid          ;


  modport master (
    output r_idx, rw_idy,
    output r_psi_inv, r_psi_start,
    input  r_psi_valid, r_psi, r_psi_done,
    output r_poly_id, r_poly_start,
    input  r_poly_valid, r_poly, r_poly_done,
    output r_rlk_id, r_rlk_start,
    input  r_rlk_valid, r_rlk_0, r_rlk_1, r_rlk_done,
    input  w_ready,
    output w_poly, w_valid
  );

  modport slave (
    input  r_idx, rw_idy,
    input  r_psi_inv, r_psi_start,
    output r_psi_valid, r_psi, r_psi_done,
    input  r_poly_id, r_poly_start,
    output r_poly_valid, r_poly,
    input  r_rlk_id, r_rlk_start,
    output r_rlk_valid, r_rlk_0, r_rlk_1, r_rlk_done,
    output w_ready,
    input  w_poly, w_valid
  );


endinterface : relin_t

`endif
