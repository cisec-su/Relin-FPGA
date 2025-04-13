`include "modadd.svh"
`include "modsub.svh"
`include "modmul_wlm.svh"
`include "wlm.svh"

module final_op
   #(   
        parameter LOGK       = 10,
        parameter LOGQ       = 64,
        parameter LOGQH      = 48,
        parameter LOGTP      = 5 ,
        parameter CORRECT    = 1 ,
        parameter FF_IN      = 1 ,
        parameter FF_MUL     = 1 ,
        parameter FF_SUM     = 0 ,
        parameter FF_SUB     = 0 ,
        parameter FF_ADDSUB  = 0 ,
        parameter USE_CSA    = 1 ,
        parameter FF_CSA     = 1 ,
        parameter MORE_DSP   = 1 ,
        parameter NON_STD    = 0
    )
    (
        input                   clk       ,
        input                   rst       ,
        input                   i_valid   ,
        input                   o_valid   ,
        input                   last      ,
        input                   load_q    ,
        input      [LOGQH -1:0] qH        ,
        input      [LOGQ  -1:0] q_inv     ,
        input      [LOGQ  -1:0] halfmod   ,
        input      [LOGQ  -1:0] A [0:TP-1],
        input      [LOGQ  -1:0] B [0:TP-1],
        output reg [LOGQ  -1:0] C [0:TP-1]
    );

///////////////////////////// Parameters ////////////////////////////////

localparam modadd_params_t modadd_params_last = {LOGQ, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_ADD_LAST = modadd_lat(modadd_params_last);

localparam modadd_params_t modadd_params = {LOGQ, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_ADD = modadd_lat(modadd_params);

localparam modsub_params_t modsub0_params = {LOGQ, LOGQ, LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_SUB0 = modsub_lat(modsub0_params);

localparam modsub_params_t modsub1_params = {LOGQ, LOGQ, LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_SUB1 = modsub_lat(modsub1_params);

localparam W = LOGQ - LOGQH;
localparam modmul_wlm_params_t modmul_params = {W, LOGQ, LOGQH, CORRECT, 0, FF_MUL, FF_SUM, FF_SUB, 1, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
localparam LAT_MUL = modmul_wlm_lat(modmul_params);

localparam LAT_LAST = LAT_ADD_LAST + 2; // Registering A & C
localparam LAT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + LAT_ADD_LAST + 2; // Taking bram_out and registering C 

localparam K  = 1 << LOGK;
localparam TP = 1 << LOGTP;

localparam A_SHIFT = LAT_SUB0 + 2; // Taking bram_out
localparam B_SHIFT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + 2; // Taking bram_out
localparam Q_INV_SHIFT = LAT_SUB0 + LAT_SUB1 + 2;
localparam QH_SUB1_SHIFT = LAT_SUB0 + 2;
localparam QH_MUL_SHIFT = LAT_SUB0 + LAT_SUB1 + 2;
localparam QH_ADD_SHIFT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + 2; 

/////////////////////////////////////////////////////////////////////////

///////////////////////// Signal Declarations ///////////////////////////

wire last_q;

wire [LOGQH -1:0] qH_q;
wire [LOGQ  -1:0] q_inv_q;
wire [LOGQ  -1:0] halfmod_q;

wire [LOGQH-1:0] qH_sub0;
wire [LOGQH-1:0] qH_sub1;
wire [LOGQH-1:0] qH_mul;
wire [LOGQH-1:0] qH_add;

wire [LOGQ -1:0] A_q [0:TP-1];
wire [LOGQ -1:0] B_q [0:TP-1];

wire [LOGQ -1:0] A_int1 [0:TP-1];
wire [LOGQ -1:0] A_int2 [0:TP-1];

wire A_shift;
wire B_shift;

wire [LOGQ  -1:0] modadd_in_A  [0:TP-1];
wire [LOGQ  -1:0] modadd_in_B  [0:TP-1];
wire [LOGQH -1:0] modadd_in_qH [0:TP-1];
wire [LOGQ  -1:0] modadd_out   [0:TP-1];

wire [LOGQ  -1:0] modsub0_in_A  [0:TP-1];
wire [LOGQ  -1:0] modsub0_in_B  [0:TP-1];
wire [LOGQH -1:0] modsub0_in_qH [0:TP-1];
wire [LOGQ  -1:0] modsub0_out   [0:TP-1];

wire [LOGQ  -1:0] modsub1_in_A  [0:TP-1];
wire [LOGQ  -1:0] modsub1_in_B  [0:TP-1];
wire [LOGQH -1:0] modsub1_in_qH [0:TP-1];
wire [LOGQ  -1:0] modsub1_out   [0:TP-1];

wire [LOGQ  -1:0] modmul_in_A  [0:TP-1];
wire [LOGQ  -1:0] modmul_in_B  [0:TP-1];
wire [LOGQH -1:0] modmul_in_qH [0:TP-1];
wire [LOGQ  -1:0] modmul_out   [0:TP-1];

wire [LOGQ -1:0] bram_in  [0:TP-1];
wire [LOGQ -1:0] bram_out [0:TP-1]; 

reg  [LOGQ-1:0] C_q [0:TP-1];

reg [LOGK -1:0] read_addr;
reg [LOGK -1:0] write_addr;
reg [4:0]       state;
reg [4:0]       next_state;
reg             o_ram_valid;
reg             done;
reg             busy;
reg             bram_wen;
reg             start_write;
reg             start_read;
reg             wen;
reg             ren;

/////////////////////////////////////////////////////////////////////////

//////////////////////// Input Registering //////////////////////////////

shift_reg #(
    .SHIFT (Q_INV_SHIFT),
    .WIDTH (LOGQ       )
) shift_reg_q_inv (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (q_inv  ),
    .o_data (q_inv_q)
);

shift_reg #(
    .SHIFT (2   ),
    .WIDTH (LOGQ)
) shift_reg_halfmod (
    .clk    (clk      ),
    .rst    (rst      ),
    .i_data (halfmod  ),
    .o_data (halfmod_q)
);

shift_reg #(
    .SHIFT (2   ),
    .WIDTH (LOGQ)
) shift_reg_qh (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (qH    ),
    .o_data (qH_q  )
);

shift_reg #(
    .SHIFT (QH_SUB1_SHIFT),
    .WIDTH (LOGQH        )
) shift_reg_qh_sub1 (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (qH     ),
    .o_data (qH_sub1)
);

shift_reg #(
    .SHIFT (QH_MUL_SHIFT),
    .WIDTH (LOGQH       )
) shift_reg_qh_mul (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (qH   ),
    .o_data (qH_mul)
);

shift_reg #(
    .SHIFT (QH_ADD_SHIFT),
    .WIDTH (LOGQH       )
) shift_reg_qh_add (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (qH    ),
    .o_data (qH_add)
);

shift_reg #(
    .SHIFT (2),
    .WIDTH (1)
) shift_reg_last (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (last  ),
    .o_data (last_q)
);

shift_reg_arr #(
    .SHIFT (2   ),
    .WIDTH (LOGQ),
    .LENGTH(TP  )
) shift_reg_A1 (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (A     ),
    .o_data (A_int1)
);

shift_reg_arr #(
    .SHIFT (A_SHIFT - 2),
    .WIDTH (LOGQ       ),
    .LENGTH(TP         )
) shift_reg_A2 (
    .clk    (clk  ),
    .rst    (rst  ),
    .i_data (A_int1),
    .o_data (A_int2)
);

shift_reg_arr #(
    .SHIFT (B_SHIFT),
    .WIDTH (LOGQ   ),
    .LENGTH(TP     )
) shift_reg_B (
    .clk    (clk  ),
    .rst    (rst  ),
    .i_data (B    ),
    .o_data (B_q  )
);

/////////////////////////////////////////////////////////////////////////

////////////////////// Combinational Assignments ////////////////////////

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modadd_in_A[i]  = (last_q) ? A_q[i] : modmul_out[i];
    assign modadd_in_B[i]  = (last_q) ? halfmod_q : B_q[i];
    assign modadd_in_qH[i] = (last_q) ? qH_q : qH_add;
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign bram_in[i] = modadd_out[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modsub0_in_A[i]  = bram_out[i]; // Available after 1 cc
    assign modsub0_in_B[i]  = halfmod_q; // Delayed to be available after 1 cc
    assign modsub0_in_qH[i] = qH_q; // Delayed to be available after 1 cc
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modsub1_in_A[i]  = A_q[i];
    assign modsub1_in_B[i]  = modsub0_out[i];
    assign modsub1_in_qH[i] = qH_sub1;
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modmul_in_A[i]  = modsub1_out[i];
    assign modmul_in_B[i]  = q_inv_q;
    assign modmul_in_qH[i] = qH_mul;
end

for (genvar i = 0; i < TP; i++) begin
    assign C_q[i] = modadd_out[i];
end

/////////////////////////////////////////////////////////////////////////

////////////////////////////// Final Op /////////////////////////////////

for (genvar i = 0; i < TP; i = i + 1) begin
    assign A_q[i] = (last_q) ? A_int1[i] : A_int2[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modadd #(
        .LOGA  (LOGQ     ),
        .LOGB  (LOGQ     ),
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_ADD(FF_ADDSUB),
        .FF_OUT(1        )
    ) modadd_inst (
        .clk(clk            ),
        .A  (modadd_in_A[i] ),
        .B  (modadd_in_B[i] ),
        .qH (modadd_in_qH[i]),
        .C  (modadd_out[i]  )
    );
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modsub #(
        .LOGA  (LOGQ     ),
        .LOGB  (LOGQ     ),
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_SUB(FF_ADDSUB),
        .FF_OUT(1        )
    ) modsub_inst0 (
        .clk(clk             ),
        .A  (modsub0_in_A[i] ),
        .B  (modsub0_in_B[i] ),
        .qH (modsub0_in_qH[i]),
        .C  (modsub0_out[i]  )
    );
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modsub #(
        .LOGA  (LOGQ     ),
        .LOGB  (LOGQ     ),
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_SUB(FF_ADDSUB),
        .FF_OUT(0        )
    ) modsub_inst1 (
        .clk(clk             ),
        .A  (modsub1_in_A[i] ),
        .B  (modsub1_in_B[i] ),
        .qH (modsub1_in_qH[i]),
        .C  (modsub1_out[i]  )
    );
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modmul_wlm #(
        .LOGQ    (LOGQ    ),
        .LOGQH   (LOGQH   ),
        .CORRECT (CORRECT ),
        .FF_IN   (0       ),
        .FF_MUL  (FF_MUL  ),
        .FF_SUM  (FF_SUM  ),
        .FF_SUB  (FF_SUB  ),
        .FF_OUT  (1       ),
        .USE_CSA (USE_CSA ),
        .FF_CSA  (FF_CSA  ),
        .MORE_DSP(MORE_DSP),
        .NON_STD (NON_STD )
    ) modmul_wlm_inst (
        .clk(clk            ),
        .A  (modmul_in_A[i] ),
        .B  (modmul_in_B[i] ),
        .qH (modmul_in_qH[i]),
        .T  (modmul_out[i]  )
    );
end

/////////////////////////////////////////////////////////////////////////

////////////////////////// BRAM Instances ///////////////////////////////

for (genvar i = 0; i < TP; i++) begin
    bram #(
        .WIDTH (LOGQ),
        .LENGTH(K   )
    ) bram_inst (
        .clk  (clk        ),
        .wen  (bram_wen   ),
        .waddr(write_addr ),
        .din  (bram_in[i] ),
        .raddr(read_addr  ),
        .dout (bram_out[i])
    );
end

/////////////////////////////////////////////////////////////////////////

///////////////////////////// Sequential Logic //////////////////////////

always @(posedge clk) begin
    if (i_valid && last) begin
        wen <= 1;
    end
    else begin
        wen <= 0;
    end
end

always @(posedge clk) begin
    if (i_valid && !last) begin
        ren <= 1;
    end
    else begin
        ren <= 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < TP; i = i + 1) begin
            C[i] <= 0;
        end
    end 
    else if (o_valid) begin
        for (int i = 0; i < TP; i = i + 1) begin
            C[i] <= C_q[i];
        end
    end
end

///////////////////////////// State machine //////////////////////////

typedef enum logic [4:0] {
    ST_IDLE              = 5'b00001,
    ST_READ              = 5'b00010,
    ST_WRITE_INIT        = 5'b00100,
    ST_WRITE_LOOP        = 5'b01000,
    ST_WRITE_END         = 5'b10000
} state_t;

counter #(
    .WIDTH(LOGK)
) ctr_read_inst (
    .clk   (clk       ),
    .rst   (rst       ),
    .inc   (start_read),
    .ctr   (read_addr )
);

counter #(
    .WIDTH(LOGK)
) ctr_write_inst (
    .clk   (clk        ),
    .rst   (rst        ),
    .inc   (start_write),
    .ctr   (write_addr )
);

always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;  // Reset to idle state
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state  = state;  // Update state
    o_ram_valid = 0;      // Reset valid signal
    done        = 0;      // Reset done signal
    busy        = 0;      // Reset done signal
    bram_wen    = 0;      // Disable BRAM writes
    start_write = 0;
    start_read  = 0;
    case (state)
        ST_IDLE: begin
            if (ren) begin
                start_read = 1;
                o_ram_valid = 1;
                next_state = ST_READ;
            end else if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
        end
        ST_READ: begin
            busy = 1;
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_IDLE;
            end
        end
        ST_WRITE_INIT: begin
            busy = 1;
            if (read_addr == LAT_LAST - 1) begin
                bram_wen = 1;
                start_write = 1;
                next_state  = ST_WRITE_LOOP;
            end
        end
        ST_WRITE_LOOP: begin
            busy = 1;
            bram_wen = 1;
            if (write_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_WRITE_END;
            end
        end
        ST_WRITE_END: begin
            bram_wen  = 0;
            if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
            else if (ren) begin
                start_read = 1;
                next_state = ST_READ;
            end
            else begin
                next_state = ST_IDLE;
            end
        end
        default: next_state = ST_IDLE;
    endcase
end

endmodule
