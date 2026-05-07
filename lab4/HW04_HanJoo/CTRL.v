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
				IorD = 0;
				IRWrite = 1;
				ALUSrcA = 0;
				ALUSrcB = 2'b01;
				PCWrite = 1;
				PCSource = 2'b00;
				NextState = `STATE1;
			end
			`STATE1: begin
			end
			`STATE2: begin
			end
			`STATE3: begin
				IorD = 1;
				if (opcode == `OP_LW) NextState = `STATE4;
				else if (opcode == `OP_SW) begin
					MemWrite = 1;
					NextState = `STATE0;
				end
			end
			`STATE4: begin
				RegDst = 0;
				RegWrite = 1;
				MemtoReg = 0;
				NextState = `STATE0;
				if (opcode == `OP_RTYPE) begin
					RegDst = 1;
				end
				else begin
					if (opcode == `OP_LW) MemtoReg = 1;
				end
			end
		endcase
	end
endmodule
