`timescale 1ns / 1ps
`include "GLOBAL.v"

module HAZARD (
		// Read-related ports
		input [5:0] opcode,
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
    // use_reg[0]->  use_rs, use_reg[1]->  use_rt

    // use_rs, use_rt 결정.
    always @(*) begin 
        use_reg = 0;
        case(opcode)
            // R 타입이면 둘다 읽기
            `OP_RTYPE : use_reg = 2'b11;
                // I 타입인데, beq, bne, sw 면 둘다 읽기
            `OP_BEQ, `OP_BNE,`OP_SW : use_reg = 2'b11;
                // J 타입이면 아예 안읽음
            `OP_J, `OP_JAL : use_reg = 2'b00;
                // 그 외의 I 타입 -> 01
            default: use_reg = 2'b01;
                
        endcase
    end
    always @(*) begin 
        stall = 0;
        if (()(rs == dest_EX) && use_reg[0] && RegWrite_EX) || ((rt == dest_EX) && use_reg[1] && RegWrite_EX)) stall = `STALL3;
        else if (((rs == dest_MEM) && use_reg[0] && RegWrite_MEM) || ((rt == dest_MEM) && use_reg[1] && RegWrite_MEM)) stall = `STALL2;
        else if (((rs == dest_WB) && use_reg[0] && RegWrite_WB) || ((rt == dest_WB) && use_reg[1] && RegWrite_WB)) stall = `STALL1;
    end

endmodule
