`timescale 1ns / 100ps

module TOP(
    input clk,
    input rst,
    
    // Read-related ports
    input [4:0] rd_addr1,
    input [4:0] rd_addr2,
    
    // Write-related ports
    input RegWrite,
    input [4:0] wr_addr,
    
    // ALU ctrl and output
    input [4:0] shamt,
    input [3:0] funct,
    output [31:0] rd_data1,
    output [31:0] rd_data2,
    output [31:0] wr_data
    );
    
	// FIXME
	// Instantiate modules and connect them!
    wire [31:0] net1;
    wire [31:0] net2;
    wire [31:0] net3;
    assign rd_data1 = net1;
    assign rd_data2 = net2; 
    assign wr_data = net3;
    // connecting them explicitly.
    RF rf (
        .clk(clk), 
        .rst(rst), 
        .rd_addr1(rd_addr1), 
        .rd_addr2(rd_addr2),
        .rd_data1(net1),
        .rd_data2(net2),
        .RegWrite(RegWrite),
        .wr_addr(wr_addr),
        .wr_data(net3)
    );
    ALU alu(
        .operand1(net1),
        .operand2(net2),
        .shamt(shamt),
        .funct(funct),
        .alu_result(net3)
    );

endmodule
