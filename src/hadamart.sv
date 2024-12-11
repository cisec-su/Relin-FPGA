/*

    Computes C[i] = A[i] * B[i] mod q for i = 0 to TP-1

*/

module hadamart
    #(
        parameter LOGQ     = 32,
        parameter LOGQH    = 15,
        parameter CORRECT  = 1 ,
        parameter FF_IN    = 1 ,
        parameter FF_MUL   = 1 ,
        parameter FF_SUM   = 1 ,
        parameter FF_SUB   = 1 ,
        parameter FF_OUT   = 1 ,
        parameter USE_CSA  = 1 ,
        parameter FF_CSA   = 1 ,
        parameter MORE_DSP = 0 ,
        parameter NON_STD  = 1,
        parameter load_q   = 1 ,
        parameter TP       = 32
    )
    (
        input               clk,
        input  [LOGQ  -1:0] A  [TP-1:0],
        input  [LOGQ  -1:0] B  [TP-1:0],
        input  [LOGQH -1:0] qH ,
        output [LOGT - 1:0] T [TP-1:0]
    );

localparam W    = LOGQ - LOGQH;
localparam LOGT = (CORRECT) ? LOGQ : LOGQ + 1;

localparam intmul_params_t intmul_params = {FF_IN, FF_MUL, FF_OUT, FF_CSA, USE_CSA};
localparam wlm_mixed_params_t wlm_mixed_params = {LOGQ, LOGQH, CORRECT, FF_IN, FF_SUB, FF_MUL, FF_SUM, FF_OUT};
localparam wlm_params_t wlm_params = {W, LOGQ, LOGQH, CORRECT, FF_IN, FF_SUB, FF_MUL, FF_SUM, FF_OUT};
localparam modmul_params_t modmul_params = {W, LOGQ, LOGQH, CORRECT, FF_IN, FF_SUB, FF_MUL, FF_SUM, FF_OUT};
localparam LAT = modmul_lat(intmul_params, wlm_mixed_params, wlm_params, modmul_params);

reg [LOGQH -1:0] qH_reg;

if (load_q) begin
    always @(posedge clk) begin
        qH_reg <= qH;
    end
end
    
for (genvar i = 0; i < TP; i++) begin
    modmul #(
        .LOGQ(LOGQ),
        .LOGQH(LOGQH),
        .CORRECT(CORRECT),
        .FF_IN(FF_IN),
        .FF_MUL(FF_MUL),
        .FF_SUM(FF_SUM),
        .FF_SUB(FF_SUB),
        .FF_OUT(FF_OUT),
        .USE_CSA(USE_CSA),
        .FF_CSA(FF_CSA),
        .MORE_DSP(MORE_DSP),
        .NON_STD(NON_STD)
    ) modmul_inst (
        .clk(clk),
        .A(A[i]),
        .B(B[i]),
        .qH(qH_reg),
        .T(T[i])
    );
end

endmodule