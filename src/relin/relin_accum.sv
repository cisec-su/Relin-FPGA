module relin_accum 
   #(
        parameter LOGK      = 10,
        parameter LOGQ      = 64,   
        parameter LOGQH     = 47,
        parameter FF_ADD    = 0 ,
        parameter LOGTP     = 32
    )
    (
        input              clk       ,
        input              rst       ,
        input              first     ,
        input              ren       ,
        input              wen       ,
        input              load_q    ,
        input  [LOGQH-1:0] qH        ,
        output             o_valid   ,
        output reg         done      ,
        output reg         busy      ,
        input  [LOGQ -1:0] A [TP-1:0],
        output [LOGQ -1:0] C [TP-1:0]
    );

///////////////////////////// Parameters ////////////////////////////////

localparam TP       = (1 << LOGTP);
localparam K        = (1 << LOGK);
localparam FF_IN    = 1;
localparam FF_OUT   = 1;
localparam LAT      = FF_ADD + FF_OUT;

/////////////////////////////////////////////////////////////////////////



///////////////////////// Type Declarations ///////////////////////////
typedef enum logic [4:0] {
    ST_IDLE              = 5'b00001,
    ST_READ              = 5'b00010,
    ST_WRITE_INIT        = 5'b00100,
    ST_WRITE_LOOP        = 5'b01000,
    ST_WRITE_END         = 5'b10000
} state_t;
/////////////////////////////////////////////////////////////////////////




///////////////////////// Signal Declarations ///////////////////////////

state_t state, next_state;

reg  [LOGQH-1:0] qH_int;
wire [LOGQ -1:0] modadd_out   [TP-1:0];
reg  [LOGQ -1:0] A_q          [TP-1:0];

wire [LOGQ -1:0] modadd_in_A  [TP-1:0];
wire [LOGQ -1:0] bram_out     [TP-1:0];
reg  [LOGK -1:0] read_addr;
reg  [LOGK -1:0] write_addr;
reg  start_read, start_write;
reg  bram_wen;

reg  first_q;

/////////////////////////////////////////////////////////////////////////

for (genvar i = 0; i < TP; i++) begin : OUT_GEN
    assign C[i] = bram_out[i];
end

for (genvar i = 0; i < TP; i++) begin : IN_GEN
    assign modadd_in_A[i] = (first_q) ? bram_out[i] : {LOGQ{1'b0}};
end

/////////////////////////////////////////////////////////////////////////

// Modular addition instances
for (genvar i = 0; i < TP; i++) begin : MODADD_GEN
    modadd #(
        .LOGA  (LOGQ  ), // Input A width
        .LOGB  (LOGQ  ), // Input B width
        .LOGQ  (LOGQ  ), // Output width
        .LOGQH (LOGQH ), // Modulus width
        .FF_IN (0     ), // Input pipeline stage. Done manually, see A_q
        .FF_ADD(FF_ADD), // Addition pipeline stage
        .FF_OUT(FF_OUT)  // Output pipeline stage
    ) mod_adder_inst (
        .clk(clk          ), // Clock signal
        .A  (modadd_in_A[i]), // Input from BRAM
        .B  (A_q[i]       ), // Input coefficient array
        .qH (qH_int       ), // Modulus value
        .C  (modadd_out[i])  // Result of modular addition
    );
end

/////////////////////////////////////////////////////////////////////////

// BRAM instances for each coefficient
for (genvar i = 0; i < TP; i++) begin : BRAM_GEN
    bram #(
        .WIDTH (LOGQ),          // Data size (word size)
        .LENGTH(K   )           // Memory size
    ) bram_inst (
        .clk  (clk          ),   // Clock signal
        .wen  (bram_wen     ),   // Write enable
        .waddr(write_addr   ),   // Write address
        .din  (modadd_out[i]),   // Data input
        .raddr(read_addr    ),   // Read address
        .dout (bram_out[i]  )    // Data output
    );
end
/////////////////////////////////////////////////////////////////////////


shift_reg #(
    .LAT   (1),
    .WIDTH (1),
    .RST_EN(1)
)
o_valid_shift_reg
(
    .clk    (clk),
    .rst    (rst),
    .i_data (ren),
    .o_data (o_valid)
);


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
        qH_int <= 0;
    end else if (load_q) begin
        qH_int <= qH;
    end
end


always @(posedge clk) begin
    A_q <= A;
end


always @(posedge clk) begin
    if (rst) begin
        first_q <= 0;
    end
    else if (first) begin
        first_q <= 0;
    end
    else if (write_addr == (K - 1)) begin
        first_q <= 1;
    end
end



always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


always @(*) begin
    next_state  = state;
    done        = 0;
    busy        = 0;
    bram_wen    = 0;
    start_write = 0;
    start_read  = 0;
    case (state)
        ST_IDLE: begin
            if (ren) begin
                start_read = 1;
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
            if (read_addr == LAT) begin
                next_state  = ST_WRITE_LOOP;
            end
            if (write_addr != 0) begin
                bram_wen = 1;
            end
        end
        ST_WRITE_LOOP: begin
            busy = 1;
            bram_wen = 1;
            if (write_addr == 0) begin
                start_write = 1;
            end
            if (read_addr == (K - 1)) begin
                done       = 1;
                next_state = ST_WRITE_END;
            end
        end
        ST_WRITE_END: begin
            bram_wen  = 1;
            if (wen) begin
                start_read = 1;
                next_state = ST_WRITE_INIT;
            end
            else if (ren) begin
                start_read = 1;
                next_state = ST_READ;
            end
            else if (write_addr == (K - 1)) begin
                next_state = ST_IDLE;
            end
        end
        default: next_state = ST_IDLE;
    endcase
end

/////////////////////////////////////////////////////////////////////////


endmodule
