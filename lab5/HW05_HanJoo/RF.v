`timescale 1ns / 100ps

module RF (
    input clk,
    input rst,

    input [4:0] rd_addr1,
    input [4:0] rd_addr2,
    output [31:0] rd_data1,
    output [31:0] rd_data2,

    input RegWrite,
    input [4:0] wr_addr,
    input [31:0] wr_data
);

    reg [31:0] register_file [0:31];

    assign rd_data1 = (rd_addr1 == 5'd0) ? 32'd0 : register_file[rd_addr1];
    assign rd_data2 = (rd_addr2 == 5'd0) ? 32'd0 : register_file[rd_addr2];

    always @(posedge clk) begin
        if (rst) begin
            $readmemh("initial_reg7.mem", register_file);
            register_file[0] <= 32'd0;
        end
        else begin
            if (RegWrite && (wr_addr != 5'd0)) begin
                register_file[wr_addr] <= wr_data;
            end
            register_file[0] <= 32'd0;
        end
    end
endmodule
