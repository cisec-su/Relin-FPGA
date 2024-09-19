module relin_top
   #(   
        parameter L        = 30  , // Number of primes
        parameter W        = 64  , // Word size
        parameter LOGN     = 16  , // Ring size
        parameter TP       = 32  , // Coefficient throughput
        parameter NT       = 1024, // Number of twiddles that must be loaded
        parameter NTT_LAT  = 2000, // NTT latency
        parameter HP_LAT   = 15  , // Hadamard product latency
        parameter ACC_LAT  = 3   , // Accum. latency
        parameter FN_LAT   = 100 , // Final op latency
    )
    (
        input              clk              ,
        input              rst              ,
        input              start            ,
        input     [W-1:0]  i_poly   [TP-1:0], 
        input     [W-1:0]  rlk0     [TP-1:0], 
        input     [W-1:0]  rlk1     [TP-1:0], 
        output    [W-1:0]  o_poly   [TP-1:0],  // total bandwidth: TP*4*W
        output    reg      o_valid
    );


localparam D = 32; // bit-width for g.p. counter


// states
localparam ST_IDLE      = 3'd0;
localparam ST_LOAD_Q_TW = 3'd1;
localparam ST_NTT       = 3'd2;
localparam ST_LOAD_ITW  = 3'd3; // load inverse twiddles
localparam ST_INTT      = 3'd4;



reg [2:0] state;
reg [2:0] next_state;

reg [D-:0] ctr; // general purpose counter 
reg ctr_inc;
reg ctr_rst;


reg [$clog(L)-1:0] ctr_L; // counter for L
reg ctr_L_inc;
reg ctr_L_rst;

wire [W-1:0] q;
reg  load_q;

wire [W-1:0] ntt_in     [TP-1:0];
wire [W-1:0] ntt_out    [TP-1:0];
reg          intt;
reg          load_tw;

wire [W-1:0] had_in_A   [TP*2-1:0];
wire [W-1:0] had_in_B   [TP*2-1:0];
wire [W-1:0] had_out    [TP*2-1:0];


wire [W-1:0] acc_in     [TP*2-1:0];
wire [W-1:0] acc_out    [TP*2-1:0];
reg          acc_en;
reg          acc_sel;
reg          acc_rst;

wire [W-1:0] fn_in      [TP-1:0];
wire [W-1:0] fn_out     [TP-1:0];



q_mux #(
    .L(L),
    .W(W)
) q_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(ctr_L),
    .q(q)
);



ntt_wrapper #(
    .W(W),
    .LOGN(LOGN),
    .TP(TP)
) ntt_wrapper_inst (
    .clk(clk),
    .rst(rst),
    .load_q(load_q),
    .load_tw(load_tw),
    .intt(intt),
    .q(q),
    .A_tw(ntt_in),
    .C(ntt_out)
);



hadamart #(
    .W(W),
    .TP(TP*2)
) hadamart_inst (
    .clk(clk),
    .rst(rst),
    .q(q),
    .A(had_in_A),
    .B(had_in_B),
    .C(had_out)
);



accumulator #(
    .W(W),
    .TP(TP*2)
) accumulator_inst (
    .clk(clk),
    .rst(rst | acc_rst),
    .en(acc_en),
    .load_q(load_q),
    .q(q),
    .A(acc_in),
    .C(acc_out)
);


final_op #(
    .W(W),
    .TP(TP)
) final_op_inst (
    .clk(clk),
    .rst(rst),
    .A(o_data),
    .C(o_data)
);



for (genvar i = 0; i < TP; i = i + 1) begin
    
    always @(posedge clk) begin
        ntt_out_q[i] <= ntt_out[i];
        had_out_q[i] <= had_out[i];
        acc_out_q[i] <= acc_out[i];
        fn_out_q[i] <= fn_out[i];
    end

end

for (genvar i = TP; i < TP*2; i = i + 1) begin
    
    always @(posedge clk) begin
        had_out_q[i] <= had_out[i];
        acc_out_q[i] <= acc_out[i];
    end

end


always @(posedge clk) begin
    if (rst) begin
        ctr_L <= 0;
    end
    else if (ctr_L_inc) begin
        ctr_L <= ctr_L + 1;
    end
    else if (ctr_L_rst) begin
        ctr_L <= 0;
    end
end


always @(posedge clk) begin
    if (rst) begin
        ctr <= 0;
    end
    else if (ctr_inc) begin
        ctr <= ctr + 1;
    end
    else if (ctr_rst) begin
        ctr <= 0;
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


for (genvar i = 0; i < TP; i = i + 1) begin
    assign ntt_in  [i   ] = (intt)? ((acc_sel)? acc_out[i+TP]: acc_out[i]): i_poly[i];
    assign had_in_A[i   ] = ntt_out[i   ];
    assign had_in_A[i+TP] = ntt_out[i   ];
    assign had_in_B[i   ] = rlk0   [i   ];
    assign had_in_B[i+TP] = rlk1   [i   ];
    assign acc_in  [i   ] = had_out[i   ];
    assign acc_in  [i+TP] = had_out[i+TP];
    assign fn_in   [i   ] = acc_out[i   ];
end


always @(*) begin

    intt      = 0;
    acc_en    = 1;
    acc_sel   = 0;
    acc_rst   = 0;
    load_q    = 0;
    load_tw   = 0;
    ctr_inc   = 0;
    ctr_rst   = 0;
    ctr_L_inc = 0;
    ctr_L_rst = 0;
    o_valid   = 0;

    case (state)
        ST_IDLE: begin
            if (start)
                next_state = ST_LOAD_Q_TW;
            ctr_L_rst = 1;
            ctr_rst = 1;
        end
        ST_LOAD_Q_TW: begin
            if (ctr == ((NT/TP)-1)) begin
                load_tw = 1;
                ctr_rst = 1;
            end
            else if (ctr == (NT/TP)) begin
                load_q = 1;
                next_state = ST_NTT;                
            end
            else begin
                load_tw = 1;
                ctr_inc = 1;
            end
        end
        ST_NTT: begin
            if (ctr > ((NTT_LAT+HP_LAT+ACC_LAT+(L-1)*(N/TP)) - ACC_LAT - 1)) begin  // freeze accumulator
                acc_en = 0;
            end

            if (ctr == ((NTT_LAT+HP_LAT+ACC_LAT+(L-1)*(N/TP)) - 1)) begin  // wait until all polynomials are processed
                next_state = ST_INTT0;
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end
        ST_LOAD_ITW: begin
            acc_en = 0;
            load_tw = 1;
            intt = 1;
            if (ctr == ((NT/TP)-1)) begin
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end
        ST_INTT: begin
            intt = 1;
            acc_en = 0;
            if (ctr > (NTT_LAT-1)) begin
                acc_sel = 1;
            end
            if (ctr > (NTT_LAT+FN_LAT-1)) begin
                o_valid = 1;
            end
            if (ctr == (NTT_LAT+FN_LAT+(N/TP)-1)) begin
                if (ctr_L == L) begin
                    ctr_L_rst = 1;
                    next_state = ST_IDLE;
                end
                else begin
                    ctr_L_inc = 1;
                    next_state = ST_LOAD_Q_TW; // go to next prime
                    acc_rst = 1;
                end
                ctr_rst = 1;
            end
            else begin
                ctr_inc = 1;
            end
        end


    endcase


end


endmodule