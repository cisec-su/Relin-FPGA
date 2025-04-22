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
        input                   last      ,
        input                   load_q    ,
        input      [LOGQH -1:0] qH        ,
        input      [LOGQ  -1:0] q_inv     ,
        input      [LOGQ  -1:0] halfmod   ,
        input      [LOGQ  -1:0] A [0:TP-1],
        input      [LOGQ  -1:0] B [0:TP-1],
        output reg              o_valid   ,
        output reg [LOGQ  -1:0] C [0:TP-1]
    );

///////////////////////////// Parameters ////////////////////////////////

localparam modadd_params_t modadd_params = {LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_ADD = modadd_lat(modadd_params);

localparam modsub_params_t modsub0_params = {LOGQ, LOGQH, 1, FF_ADDSUB, 1};
localparam LAT_SUB0 = modsub_lat(modsub0_params);

localparam modsub_params_t modsub1_params = {LOGQ, LOGQH, 0, FF_ADDSUB, 1};
localparam LAT_SUB1 = modsub_lat(modsub1_params);

localparam modmul_wlm_params_t modmul_params = {LOGQ, LOGQH, CORRECT, 0, FF_MUL, FF_SUM, FF_SUB, 1, USE_CSA, FF_CSA, MORE_DSP, NON_STD};
localparam LAT_MUL = modmul_wlm_lat(modmul_params);

localparam LAT_BRAM_READ = 2;

localparam LAT_LAST = LAT_ADD + 2; 
localparam LAT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + LAT_ADD + LAT_BRAM_READ + 1; 

localparam K  = 1 << LOGK;
localparam TP = 1 << LOGTP;

localparam A_SHIFT = LAT_SUB0 + LAT_BRAM_READ; 
localparam B_SHIFT = LAT_SUB0 + LAT_SUB1 + LAT_MUL + LAT_BRAM_READ; 

/////////////////////////////////////////////////////////////////////////



///////////////////////// Signal Declarations ///////////////////////////

reg run_q;
reg last_q;

reg [LOGK-1:0] run_ctr;
reg [LOGK-1:0] last_ctr;

reg [LOGQH -1:0] qH_q;
reg [LOGQ  -1:0] q_inv_q;
reg [LOGQ  -1:0] halfmod_q;

wire o_valid_last;
wire o_valid_not_last;
wire last_d;

wire [LOGQ -1:0] A_d [0:TP-1];
wire [LOGQ -1:0] B_d [0:TP-1];

wire [LOGQ -1:0] A_last [0:TP-1];
wire [LOGQ -1:0] A_sub1 [0:TP-1];

wire [LOGQ  -1:0] modadd_in_A  [0:TP-1];
wire [LOGQ  -1:0] modadd_in_B  [0:TP-1];
wire [LOGQ  -1:0] modadd_out   [0:TP-1];

wire [LOGQ  -1:0] modsub0_in_A  [0:TP-1];
wire [LOGQ  -1:0] modsub0_in_B  [0:TP-1];
wire [LOGQ  -1:0] modsub0_out   [0:TP-1];

wire [LOGQ  -1:0] modsub1_in_A  [0:TP-1];
wire [LOGQ  -1:0] modsub1_in_B  [0:TP-1];
wire [LOGQ  -1:0] modsub1_out   [0:TP-1];

wire [LOGQ  -1:0] modmul_in_A  [0:TP-1];
wire [LOGQ  -1:0] modmul_in_B  [0:TP-1];
wire [LOGQ  -1:0] modmul_out   [0:TP-1];

wire [LOGQ -1:0] bram_in  [0:TP-1];
wire [LOGQ -1:0] bram_out [0:TP-1]; 

wire [LOGQ-1:0] C_d [0:TP-1];

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
    .SHIFT (LAT_LAST - 1),
    .WIDTH (1           )
) shift_reg_o_valid_last (
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (i_valid     ),
    .o_data (o_valid_last)
);

shift_reg #(
    .SHIFT (LAT - LAT_LAST),
    .WIDTH (1             )
) shift_reg_o_valid_not_last (
    .clk    (clk             ),
    .rst    (rst             ),
    .i_data (o_valid_last    ),
    .o_data (o_valid_not_last)
);

shift_reg #(
    .SHIFT (LAT_LAST - 1),
    .WIDTH (1           )
) shift_reg_last_d (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (last  ),
    .o_data (last_d)
);

shift_reg_arr #(
    .SHIFT (1   ),
    .WIDTH (LOGQ),
    .LENGTH(TP  )
) shift_reg_A_last (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (A     ),
    .o_data (A_last)
);

shift_reg_arr #(
    .SHIFT (A_SHIFT - 1),
    .WIDTH (LOGQ       ),
    .LENGTH(TP         )
) shift_reg_A_sub1 (
    .clk    (clk   ),
    .rst    (rst   ),
    .i_data (A_last),
    .o_data (A_sub1)
);

shift_reg_arr #(
    .SHIFT (B_SHIFT),
    .WIDTH (LOGQ   ),
    .LENGTH(TP     )
) shift_reg_B_d (
    .clk    (clk),
    .rst    (rst),
    .i_data (B  ),
    .o_data (B_d)
);

/////////////////////////////////////////////////////////////////////////



////////////////////// Combinational Assignments ////////////////////////

for (genvar i = 0; i < TP; i = i + 1) begin
    assign A_d[i] = (last_q) ? A_last[i] : A_sub1[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modadd_in_A[i]  = (last_q) ? A_d[i] : modmul_out[i];
    assign modadd_in_B[i]  = (last_q) ? halfmod_q : B_d[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign bram_in[i] = modadd_out[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modsub0_in_A[i]  = bram_out[i];
    assign modsub0_in_B[i]  = halfmod_q;
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modsub1_in_A[i]  = A_d[i];
    assign modsub1_in_B[i]  = modsub0_out[i];
end

for (genvar i = 0; i < TP; i = i + 1) begin
    assign modmul_in_A[i]  = modsub1_out[i];
    assign modmul_in_B[i]  = q_inv_q;
end

for (genvar i = 0; i < TP; i++) begin
    assign C_d[i] = modadd_out[i];
end

/////////////////////////////////////////////////////////////////////////



////////////////////////////// Final Op /////////////////////////////////

for (genvar i = 0; i < TP; i = i + 1) begin
    modadd #(
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_ADD(FF_ADDSUB),
        .FF_OUT(1        )
    ) modadd_inst (
        .clk(clk            ),
        .A  (modadd_in_A[i] ),
        .B  (modadd_in_B[i] ),
        .qH (qH_q),
        .C  (modadd_out[i]  )
    );
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modsub #(
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_SUB(FF_ADDSUB),
        .FF_OUT(1        )
    ) modsub_inst0 (
        .clk(clk            ),
        .A  (modsub0_in_A[i]),
        .B  (modsub0_in_B[i]),
        .qH (qH_q           ),
        .C  (modsub0_out[i] )
    );
end

for (genvar i = 0; i < TP; i = i + 1) begin
    modsub #(
        .LOGQ  (LOGQ     ),
        .LOGQH (LOGQH    ),
        .FF_IN (1        ),
        .FF_SUB(FF_ADDSUB),
        .FF_OUT(0        )
    ) modsub_inst1 (
        .clk(clk            ),
        .A  (modsub1_in_A[i]),
        .B  (modsub1_in_B[i]),
        .qH (qH_q           ),
        .C  (modsub1_out[i] )
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
        .clk(clk           ),
        .A  (modmul_in_A[i]),
        .B  (modmul_in_B[i]),
        .qH (qH_q          ),
        .T  (modmul_out[i] )
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
    if (rst) begin
        run_q <= 0;
        run_ctr <= 0;
    end
    else if (i_valid && !last) begin
        run_q <= 1;
        run_ctr <= 0;
    end
    else if (run_q) begin
        run_ctr <= run_ctr + 1;
        if (run_ctr == K - 1)
            run_q <= 0;
    end 
end

always @(posedge clk) begin
    if (rst) begin
        last_q <= 0;
        last_ctr <= 0;
    end
    else if (i_valid && last) begin
        last_q <= 1;
        last_ctr <= 0;
    end
    else if (last_q) begin
        last_ctr <= last_ctr + 1;
        if (last_ctr == K - 1)
            last_q <= 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        qH_q <= 0;
        q_inv_q <= 0;
        halfmod_q <= 0;
    end
    else if (load_q) begin
        qH_q <= qH;
        q_inv_q <= q_inv;
        halfmod_q <= halfmod;
    end
end

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
    if ((last_d && o_valid_last) || (!last_d && o_valid_not_last)) begin
        o_valid <= 1;
    end
    else begin
        o_valid <= 0;
    end
end

always @(posedge clk) begin
    for (int i = 0; i < TP; i = i + 1) begin
        C[i] <= C_d[i];
    end
end

/////////////////////////////////////////////////////////////////////////



///////////////////////////// State machine /////////////////////////////

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
            if (read_addr == LAT_LAST - 2) begin
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
