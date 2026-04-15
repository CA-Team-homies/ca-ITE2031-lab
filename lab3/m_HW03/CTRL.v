`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg RegDst,
	output reg Jump,
	output reg Branch,
	output reg MemRead,
	output reg MemtoReg,
	output reg [3:0] ALUOp,
	output reg MemWrite,
	output reg ALUSrc,
	output reg RegWrite,
	// NEW !
	output reg JR, // jr inst 인가?
	output reg SignExtend, // singextend를 사용할 것인가?
	// I type memory, alu 같은 경우만 signextend를 사용; LSB 16bit
	output reg SavePC // 돌아올 pc값을 RF에 저장해줄 것인가? 
	// -> For jal label : GPR[ra] = PC+4 
    );

	always @(*) begin
		
	end
endmodule
