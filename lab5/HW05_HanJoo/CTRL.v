`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
    input [5:0] opcode,
    input [5:0] funct,

    output reg RegWrite,
    output reg [1:0] MemtoReg,
    output reg MemWrite,
    output reg [1:0] PCSource,
    output reg SignExtend,
    output reg ALUSrc,
    output reg [3:0] ALUOp,
    output reg [1:0] RegDst
);

    always @(*) begin
        RegWrite   = 1'b0;
        MemtoReg   = 2'b00;
        MemWrite   = 1'b0;
        PCSource   = 2'b00;
        SignExtend = 1'b0;
        ALUSrc     = 1'b0;
        ALUOp      = `ALU_ADDU;
        RegDst     = 2'b00;

        case (opcode)
            `OP_RTYPE: begin
                RegDst   = 2'b01;
                MemtoReg = 2'b01;
                RegWrite = 1'b1;

                case (funct)
                    `FUNCT_JR: begin
                        PCSource = 2'b11;
                        RegWrite = 1'b0;
                    end
                    `FUNCT_ADDU: ALUOp = `ALU_ADDU;
                    `FUNCT_AND : ALUOp = `ALU_AND;
                    `FUNCT_NOR : ALUOp = `ALU_NOR;
                    `FUNCT_OR  : ALUOp = `ALU_OR;
                    `FUNCT_SLT : ALUOp = `ALU_SLT;
                    `FUNCT_SLTU: ALUOp = `ALU_SLTU;
                    `FUNCT_SUBU: ALUOp = `ALU_SUBU;
                    `FUNCT_XOR : ALUOp = `ALU_XOR;
                    `FUNCT_SLL : ALUOp = `ALU_SLL;
                    `FUNCT_SRA : ALUOp = `ALU_SRA;
                    `FUNCT_SRL : ALUOp = `ALU_SRL;
                    default: begin
                        RegWrite = 1'b0;
                        ALUOp = `ALU_ADDU;
                    end
                endcase
            end

            `OP_J: begin
                PCSource = 2'b10;
            end

            `OP_JAL: begin
                PCSource = 2'b10;
                RegDst   = 2'b10;   // $ra = $31
                MemtoReg = 2'b10;   // write PC + 4
                RegWrite = 1'b1;
            end

            `OP_BEQ: begin
                PCSource   = 2'b01;
                SignExtend = 1'b1;
            end

            `OP_BNE: begin
                PCSource   = 2'b01;
                SignExtend = 1'b1;
            end

            `OP_ADDIU: begin
                RegWrite   = 1'b1;
                MemtoReg   = 2'b01;
                ALUSrc     = 1'b1;
                SignExtend = 1'b1;
                ALUOp      = `ALU_ADDU;
            end

            `OP_SLTI: begin
                RegWrite   = 1'b1;
                MemtoReg   = 2'b01;
                ALUSrc     = 1'b1;
                SignExtend = 1'b1;
                ALUOp      = `ALU_SLT;
            end

            `OP_SLTIU: begin
                RegWrite   = 1'b1;
                MemtoReg   = 2'b01;
                ALUSrc     = 1'b1;
                SignExtend = 1'b1;
                ALUOp      = `ALU_SLTU;
            end

            `OP_ANDI: begin
                RegWrite = 1'b1;
                MemtoReg = 2'b01;
                ALUSrc   = 1'b1;
                ALUOp    = `ALU_AND;
            end

            `OP_ORI: begin
                RegWrite = 1'b1;
                MemtoReg = 2'b01;
                ALUSrc   = 1'b1;
                ALUOp    = `ALU_OR;
            end

            `OP_XORI: begin
                RegWrite = 1'b1;
                MemtoReg = 2'b01;
                ALUSrc   = 1'b1;
                ALUOp    = `ALU_XOR;
            end

            `OP_LUI: begin
                RegWrite = 1'b1;
                MemtoReg = 2'b01;
                ALUSrc   = 1'b1;
                ALUOp    = `ALU_LUI;
            end

            `OP_LW: begin
                RegWrite   = 1'b1;
                MemtoReg   = 2'b00;
                ALUSrc     = 1'b1;
                SignExtend = 1'b1;
                ALUOp      = `ALU_ADDU;
            end

            `OP_SW: begin
                MemWrite   = 1'b1;
                ALUSrc     = 1'b1;
                SignExtend = 1'b1;
                ALUOp      = `ALU_ADDU;
            end

            default: begin
                RegWrite   = 1'b0;
                MemtoReg   = 2'b00;
                MemWrite   = 1'b0;
                PCSource   = 2'b00;
                SignExtend = 1'b0;
                ALUSrc     = 1'b0;
                ALUOp      = `ALU_ADDU;
                RegDst     = 2'b00;
            end
        endcase
    end
endmodule
