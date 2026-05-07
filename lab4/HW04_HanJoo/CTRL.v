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
				if opcode == `OP_J or `OP_JAL begin
					PCWrite = 1;
					PCSource = 10;
					if opcode == `OP_JAL begin
						MemtoReg = 10;
						RegDst = 10;
						RegWrite = 1;
					end
					NextState = 0;
				end
				else if (opcode == `OP_RTYPE) && (funct == `FUNCT_JR) begin
					PCWrite = 1;
					PCSource = 11;	
					NextState = 0;
				end
				else begin
					ALUSrcA = 0;
					ALUSrcB = 11;
					ALUOp = `ALU_ADDU;
					NextState = 2;
				end

			end
			`STATE2: begin
				if opcode == `OP_BEQ begin
					ALUSrcA = 1;
					ALUSrcB = 00;
					ALUOp = `ALU_SUBU;
					PCSource = 01;
					PCWriteCond = 1;
					NextState = 0;
				end
				else if opcode == `OP_RTYPE begin
					ALUSrcA = 1;
					ALUSrcB = 00;
					NextState = 4;
					ALUOp = funct
				end
				else // For other I-type inst'
					ALUSrcA = 1;
					ALUSrcB = 10;
					ALUOp = opcode;
					NextState = 4;
				if (opcode == `OP_LW) or (opcode == `OP_SW) begin
					NextState = 3;
				end
			end
			`STATE3: begin
			end
			`STATE4: begin
			end
		endcase
	end
endmodule
