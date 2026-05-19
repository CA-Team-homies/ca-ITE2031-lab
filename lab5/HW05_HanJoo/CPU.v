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
	// IF/ID
	reg [31:0] IFID_PC;
	reg [31:0] IFID_Inst;

	// ID/EX
	reg IDEX_RegWrite;
	reg [1:0] IDEX_MemtoReg;

	reg IDEX_MemWrite;

	reg [1:0] IDEX_PCSource;
	reg IDEX_SignExtend;
	reg IDEX_ALUSrc;
	reg [3:0] IDEX_ALUOp;
	reg [1:0] IDEX_RegDst;

	reg [31:0] IDEX_PC;
	reg [31:0] IDEX_Data1;
	reg [31:0] IDEX_Data2;
	reg [25:0] IDEX_IMMJ;
	reg [15:0] IDEX_IMMI; // resolve @ EX stage
	reg [4:0] IDEX_RT;
	reg [4:0] IDEX_RD;

	// EX/MEM
	reg EXMEM_RegWrite;
	reg [1:0] EXMEM_MemtoReg;

	reg EXMEM_MemWrite;

	reg [31:0] EXMEM_PC;
	reg [31:0] EXMEM_ALUResult;
	reg [31:0] EXMEM_Data;
	reg [4:0] EXMEM_RegAddr;

	// MEM/WB
	reg MEMWB_RegWrite;
	reg [1:0] MEMWB_MemtoReg;

	reg [31:0] MEMWB_PC;
	reg [31:0] MEMWB_Data;
	reg [31:0] MEMWB_ALUResult;
	reg [4:0] MEMWB_RegAddr;

	// define variables
	reg [31:0] PC_next;
	reg [31:0] ext_imm;
	reg [4:0] RegAddr;
	reg [31:0] RegData;
	reg [31:0] operand2;

	reg [1:0] stall;
	wire taken;

	// define wires
	wire [31:0] inst_addr;
	wire [31:0] inst;

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

	wire [31:0] inst_addr;
	wire [31:0] inst;
	wire [31:0] mem_write_data;
	wire [31:0] mem_read_data;
	wire [31:0] mem_addr;


	wire [31:0] operand1;
	wire [31:0] operand2;
	wire [31:0] alu_result;

	// Control-related wires
	wire RegWrite;
	wire [1:0] MemtoReg;
	wire MemWrite;
	wire [1:0] PCSource;
	wire SignExtend;
	wire ALUSrc;
	wire [3:0] ALUOp;
	wire [1:0] RegDst;

	// Define the wires
	assign opcode = IFID_Inst[31:26];
	assign rs = 		IFID_Inst[25:21];
	assign rt = 		IFID_Inst[20:16];
	assign rd = 		IFID_Inst[15:11];
	assign shamt = 	IFID_Inst[10:6];
	assign funct = 	IFID_Inst[5:0];
	assign immi = 	IFID_Inst[15:0];
	assign immj = 	IFID_Inst[25:0];

	assign halt	= (IR == 32'b0);
	assign taken = ((opcode == `OP_BEQ && IDEX_Data1 == IDEX_Data2) || (opcode == `OP_BNE && IDEX_Data1 != IDEX_Data2))

	// opcode == beq/bne && taken 아니야... flush 
	always @(*) begin
		ext_imm = IDEX_SignExtend ? {{16{immi[15]}}, IDEX_IMMI} : {16'b0, IDEX_IMMI};
		case (PCSource)
			2'd0: PC_next = PC + 4;
			2'd1: PC_next = PC + 4 + (taken ? ext_imm : 0);
			2'd2: PC_next = ((PC + 4) & 32'hF0000000) | (IDEX_IMMJ << 2);
			2'd3: PC_next = IDEX_Data1;
		endcase
		case (RegDst)
			2'd0: RegAddr = rt;
			2'd1: RegAddr = rd;
			2'd2: RegAddr = 5'd31;
		endcase
		case (MemtoReg)
			2'd0: RegData = MEMWB_Data;
			2'd1: wr_data = MEMWB_ALUResult;
			2'd2: wr_data = MEMWB_PC;
		endcase
		operand2 = ALUSrc ? ext_imm : IDEX_Data2;
	end

	// Update the Clock
	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
		end
		else begin
			// j, jr은 EX에서 immj, rddata1 EXstage에 점프추가
			// Branch는 MEM에서 점프
			// jal은 WB까지 가야함 점프는 EX에서 미리하되 HAZARD 신경쓰기
			// 시그널 다시 설정후 삼항연산자사용
			PC <= PC_next;
			IFID_PC <= PC + 4;
			IFID_Inst <= inst;

			IDEX_RegWrite <= RegWrite;
			IDEX_MemtoReg <= MemtoReg;
			IDEX_MemWrite <= MemWrite;
			IDEX_PCSource <= PCSource;
			IDEX_SignExtend <= SignExtend;
			IDEX_ALUSrc <= ALUSrc;
			IDEX_ALUOp <= ALUOp;
			IDEX_RegDst <= RegDst;
			IDEX_PC <= IFID_PC;
			IDEX_Data1 <= rd_data1;
			IDEX_Data2 <= rd_data2;
			IDEX_IMMI <= immi;
			IDEX_IMMJ <= immj;
			IDEX_RT <= rt;
			IDEX_RD <= rd;

			EXMEM_RegWrite <= IDEX_RegWrite;
			EXMEM_MemtoReg <= IDEX_MemtoReg;
			EXMEM_MemWrite <= IDEX_MemWrite;
			EXMEM_PC <= IDEX_PC;
			EXMEM_ALUResult <= alu_result;
			EXMEM_Data <= IDEX_Data2;
			EXMEM_RegAddr <= RegAddr;
			
			MEMWB_RegWrite <= EXMEM_RegWrite;
			MEMWB_MemtoReg <= EXMEM_MemtoReg;
			MEMWB_PC <= EXMEM_PC;
			MEMWB_Data <= mem_read_data;
			MEMWB_ALUResult <= EXMEM_ALUResult;
			MEMWB_RegAddr <= EXMEM_RegAddr;
		end	
	end
	
	HAZARD hazard(
		.opcode(opcode),
		.rs(rs),
		.rt(rt),
		.dest_EX(RegAddr),
		.dest_MEM(EXMEM_RegAddr),
		.dest_WB(MEMWB_RegAddr),
		.RegWrite_EX(IDEX_RegWrite),
		.RegWrite_MEM(EXMEM_RegWrite),
		.RegWrite_WB(MEMWB_RegWrite),
		.stall(stall)
	);

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
