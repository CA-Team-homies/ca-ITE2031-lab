`timescale 1ns / 1ps
`include "GLOBAL.v"

module HAZARD (
    input       valid,

    input [5:0] opcode,
    input [5:0] funct,
    input [4:0] rs,
    input [4:0] rt,

    input [4:0] dest_EX,
    input RegWrite_EX,
    input [1:0] MemtoReg_EX,

    input [4:0] dest_MEM,
    input RegWrite_MEM,
    input [1:0] MemtoReg_MEM,

    output reg [1:0] stall
);

    reg [1:0] use_reg;
    // use_reg[0] = use rs, use_reg[1] = use rt

    // branch early resolution을 괜히 해주었는가...
    reg is_branch;
    // 혹시 lw 십니까?
    // branch 에 대해선 lw 직후 stall이 또 다르다
    wire lw_in_EX;
    wire lw_in_MEM;


    // dep. 찾기 변수 따로 빼두기...
    wire dep_rs_EX;
    wire dep_rt_EX;
    wire dep_rs_MEM;
    wire dep_rt_MEM;

    always @(*) begin
        use_reg   = 2'b00;
        is_branch = 1'b0;

        // ID stage에 있는게 valid 한 instruction이 아닌데,
        // 즉, nop인 상황인데 우연치않게 reg operand/regdst가 겹칠 때 redundant 한 stall이 생길 수 있다.
        if (valid) begin
            case (opcode)
                `OP_RTYPE: begin
                    case (funct)
                        `FUNCT_JR: use_reg = 2'b01; // rs
                        `FUNCT_SLL, `FUNCT_SRA, `FUNCT_SRL: use_reg = 2'b10; // rt
                        default: use_reg = 2'b11; // rs, rt
                    endcase
                end
                `OP_BEQ, `OP_BNE: begin
                    use_reg = 2'b11;
                    is_branch = 1'b1;
                end
                `OP_SW: use_reg = 2'b11;
                `OP_J, `OP_JAL: use_reg = 2'b00;
                default: use_reg = 2'b01;
            endcase
        end
    end

    // MemtoReg = 0 -> lw 임!
    assign lw_in_EX  = RegWrite_EX  && (MemtoReg_EX  == 2'b00);
    assign lw_in_MEM = RegWrite_MEM && (MemtoReg_MEM == 2'b00);
 
    assign dep_rs_EX = use_reg[0] && RegWrite_EX && (rs == dest_EX);
    assign dep_rt_EX = use_reg[1] && RegWrite_EX &&(rt == dest_EX);
    assign dep_rs_MEM = use_reg[0] && RegWrite_MEM && (rs == dest_MEM);
    assign dep_rt_MEM = use_reg[1] && RegWrite_MEM && (rt == dest_MEM);

    always @(*) begin
        stall = 2'b00;
        if (valid) begin
            if (is_branch) begin
                // 지금 나 branch 니?
                if (dep_rs_EX || dep_rt_EX) begin
                    // lw 면 좀 많이 멈추기
                    if (lw_in_EX) stall = `STALL2;
                    else stall = `STALL1;
                end
                else if ((dep_rs_MEM || dep_rt_MEM) && lw_in_MEM) stall = `STALL1;
            end
            else begin
                // lw일때와 dist가 1일때만 멈추기
                if ((dep_rs_EX || dep_rt_EX) && lw_in_EX) stall = `STALL1;
            end
        end
    end
endmodule
