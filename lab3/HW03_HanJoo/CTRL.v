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
	    RegDst = 0;
        Jump = 0;
        Branch = 0;
        JR = 0;
        MemRead = 0;
        MemtoReg = 0;
        MemWrite = 0;
        ALUSrc = 0;
        SignExtend = 0;
        RegWrite = 0;
        ALUOp = 0;
        SavePC = 0;
        if(opcode==`OP_RTYPE) 
            RegDst = 1;
        
        if(opcode==`OP_J || opcode==`OP_JAL || (opcode==`OP_RTYPE && funct==`FUNCT_JR)) 
            Jump = 1;
        
        if(opcode==`OP_BEQ || opcode==`OP_BNE) 
            Branch = 1;
        
        if(opcode==`OP_RTYPE && funct==`FUNCT_JR) 
            JR = 1;
        
        if(opcode==`OP_LW) begin
            MemRead = 1;
            MemtoReg = 1;
        end
        
        if(opcode==`OP_SW) 
            MemWrite = 1;
        
        if(opcode!=`OP_RTYPE && opcode!=`OP_BEQ && opcode!=`OP_BNE) 
            ALUSrc = 1;
        
        if(opcode==`OP_ADDIU || opcode==`OP_SLTI ||
            opcode==`OP_SLTIU ||opcode==`OP_BEQ ||
            opcode==`OP_BNE || opcode==`OP_LW || opcode==`OP_SW) 
            SignExtend = 1;
        
        if(opcode!=`OP_SW && opcode!=`OP_BEQ &&
            opcode!=`OP_BNE && opcode!=`OP_J && !(opcode==`OP_RTYPE && funct==`FUNCT_JR)) 
            RegWrite = 1;
        
        if((opcode==`OP_RTYPE && funct==`FUNCT_ADDU) || opcode==`OP_ADDIU ||
            opcode==`OP_LW || opcode==`OP_SW) 
            ALUOp = `ALU_ADDU;
        else if((opcode==`OP_RTYPE && funct==`FUNCT_AND) || opcode==`OP_ANDI) 
            ALUOp = `ALU_AND;
        else if(opcode==`OP_RTYPE && funct==`FUNCT_NOR) 
            ALUOp = `ALU_NOR;
        else if((opcode==`OP_RTYPE && funct==`FUNCT_OR) || opcode==`OP_ORI) 
            ALUOp = `ALU_OR;
        else if(opcode==`OP_RTYPE && funct==`FUNCT_SLL) 
            ALUOp = `ALU_SLL;
        else if(opcode==`OP_RTYPE && funct==`FUNCT_SRA) 
            ALUOp = `ALU_SRA;
        else if(opcode==`OP_RTYPE && funct==`FUNCT_SRL) 
            ALUOp = `ALU_SRL;
        else if(opcode==`OP_RTYPE && funct==`FUNCT_SUBU) 
            ALUOp = `ALU_SUBU;
        else if((opcode==`OP_RTYPE && funct==`FUNCT_XOR) || opcode==`OP_XORI) 
            ALUOp = `ALU_XOR;
        else if((opcode==`OP_RTYPE && funct==`FUNCT_SLT) || opcode==`OP_SLTI) 
            ALUOp = `ALU_SLT;
        else if((opcode==`OP_RTYPE && funct==`FUNCT_SLTU) || opcode==`OP_SLTIU) 
            ALUOp = `ALU_SLTU;
        else if(opcode==`OP_BEQ) 
            ALUOp = `ALU_EQ;
        else if(opcode==`OP_BNE) 
            ALUOp = `ALU_NEQ;
        else if(opcode==`OP_LUI) 
            ALUOp = `ALU_LUI;
            
        if(opcode==`OP_JAL)
            SavePC = 1;
        else
            SavePC = 0;
            
	end
endmodule