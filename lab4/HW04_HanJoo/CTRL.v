`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,
	// input current state
	input [2:0] State,

	// output various ports
	output reg [1:0] RegDst,
	output reg RegWrite,

	output reg [1:0] MemtoReg,
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
		RegDst = 0;
		RegWrite = 0;
		MemtoReg = 0;
		MemWrite = 0;
		IorD = 0;
		ALUSrcA = 0;
		ALUSrcB = 0;
		ALUOp = 0;
		PCSource = 0;
		PCWriteCond = 0;
		PCWrite = 0;
		//NextState = 0;
		IRWrite = 0;
		InstDone = 0;

		case (State)
			`STATE0: begin
				IorD = 0;
				IRWrite = 1;
				ALUSrcA = 0;
				ALUSrcB = 2'b01;
				PCWrite = 1;
				PCSource = 2'b00;
				ALUOp = `ALU_ADDU;
				NextState = `STATE1;
			end

			`STATE1: begin
				RegDst = 0;
				RegWrite = 0;
				MemtoReg = 0;
				MemWrite = 0;
				IorD = 0;
				ALUSrcA = 0;
				ALUSrcB = 0;
				ALUOp = 0;
				PCSource = 0;
				PCWriteCond = 0;
				PCWrite = 0;
				//NextState = 0;
				IRWrite = 0;
				InstDone = 0;

				if (opcode == `OP_J || opcode ==`OP_JAL) begin
					PCWrite = 1;
					PCSource = 2'b10;
					if (opcode == `OP_JAL) begin
						MemtoReg = 2'b10;
						RegDst = 2'b10;
						RegWrite = 1;
					end
					NextState = `STATE0;
				end
				else if ((opcode == `OP_RTYPE) && (funct == `FUNCT_JR)) begin
					PCWrite = 1;
					PCSource = 2'b11;	
					NextState = `STATE0;
				end
				else begin
					ALUSrcA = 0;
					ALUSrcB = 2'b11;
					ALUOp = `ALU_ADDU;
					NextState = `STATE2;
				end
			end

			`STATE2: begin
				RegDst = 0;
				RegWrite = 0;
				MemtoReg = 0;
				MemWrite = 0;
				IorD = 0;
				ALUSrcA = 0;
				ALUSrcB = 0;
				ALUOp = 0;
				PCSource = 0;
				PCWriteCond = 0;
				PCWrite = 0;
				//NextState = 0;
				IRWrite = 0;
				InstDone = 0;

				if (opcode == `OP_BEQ || opcode == `OP_BNE) begin
					ALUSrcA = 1;
					ALUSrcB = 2'b00;
					ALUOp = (opcode == `OP_BEQ) ? `ALU_NEQ : `ALU_EQ;
					PCSource = 2'b01;
					PCWriteCond = 1;
					NextState = `STATE0;
				end
				else if (opcode == `OP_RTYPE) begin
					ALUSrcA = 1;
					ALUSrcB = 2'b00;
					NextState = `STATE4;
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
				else begin // For other I-type inst'
					ALUSrcA = 1;
					ALUSrcB = 2'b10;
					case(opcode)
						`OP_ADDIU: ALUOp = `ALU_ADDU; 
						`OP_SLTI: ALUOp = `ALU_SLT; 
						`OP_SLTIU: ALUOp = `ALU_SLTU; 
						`OP_ANDI: ALUOp = `ALU_AND; 
						`OP_ORI: ALUOp = `ALU_OR; 
						`OP_XORI: ALUOp = `ALU_XOR; 
						`OP_LUI: ALUOp = `ALU_LUI; 
					endcase
					NextState = `STATE4;
					if (opcode == `OP_LW || opcode == `OP_SW) begin
						ALUOp = `ALU_ADDU;
						NextState = `STATE3;
					end
				end
			end

			`STATE3: begin
				RegDst = 0;
				RegWrite = 0;
				MemtoReg = 0;
				MemWrite = 0;
				IorD = 0;
				ALUSrcA = 0;
				ALUSrcB = 0;
				ALUOp = 0;
				PCSource = 0;
				PCWriteCond = 0;
				PCWrite = 0;
				//NextState = 0;
				IRWrite = 0;
				InstDone = 0;

				IorD = 1;
				if (opcode == `OP_LW) begin
					NextState = `STATE4;
				end
				else if (opcode == `OP_SW) begin
					MemWrite = 1;
					NextState = `STATE0;
				end
			end

			`STATE4: begin
				RegDst = 0;
				RegWrite = 0;
				MemtoReg = 0;
				MemWrite = 0;
				IorD = 0;
				ALUSrcA = 0;
				ALUSrcB = 0;
				ALUOp = 0;
				PCSource = 0;
				PCWriteCond = 0;
				PCWrite = 0;
				//NextState = 0;
				IRWrite = 0;
				InstDone = 0;

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
