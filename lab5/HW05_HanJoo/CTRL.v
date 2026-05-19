`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg RegWrite,
	output reg [1:0] MemtoReg,
	output reg MemWrite,
	output reg [1:0] PCSource,
	output reg SignExtend,
	output reg ALUSrc,
	output reg [3:0] ALUOp,
	output reg [1:0] RegDst,
  );

	always @(*) begin
		RegWrite = 0;
		MemtoReg = 0;
		MemWrite = 0;
		PCSource = 0;
		SignExtend = 0;
		ALUSrc = 0;
		ALUOp = 0;
		RegDst = 0;
		if(opcode == `OP_RTYPE) begin
			RegDst = 2'b01;
			MemtoReg = 2'b01;
			RegWrite = 1;
			if(funct == `FUNCT_JR) begin
				PCSource = 2'b11;
				RegWrite = 0;
			end
			else begin
				case(funct)
					`FUNCT_ADDU:  ALUOp = `ALU_ADDU;
					`FUNCT_AND: 	ALUOp = `ALU_AND;
					`FUNCT_NOR: 	ALUOp = `ALU_NOR;
					`FUNCT_OR: 		ALUOp = `ALU_OR;
					`FUNCT_SLT:		ALUOp = `ALU_SLT;
					`FUNCT_SLTU: 	ALUOp = `ALU_SLTU;
					`FUNCT_SUBU: 	ALUOp = `ALU_SUBU;
					`FUNCT_XOR: 	ALUOp = `ALU_XOR;
					`FUNCT_SLL: 	ALUOp = `ALU_SLL;
					`FUNCT_SRA: 	ALUOp = `ALU_SRA;
					`FUNCT_SRL: 	ALUOp = `ALU_SRL;
				endcase
			end
		end
		case(opcode)
			`OP_J: begin
				PCSource = 2'b10;
			end

			`OP_JAL: begin
				PCSource = 2'b10;
				MemtoReg = 2'b10
				RegWrite = 1;
			end

			`OP_BEQ: begin
				PCSource = 2'b01;
				SignExtend = 1;
			end

			`OP_BNE: begin
				PCSource = 2'b01;
				SignExtend = 	1;
			end

			`OP_ADDIU: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				SignExtend = 	1;
				ALUOp = `ALU_ADDU;
			end

			`OP_SLTI: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				SignExtend = 1;
				ALUOp = `ALU_SLT;
			end

			`OP_SLTIU: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				SignExtend = 1;
				ALUOp = `ALU_SLTU;
			end

			`OP_ANDI: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				ALUOp = `ALU_AND;
			end

			`OP_ORI: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				ALUOp = `ALU_OR;
			end

			`OP_XORI: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				ALUOp = `ALU_XOR;
			end

			`OP_LUI: begin
				MemtoReg = 2'b01;
				RegWrite = 1;
				ALUSrc = 1;
				ALUOp = `ALU_LUI;
			end

			`OP_LW: begin
				MemtoReg = 2'b00;
				ALUSrc = 1;
				SignExtend = 1;
				RegWrite = 1;
				ALUOp = `ALU_ADDU;
			end

			`OP_SW: begin
				MemWrite = 1;
				ALUSrc = 1;
				SignExtend = 1;
				ALUOp = `ALU_ADDU;
			end
		endcase
	end
endmodule
