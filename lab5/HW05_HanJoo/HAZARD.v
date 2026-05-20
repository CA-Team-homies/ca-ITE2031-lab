`timescale 1ns / 1ps
`include "GLOBAL.v"

module HAZARD (
    input       valid,
    input [5:0] opcode,
    input [5:0] funct,
    input [4:0] rs,
    input [4:0] rt,

    input [4:0] dest_EX,
    input [4:0] dest_MEM,
    input [4:0] dest_WB,

    input RegWrite_EX,
    input RegWrite_MEM,
    input RegWrite_WB,

    output reg [1:0] stall
);

    reg [1:0] use_reg;
    // use_reg[0] = use rs, use_reg[1] = use rt

    always @(*) begin
        use_reg = 2'b00;

        if (valid) begin
            case (opcode)
                `OP_RTYPE: begin
                    case (funct)
                        `FUNCT_JR: use_reg = 2'b01; // rs only
                        `FUNCT_SLL,
                        `FUNCT_SRA,
                        `FUNCT_SRL: use_reg = 2'b10; // rt only
                        default:    use_reg = 2'b11; // rs and rt
                    endcase
                end

                `OP_BEQ,
                `OP_BNE,
                `OP_SW: begin
                    use_reg = 2'b11;
                end

                `OP_J,
                `OP_JAL: begin
                    use_reg = 2'b00;
                end

                default: begin
                    use_reg = 2'b01; // most I-type instructions use rs only
                end
            endcase
        end
    end

    always @(*) begin
        stall = 2'b00;

        if ((dest_EX != 5'd0) &&
            (((rs == dest_EX) && use_reg[0] && RegWrite_EX) ||
             ((rt == dest_EX) && use_reg[1] && RegWrite_EX))) begin
            stall = `STALL3;
        end
        else if ((dest_MEM != 5'd0) &&
                 (((rs == dest_MEM) && use_reg[0] && RegWrite_MEM) ||
                  ((rt == dest_MEM) && use_reg[1] && RegWrite_MEM))) begin
            stall = `STALL2;
        end
        else if ((dest_WB != 5'd0) &&
                 (((rs == dest_WB) && use_reg[0] && RegWrite_WB) ||
                  ((rt == dest_WB) && use_reg[1] && RegWrite_WB))) begin
            stall = `STALL1;
        end
    end
endmodule
