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
    RF rf (clk, rst, rd_addr1, rd_addr2, rd_data1, rd_data2, RegWrite, wr_addr, wr_data);
    ALU alu (rd_data1, rd_data2, shamt, funct, rf.wr_data);
    
    // RF input
    // rf.wr_data = alu.alu_result;
    // rf.rd_addr1 = rd_addr1;
    // rf.rd_addr2 = rd_addr2;
    // rf.wr_addr = wr_addr;
    // rf.RegWrite = RegWrite;
    // rf.clk = clk;
    // rf.rst = rst;

    // // RF output
    // rd_data1 = rf.rd_data1;
    // rd_data2 = rf.rd_data2;

    // // ALU input
    // alu.operand1 = rf.rd_data1;
    // alu.operand2 = rf.rd_data2;
    // alu.funct = funct;
    // alu.shamt = shant;

    // // ALU output
    // alu_result = alu.alu_result;

    
endmodule
