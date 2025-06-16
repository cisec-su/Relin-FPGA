/*

    outputs q[i]

*/


module relin_q_mux
   #(   
        parameter LOGN     = 16,
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64,
        parameter LOGQH    = 17
    )
    (
        input                  clk,
        input                  rst,
        input  [LOGL -1:0]     i  ,
        output [LOGQH-1:0]     qH
    );


reg [ LOGQ-1:0] qH_int;


if (LOGN == 12) begin
    always @(*) begin
        case (i)
            0      : qH_int = 60'h800580000000001;
            1      : qH_int = 60'h800800000000001;
            2      : qH_int = 60'h801a80000000001;
            default: qH_int = 60'h800580000000001; // default to first prime
        endcase
    end
end
else if (LOGN == 13) begin
    always @(*) begin
        case (i)
            0      : qH_int = 60'h800580000000001;
            1      : qH_int = 60'h800800000000001;
            2      : qH_int = 60'h801a80000000001;
            3      : qH_int = 60'h802500000000001;
            4      : qH_int = 60'h803200000000001;
            default: qH_int = 60'h800580000000001; // default to first prime
        endcase
    end
end
else if (LOGN == 14) begin
    always @(*) begin
        case (i)
            0      : qH_int = 60'h800580000000001;
            1      : qH_int = 60'h800800000000001;
            2      : qH_int = 60'h801a80000000001;
            3      : qH_int = 60'h802500000000001;
            4      : qH_int = 60'h803200000000001;
            5      : qH_int = 60'h805080000000001;
            6      : qH_int = 60'h805a80000000001;
            7      : qH_int = 60'h805c80000000001;
            default: qH_int = 60'h800580000000001; // default to first prime
        endcase
    end
end
else if (LOGN == 15) begin
    always @(*) begin
        case (i)
            0      : qH_int = 60'h800580000000001;
            1      : qH_int = 60'h800800000000001;
            2      : qH_int = 60'h801a80000000001;
            3      : qH_int = 60'h802500000000001;
            4      : qH_int = 60'h803200000000001;
            5      : qH_int = 60'h805080000000001;
            6      : qH_int = 60'h805a80000000001;
            7      : qH_int = 60'h805c80000000001;
            8      : qH_int = 60'h806e00000000001;
            9      : qH_int = 60'h807a80000000001;
            10     : qH_int = 60'h807f00000000001;
            11     : qH_int = 60'h809080000000001;
            12     : qH_int = 60'h809500000000001;
            13     : qH_int = 60'h80a580000000001;
            14     : qH_int = 60'h80ba80000000001;
            default: qH_int = 60'h800580000000001; // default to first prime
        endcase
    end
end
else if (LOGN == 16) begin
    always @(*) begin
        case (i)
            0      : qH_int = 60'h800580000000001;
            1      : qH_int = 60'h800800000000001;
            2      : qH_int = 60'h801a80000000001;
            3      : qH_int = 60'h802500000000001;
            4      : qH_int = 60'h803200000000001;
            5      : qH_int = 60'h805080000000001;
            6      : qH_int = 60'h805a80000000001;
            7      : qH_int = 60'h805c80000000001;
            8      : qH_int = 60'h806e00000000001;
            9      : qH_int = 60'h807a80000000001;
            10     : qH_int = 60'h807f00000000001;
            11     : qH_int = 60'h809080000000001;
            12     : qH_int = 60'h809500000000001;
            13     : qH_int = 60'h80a580000000001;
            14     : qH_int = 60'h80ba80000000001;
            15     : qH_int = 60'h80c200000000001;
            16     : qH_int = 60'h80c280000000001;
            17     : qH_int = 60'h80ee00000000001;
            18     : qH_int = 60'h80ef00000000001;
            19     : qH_int = 60'h80fd00000000001;
            20     : qH_int = 60'h810100000000001;
            21     : qH_int = 60'h810900000000001;
            22     : qH_int = 60'h810b80000000001;
            23     : qH_int = 60'h810c00000000001;
            24     : qH_int = 60'h811b00000000001;
            25     : qH_int = 60'h813000000000001;
            26     : qH_int = 60'h813880000000001;
            27     : qH_int = 60'h813d80000000001;
            28     : qH_int = 60'h814000000000001;
            default: qH_int = 60'h800580000000001; // default to first prime
        endcase
    end
end


assign qH = qH_int[LOGQ-1 : LOGQ - LOGQH];  // take MSB LOGQH bits

endmodule