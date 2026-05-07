`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,
	// input current state
	input [2:0] State

	// output various ports
	output reg [1:0] RegDst,
	output reg RegWrite,

	output reg MemtoReg,
	output reg MemWrite,
	output reg IorD,

	output reg ALUSrcA,
	output reg [1:0] ALUSrcB,
	output reg [3:0] ALUOp,

	output reg [1:0] PCSource,
	output reg PCWriteCond,
	output reg PCWrite,

	output reg [2:0] NextState,
	output reg IRWrite,
	output reg InstDone
  );

	always @(*) begin
		// FIXME
		case (State)
			`STATE0: begin
			end
			`STATE1: begin
			end
			`STATE2: begin
			end
			`STATE3: begin
			end
			`STATE4: begin
			end
		endcase
	end
endmodule
