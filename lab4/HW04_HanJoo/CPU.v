`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU(
	input			clk,
	input			rst,
	output 		halt
	);

	// Define PC
	reg [31:0] PC;

	// Microarchitectural Registers
	reg [31:0] PC_next;
	reg [31:0] IR;
	reg [31:0] MDR;
	reg [31:0] A;
	reg [31:0] B;
	reg [31:0] ALUOut;
	reg [2:0] State;

	reg [4:0] wr_addr;
	reg [31:0] wr_data;
	reg [31:0] Address;
	reg [31:0] Operand1;
	reg [31:0] Operand2;
	
	// Split the Instructions
	wire [5:0] opcode;
	wire [4:0] rs;
	wire [4:0] rt;
	wire [4:0] rd;
	wire [4:0] shamt;
	wire [5:0] funct;
	wire [15:0] immi;
	wire [25:0] immj;

	wire [4:0] rd_addr1;
	wire [4:0] rd_addr2;
	wire [31:0] rd_data1;
	wire [31:0] rd_data2;
	wire [31:0] mem_write_data;
	wire [31:0] mem_read_data;
	//wire [31:0] r31;

	wire [31:0] alu_result;

	// Control-related wires
	wire [1:0] RegDst;
	wire RegWrite;
	wire [1:0] MemtoReg;
	wire MemWrite;
	wire IorD;
	wire SignExtend;
	wire ALUSrcA;
	wire [1:0] ALUSrcB;
	wire [3:0] ALUOp;
	wire [1:0] PCSource;
	wire PCWriteCond;
	wire PCWrite;
	wire [2:0] NextState;
	wire IRWrite;
	wire InstDone;


	// Define the wires
	assign opcode = IR[31:26];
	assign rs = 		IR[25:21];
	assign rt = 		IR[20:16];
	assign rd = 		IR[15:11];
	assign shamt = 	IR[10:6];
	assign funct = 	IR[5:0];
	assign immi = 	IR[15:0];
	assign immj = 	IR[25:0];

  	assign rd_addr1 = rs;
  	assign rd_addr2 = rt;

	assign mem_write_data = B;

	assign halt	= (IR == 32'b0);
	
	always @(*) begin
		Address = IorD ? ALUOut : PC;
		case (RegDst)
			2'd0: wr_addr = rt;
			2'd1: wr_addr = rd;
			2'd2: wr_addr = 5'd31;
		endcase
		case (MemtoReg)
			2'd0: wr_data = ALUOut;
			2'd1: wr_data = MDR;
			2'd2: wr_data = PC;
		endcase
		Operand1 = ALUSrcA ? A : PC;
		case (ALUSrcB)
			2'd0: Operand2 = B;
			2'd1: Operand2 = 32'd4;
			2'd2: Operand2 = SignExtend ? {{16{immi[15]}}, immi} : {16'b0, immi};
			2'd3: Operand2 = {{16{immi[15]}}, immi} << 2;
		endcase
		case (PCSource)
			2'd0: PC_next = alu_result;
			2'd1: PC_next = ALUOut;
			2'd2: PC_next = (PC & 32'hF0000000) | (immj << 2);
			//2'd3: PC_next = A;
			2'd3: PC_next = rd_data1;
		endcase
	end

	// Update the Clock
	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
			IR <= 0;
			MDR <= 0;
			A <= 0;
			B <= 0;
			ALUOut <= 0;
			State <= `STATE0;
		end
		else begin
			if (PCWrite || (PCWriteCond && (alu_result == 0))) begin
				PC <= PC_next;
			end
			if (IRWrite) begin
				IR <= mem_read_data;
			end
			// always latched
			MDR <= mem_read_data;
			A <= rd_data1;
			B <= rd_data2;
			ALUOut <= alu_result;
			State <= NextState;
		end	
	end
	
	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		.State(State),
		.RegDst(RegDst),
		.RegWrite(RegWrite),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.IorD(IorD),
		.SignExtend(SignExtend),
		.ALUSrcA(ALUSrcA),
		.ALUSrcB(ALUSrcB),
		.ALUOp(ALUOp),
		.PCSource(PCSource),
		.PCWriteCond(PCWriteCond),
		.PCWrite(PCWrite),
		.NextState(NextState),
		.IRWrite(IRWrite),
		.InstDone(InstDone)
	);

	RF rf (
		.clk(clk),
		.rst(rst),
		.rd_addr1(rd_addr1),
		.rd_addr2(rd_addr2),
		.rd_data1(rd_data1),
		.rd_data2(rd_data2),
		.RegWrite(RegWrite),
		.wr_addr(wr_addr),
		.wr_data(wr_data)
	);

	MEM mem (
		.clk(clk),
		.rst(rst),
		.mem_addr(Address),
		.MemWrite(MemWrite),
		.mem_write_data(mem_write_data),
		.mem_read_data(mem_read_data)
	);
	
	ALU alu (
		.operand1(Operand1),
		.operand2(Operand2),
		.shamt(shamt),
		.funct(ALUOp),
		.alu_result(alu_result)
	);
	
endmodule
