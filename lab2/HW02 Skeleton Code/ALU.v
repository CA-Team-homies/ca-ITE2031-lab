`timescale 1ns / 1ps
`include "GLOBAL.v"

// this is a combinational logic
module ALU(
		input [31:0]		operand1,
		input [31:0]		operand2,
		input [4:0]			shamt,
		input [3:0]			funct,
		output reg [31:0]	alu_result
	);
	
	// FIXME
	always @(*) begin
		case (funct)
			`ALU_ADD:
			`ALU_AND:
			`ALU_NOR:
			`ALU_OR :
			`ALU_SLL:
			`ALU_SRA:
			`ALU_SRL:
			`ALU_SUB:
			`ALU_XOR:
			`ALU_SLT:
			`ALU_EQ :
			`ALU_NEQ:
			`ALU_LUI:
			default:
		endcase
	end
endmodule
