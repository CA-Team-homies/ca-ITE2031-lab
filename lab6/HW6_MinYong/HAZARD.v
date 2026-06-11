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
        // ID stage에 있는게 valid 한 instruction이 아닌데, 
        // 즉, nop인 상황인데 우연치않게 reg operand/regdst가 겹칠 때 rebundant 한 stall이 생길 수 있다.
        // CPU.v 에서 nop에 대한 if 문에서 코드 길어지는거 막으려고 operand 값 똑같이 넣어줘서 그럼.
        if (valid) begin
            case (opcode)
                `OP_RTYPE: begin
                    case (funct)
                        `FUNCT_JR: use_reg = 2'b01; // rs 
                        `FUNCT_SLL,`FUNCT_SRA,`FUNCT_SRL: use_reg = 2'b10; // rt 
                        default:    use_reg = 2'b11; // rs,rt
                    endcase
                end

                `OP_BEQ,`OP_BNE,`OP_SW: use_reg = 2'b11; // rs,rt
                `OP_J,`OP_JAL: use_reg = 2'b00; // 아무것도 안씀.
                default: begin
                    use_reg = 2'b01; // 그 이외의 I type inst
                end
            endcase
        end
    end

    always @(*) begin
        stall = 2'b00;

        if ((((rs == dest_EX) && use_reg[0] && RegWrite_EX) ||
             ((rt == dest_EX) && use_reg[1] && RegWrite_EX))) begin
            stall = `STALL3;
        end
        else if ((((rs == dest_MEM) && use_reg[0] && RegWrite_MEM) ||
                  ((rt == dest_MEM) && use_reg[1] && RegWrite_MEM))) begin
            stall = `STALL2;
        end
        else if ((((rs == dest_WB) && use_reg[0] && RegWrite_WB) ||
                  ((rt == dest_WB) && use_reg[1] && RegWrite_WB))) begin
            stall = `STALL1;
        end
    end
endmodule
