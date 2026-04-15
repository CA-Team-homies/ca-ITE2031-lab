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
	output reg JR,
	output reg MemRead,
	output reg MemtoReg,
	output reg MemWrite,
	output reg ALUSrc,
	output reg SignExtend,
	output reg RegWrite,
	output reg [3:0] ALUOp,
	output reg SavePC
  );

	always @(*) begin
		RegDst = 			0;
		Jump = 				0;
		Branch = 			0;
		JR = 					0;
		MemRead = 		0;
		MemtoReg = 		0;
		MemWrite = 		0;
		ALUSrc = 			0;
		SignExtend = 	0;
		RegWrite = 		0;
		SavePC = 			0;
		if(opcode == OP_RTYPE) begin
			RegDst = 			1;
			RegWrite = 		1;
			if(funct == FUNCT_JR) begin
				JR = 1;
				RegWrite = 0;
			end
			else begin
				case(funct)
					FUNCT_ADDU: ALUOp = ALU_ADDU;
					FUNCT_AND: 	ALUOp = ALU_AND;
					FUNCT_NOR: 	ALUOp = ALU_NOR;
					FUNCT_OR: 	ALUOp = ALU_OR;
					FUNCT_SLT:	ALUOp = ALU_SLT;
					FUNCT_SLTU: ALUOp = ALU_SLTU;
					FUNCT_SUBU: ALUOp = ALU_SUBU;
					FUNCT_XOR: 	ALUOp = ALU_XOR;
					FUNCT_SLL: 	ALUOp = ALU_SLL;
					FUNCT_SRA: 	ALUOp = ALU_SRA;
					FUNCT_SRL: 	ALUOp = ALU_SRL;
			endcase
		end
		else{
			
		}
		// done for R/
		
		case(opcode)
			OP_J: begin
				// RegDst = 			x;
				Jump = 				1;
				Branch = 			x;
				JR = 					0;
				MemRead = 		0;
				MemtoReg = 		x;
				MemWrite = 		0;
				ALUSrc = 			x;
				SignExtend = 	x;
				RegWrite = 		0;
				SavePC = 			x;
			end

			OP_JAL: begin
				RegDst = 			x;
				Jump = 				1;
				Branch = 			x;
				JR = 					0;
				MemRead = 		0;
				MemtoReg = 		x;
				MemWrite = 		0;
				ALUSrc = 			x;
				SignExtend = 	x;
				RegWrite = 		1;
				SavePC = 			1;
			end

			OP_BEQ: begin
				RegDst = 			x;
				Jump = 				0;
				Branch = 			1;
				JR = 					0;
				MemRead = 		0;
				MemtoReg = 		x;
				MemWrite = 		0;
				ALUSrc = 			0;
				SignExtend = 	1;
				RegWrite = 		0;
				SavePC = 			0;
				ALUOp = ALU_NEQ; // important
			end

			OP_BNE: begin
				RegDst = 			x;
				Jump = 				0;
				Branch = 			1;
				JR = 					0;
				MemRead = 		0;
				MemtoReg = 		x;
				MemWrite = 		0;
				ALUSrc = 			0;
				SignExtend = 	1;
				RegWrite = 		0;
				SavePC = 			0;
				ALUOp = ALU_EQ; // important
			end
			OP_ADDIU: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				SignExtend = 	1;
				ALUOp = ALU_AND; // important
			end
			OP_SLTI: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				SignExtend = 	1;
				ALUOp = ALU_SLT; // important
			end
			OP_SLTIU: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				SignExtend = 	1;
				ALUOp = ALU_SLTU; // important
			end
			OP_ANDI: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				//SignExtend = 	1;
				ALUOp = ALU_AND; // important
			end
			OP_ORI: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				//SignExtend = 	1;
				ALUOp = ALU_OR; // important
			end
			OP_XORI: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				//SignExtend = 	1;
				ALUOp = ALU_XOR; // important
			end
			OP_LUI: begin
				RegWrite = 		1;
				ALUSrc = 			1;
				ALUOp = ALU_LUI; // important
			end
		endcase
	end
endmodule
