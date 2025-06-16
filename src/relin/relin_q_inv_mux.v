module relin_q_inv_mux
   #(   
        parameter LOGN     = 16,
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64
    )
    (
        input                 clk,
        input                 rst,
        input      [LOGL-1:0] i  ,
        output reg [LOGQ-1:0] q_inv
    );



if (LOGN == 12) begin
    always @(*) begin
        case (i)
            0      : q_inv = 60'h0c3149249249e7a;
            1      : q_inv = 60'h0375d67c8a61bad;
            default: q_inv = 60'h0c3149249249e7a;
        endcase
    end
end
else if (LOGN == 13) begin
    always @(*) begin
        case (i)
            0      : q_inv = 60'h0fd2a84508a1703;
            1      : q_inv = 60'h67a4f3cf3cf430d;
            2      : q_inv = 60'h6792b3bea3682ba;
            3      : q_inv = 60'h764989d89d8b13c;
            default: q_inv = 60'h0fd2a84508a1703;
        endcase
    end
end
else if (LOGN == 14) begin
    always @(*) begin
        case (i)
            0      : q_inv = 60'h75b88d3dcb09030;
            1      : q_inv = 60'h42aacafb74a3c98;
            2      : q_inv = 60'h6cb1a2e8ba2ec9c;
            3      : q_inv = 60'h274060dd67c8efe;
            4      : q_inv = 60'h28b88a8a8a8aeaf;
            5      : q_inv = 60'h558b00000001556;
            6      : q_inv = 60'h000000000008000;
            default: q_inv = 60'h75b88d3dcb09030;
        endcase
    end
end
else if (LOGN == 15) begin
    always @(*) begin
        case (i)
            0      : q_inv = 60'h6305ab235bef1dc;
            1      : q_inv = 60'h54a30c30c30c47c;
            2      : q_inv = 60'h667b99999999b34;
            3      : q_inv = 60'h690059e6507b65f;
            4      : q_inv = 60'h29cae88e88e8ac9;
            5      : q_inv = 60'h32d771826a43c61;
            6      : q_inv = 60'h5591aaaaaaaad56;
            7      : q_inv = 60'h08317a8d9df546d;
            8      : q_inv = 60'h707b1c71c71ca76;
            9      : q_inv = 60'h000000000000400;
            10     : q_inv = 60'h7e5624924924d73;
            11     : q_inv = 60'h681373cf3cf430d;
            12     : q_inv = 60'h12dbd3a06d3a741;
            13     : q_inv = 60'h4fa3679e79e8619;
            default: q_inv = 60'h6305ab235bef1dc;
        endcase
    end
end
else if (LOGN == 16) begin
    always @(*) begin
        case (i)
            0      : q_inv = 60'h3dab8d6e4bb3893;
            1      : q_inv = 60'h7cbf96f96f9706a;
            2      : q_inv = 60'h3a0ce178cdd8cde;
            3      : q_inv = 60'h2f178c36468efb8;
            4      : q_inv = 60'h0798c536fe1a9b8;
            5      : q_inv = 60'h36612e3aca05695;
            6      : q_inv = 60'h2eb30daa1be3115;
            7      : q_inv = 60'h117db1cb1cb1dd2;
            8      : q_inv = 60'h532c6b46b46b5a4;
            9      : q_inv = 60'h41b3f3afa2ac79e;
            10     : q_inv = 60'h413f291e81fd6e2;
            11     : q_inv = 60'h33477e2d3828ef4;
            12     : q_inv = 60'h1990e68cb9a3466;
            13     : q_inv = 60'h74fd3c1091d00d5;
            14     : q_inv = 60'h28044863b721ad9;
            15     : q_inv = 60'h35235d75d75d966;
            16     : q_inv = 60'h2eae8c3d31fa021;
            17     : q_inv = 60'h51c2a2576a25a8a;
            18     : q_inv = 60'h6f6c9161f9ae066;
            19     : q_inv = 60'h320e1e9131ac2de;
            20     : q_inv = 60'h6a7abaebaebb2cc;
            21     : q_inv = 60'h6beb99999999e42;
            22     : q_inv = 60'h4c32ad1ad1ad68e;
            23     : q_inv = 60'h6d3189d89d8a277;
            24     : q_inv = 60'h4cc3f22983760de;
            25     : q_inv = 60'h000000000001000;
            26     : q_inv = 60'h113abbbbbbbddde;
            27     : q_inv = 60'h33b23333333999a;
            default: q_inv = 60'h3dab8d6e4bb3893;
        endcase
    end
end


endmodule