`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU(
    input  clk,
    input  rst,
    output halt
);

    // PC
    reg [31:0] PC;

    // IF/ID
    reg        IFID_Valid;
    reg [31:0] IFID_PC;
    reg [31:0] IFID_Inst;

    // ID/EX
    reg        IDEX_Valid;
    reg        IDEX_Halt;
    reg        IDEX_RegWrite;
    reg [1:0]  IDEX_MemtoReg;
    reg        IDEX_MemWrite;
    reg [1:0]  IDEX_PCSource;
    reg        IDEX_SignExtend;
    reg        IDEX_ALUSrc;
    reg [3:0]  IDEX_ALUOp;
    reg [1:0]  IDEX_RegDst;
    reg [31:0] IDEX_PC;
    reg [31:0] IDEX_Data1;
    reg [31:0] IDEX_Data2;
    reg [25:0] IDEX_IMMJ;
    reg [15:0] IDEX_IMMI;
    reg [4:0]  IDEX_RT;
    reg [4:0]  IDEX_RD;
    reg [4:0]  IDEX_Shamt;

    // EX/MEM
    reg        EXMEM_Valid;
    reg        EXMEM_Halt;
    reg        EXMEM_RegWrite;
    reg [1:0]  EXMEM_MemtoReg;
    reg        EXMEM_MemWrite;
    reg [31:0] EXMEM_PC;
    reg [31:0] EXMEM_ALUResult;
    reg [31:0] EXMEM_Data;
    reg [4:0]  EXMEM_RegAddr;

    // MEM/WB
    reg        MEMWB_Valid;
    reg        MEMWB_Halt;
    reg        MEMWB_RegWrite;
    reg [1:0]  MEMWB_MemtoReg;
    reg [31:0] MEMWB_PC;
    reg [31:0] MEMWB_Data;
    reg [31:0] MEMWB_ALUResult;
    reg [4:0]  MEMWB_RegAddr;

    // 내부에서 사용할 reg 들... 
	// always 문에서 처리해주어야 해서 reg로 정의.
    reg [31:0] PC_next;
    reg [31:0] ext_imm;
    reg [4:0]  RegAddr;
    reg [31:0] RegData;
    reg [31:0] operand2;
    reg [1:0]  stall_count;

    // Split the instructions
	// Instruction-related wires
	// ID stage 분리시켜서 에서 사용할 wire들.
    wire [5:0]  opcode;
    wire [4:0]  rs;
    wire [4:0]  rt;
    wire [4:0]  rd;
    wire [4:0]  shamt;
    wire [5:0]  funct;
    wire [15:0] immi;
    wire [25:0] immj;

    wire [4:0]  rd_addr1;
    wire [4:0]  rd_addr2;
    wire [31:0] rd_data1;
    wire [31:0] rd_data2;

    wire [31:0] inst_addr;
    wire [31:0] inst;
    wire [31:0] mem_read_data;

    wire [31:0] operand1;
    wire [31:0] alu_result;

	// 현재 남은 #stall, stall인지 아닌지.
    wire [1:0] stall;
    wire stall_active;

    // CTRL.v 에서 바로 받아오는 signal들.
    wire        ctrl_RegWrite;
    wire [1:0]  ctrl_MemtoReg;
    wire        ctrl_MemWrite;
    wire [1:0]  ctrl_PCSource;
    wire        ctrl_SignExtend;
    wire        ctrl_ALUSrc;
    wire [3:0]  ctrl_ALUOp;
    wire [1:0]  ctrl_RegDst;

    // ID-stage gated control wires
    wire        id_valid_inst;
    wire        id_halt;
    wire        id_RegWrite;
    wire [1:0]  id_MemtoReg;
    wire        id_MemWrite;
    wire [1:0]  id_PCSource;
    wire        id_SignExtend;
    wire        id_ALUSrc;
    wire [3:0]  id_ALUOp;
    wire [1:0]  id_RegDst;

    // ID stage에서 사용할 wire 들; jump와 branch 관련 연산을 해야함.
    wire        branch_taken;
    wire [31:0] id_branch_target;
    wire [31:0] id_jump_target;
    wire        control_taken;
    wire        control_flush;

    // IF/ID field split
    assign opcode = IFID_Inst[31:26];
    assign rs     = IFID_Inst[25:21];
    assign rt     = IFID_Inst[20:16];
    assign rd     = IFID_Inst[15:11];
    assign shamt  = IFID_Inst[10:6];
    assign funct  = IFID_Inst[5:0];
    assign immi   = IFID_Inst[15:0];
    assign immj   = IFID_Inst[25:0];

    assign rd_addr1 = rs;
    assign rd_addr2 = rt;
    assign inst_addr = PC;

	// operand1 은 항상 RF[rs], 즉 rd_data1임.
	// -> IDEX_Data1 과 연결
    assign operand1 = IDEX_Data1;

	// ID stage에서 decode중인 inst가 nop인지, halt inst는 아닌지 확인해야함.
	// : nop 이 32'b0이기 때문에 inst만 보았을 때 halt와 구분이 안감.
	// IF/ID stage 부터 stall/flush가 생길 수 있음.
    assign id_valid_inst = IFID_Valid;
    assign id_halt = id_valid_inst && (IFID_Inst == 32'b0);

	// nop이 아니고 halt 가 아니면 CTRL.v 값 그대로 가져오고,
	// nop 이거나 halt 라면 기본 값 넣어주기.
    assign id_RegWrite   = (id_valid_inst && !id_halt) ? ctrl_RegWrite   : 1'b0;
    assign id_MemtoReg   = (id_valid_inst && !id_halt) ? ctrl_MemtoReg   : 2'b00;
    assign id_MemWrite   = (id_valid_inst && !id_halt) ? ctrl_MemWrite   : 1'b0;
    assign id_PCSource   = (id_valid_inst && !id_halt) ? ctrl_PCSource   : 2'b00;
    assign id_SignExtend = (id_valid_inst && !id_halt) ? ctrl_SignExtend : 1'b0;
    assign id_ALUSrc     = (id_valid_inst && !id_halt) ? ctrl_ALUSrc     : 1'b0;
    assign id_ALUOp      = (id_valid_inst && !id_halt) ? ctrl_ALUOp      : 4'b0000;
    assign id_RegDst     = (id_valid_inst && !id_halt) ? ctrl_RegDst     : 2'b00;

	// branch early resolution...
	// 간단한 로직이니, ALU.v 를 거치지 않고 알아서 검사.
    assign branch_taken =
        id_valid_inst && !id_halt &&
        (((opcode == `OP_BEQ) && (rd_data1 == rd_data2)) ||
         ((opcode == `OP_BNE) && (rd_data1 != rd_data2)));

	// branch target 과 jump target 값 일단 만들어 두기. 
    assign id_branch_target = IFID_PC + {{14{immi[15]}}, immi, 2'b00};
    assign id_jump_target   = {IFID_PC[31:28], immj, 2'b00};

	// c.f. PCSourve -> 1이면 branch, 2면 J나 Jal, 3이면 Jr
    assign control_taken =
        id_valid_inst && !id_halt &&
        ((id_PCSource == 2'd2) ||
         (id_PCSource == 2'd3) ||
         ((id_PCSource == 2'd1) && branch_taken));

	// 현재 ID stage에서 stall 인가?
    assign stall_active = (stall_count != 2'b00) || (stall != 2'b00);
	// flush 가 일어나는 순간 : mispred' 감지...
	// but stall 이 아닌 순간에만 flush 해야함...
	// 왜 Why... add r1 r2 r3, beq r1 r6 target 같은 경우,
	// add가 r1에 쓰고 있기 때문에 beq가 아직 r1 을 사용해서 T/NT를 결정해서는 안됨.
	// 즉 stall 해야함. 즉, stall이 우선이기 때문에 &&로 연산해야한다...
    assign control_flush = control_taken && !stall_active;

    
	//assign halt = (IFID_Inst == 32'b0);
	// 뒤쪽 pipeline에 아직 명령어가 돌고 있을 수도 있다...
	// IFID_Inst 를 기준으로 보아서는 안된다. 
	// 해서 MEM/WB까지 왔을 때, 즉 halt inst가 pipeline 끝까지 왔을 때 halt 시키기...
	// 또한 nop 자체가 32'b0이다. 즉, halt 와 구분되어야하므로 halt bit도 계속 넘겨주어야함. 
	assign halt = MEMWB_Valid && MEMWB_Halt;

    always @(*) begin
		// SignExtend -> Ex stage 에서 사용할 operand에 쓰일 extend 종류 결정
		// -> Ex stage signal...
        ext_imm = IDEX_SignExtend ? {{16{IDEX_IMMI[15]}}, IDEX_IMMI}
                                  : {16'b0, IDEX_IMMI};
		// rebun
        // PC_next = PC + 32'd4;
        // RegAddr = 5'd0;
        // RegData = 32'd0;
        // operand2 = 32'd0;

		// PCSource는 IF stage singal... 
		// CTRL 에서 바로 받아온 값으로 일단 PC_next 계산해두기
        case (id_PCSource)
            2'd0: PC_next = PC + 4; 
            2'd1: PC_next = branch_taken ? id_branch_target : (PC + 4); // for beq and bne
            2'd2: PC_next = id_jump_target; // for J and Jal ...; pc = target
            2'd3: PC_next = rd_data1; // only for JR...; JR rs -> pc = rs
			// rebun
            //default: PC_next = PC + 32'd4;
        endcase

		// RegDst 는 write_addr 결정해주는 signal
		// EX stage signal...
        case (IDEX_RegDst)
            2'd0: RegAddr = IDEX_RT; // for I-type.
            2'd1: RegAddr = IDEX_RD; // for R-type.
            2'd2: RegAddr = 5'd31; // only for JAL...; r31 = pc
			// rebun
            //default: RegAddr = 5'd0;
        endcase

		// MemtoReg 는 WB stage signal...
        case (MEMWB_MemtoReg)
            2'd0: RegData = MEMWB_Data; // e.g. lw r2 0x100
            2'd1: RegData = MEMWB_ALUResult; // e.g. R/I type ALU inst.
            2'd2: RegData = MEMWB_PC; // JAL inst 전용.
			// rebun
            //default: RegData = 32'd0;
        endcase

		// ALUSrc 는 EX stage signal...
        operand2 = IDEX_ALUSrc ? ext_imm : IDEX_Data2;
    end

    always @(posedge clk) begin
        if (rst) begin
            PC <= 32'd0;

            IFID_Valid <= 1'b0;
            IFID_PC <= 32'd0;
            IFID_Inst <= 32'd0;

            IDEX_Valid <= 1'b0;
            IDEX_Halt <= 1'b0;
            IDEX_RegWrite <= 1'b0;
            IDEX_MemtoReg <= 2'b00;
            IDEX_MemWrite <= 1'b0;
            IDEX_PCSource <= 2'b00;
            IDEX_SignExtend <= 1'b0;
            IDEX_ALUSrc <= 1'b0;
            IDEX_ALUOp <= 4'b0000;
            IDEX_RegDst <= 2'b00;
            IDEX_PC <= 32'd0;
            IDEX_Data1 <= 32'd0;
            IDEX_Data2 <= 32'd0;
            IDEX_IMMI <= 16'd0;
            IDEX_IMMJ <= 26'd0;
            IDEX_RT <= 5'd0;
            IDEX_RD <= 5'd0;
            IDEX_Shamt <= 5'd0;

            EXMEM_Valid <= 1'b0;
            EXMEM_Halt <= 1'b0;
            EXMEM_RegWrite <= 1'b0;
            EXMEM_MemtoReg <= 2'b00;
            EXMEM_MemWrite <= 1'b0;
            EXMEM_PC <= 32'd0;
            EXMEM_ALUResult <= 32'd0;
            EXMEM_Data <= 32'd0;
            EXMEM_RegAddr <= 5'd0;

            MEMWB_Valid <= 1'b0;
            MEMWB_Halt <= 1'b0;
            MEMWB_RegWrite <= 1'b0;
            MEMWB_MemtoReg <= 2'b00;
            MEMWB_PC <= 32'd0;
            MEMWB_Data <= 32'd0;
            MEMWB_ALUResult <= 32'd0;
            MEMWB_RegAddr <= 5'd0;

            stall_count <= 2'b00;
        end
        else begin
			// posedge clk -> 한 싸이클 지났으니 stall 업데이트. 
            if (stall_count != 2'b00) begin
                stall_count <= stall_count - 1;
            end
			// stall count 가 0이 아닌데, stall 값이 있다?
			// -> 더 긴 stall이 들어 와버렸다.
            else if (stall != 2'b00) begin
                stall_count <= stall - 1;
            end
			// rebun
            // else begin
            //     stall_count <= 2'b00;
            // end

            if (stall_active) begin
				// stall 상태면 -> IF 단계 그대로 유지 + Ex stage로 넘어가는 애들 nop 넣어주기.
                
				// 굳이 안싸줘도 되지만 명시적으로 적어주기.
				PC <= PC;
                IFID_Valid <= IFID_Valid;
                IFID_PC <= IFID_PC;
                IFID_Inst <= IFID_Inst;

                IDEX_Valid <= 1'b0;
                IDEX_Halt <= 1'b0;
                IDEX_RegWrite <= 1'b0;
                IDEX_MemtoReg <= 2'b00;
                IDEX_MemWrite <= 1'b0;
                IDEX_PCSource <= 2'b00;
                IDEX_SignExtend <= 1'b0;
                IDEX_ALUSrc <= 1'b0;
                IDEX_ALUOp <= 4'b0000;
                IDEX_RegDst <= 2'b00;
                IDEX_PC <= 32'd0;
                IDEX_Data1 <= 32'd0;
                IDEX_Data2 <= 32'd0;
                IDEX_IMMI <= 16'd0;
                IDEX_IMMJ <= 26'd0;
                IDEX_RT <= 5'd0;
                IDEX_RD <= 5'd0;
                IDEX_Shamt <= 5'd0;
            end
            else begin
                PC <= PC_next;
				// flush 면 이전 IF stage inst -> 즉 IFID latch에 있는 것들 없애주기.
                if (control_flush) begin
                    IFID_Valid <= 1'b0;
                    IFID_PC <= 32'd0;
                    IFID_Inst <= 32'd0;
                end
                else begin
                    IFID_Valid <= 1'b1;
                    IFID_PC <= PC + 4;
                    IFID_Inst <= inst;
                end

                IDEX_Valid <= id_valid_inst;
                IDEX_Halt <= id_halt;
                IDEX_RegWrite <= id_RegWrite;
                IDEX_MemtoReg <= id_MemtoReg;
                IDEX_MemWrite <= id_MemWrite;
                IDEX_PCSource <= id_PCSource;
                IDEX_SignExtend <= id_SignExtend;
                IDEX_ALUSrc <= id_ALUSrc;
                IDEX_ALUOp <= id_ALUOp;
                IDEX_RegDst <= id_RegDst;
                IDEX_PC <= IFID_PC;
                IDEX_Data1 <= rd_data1;
                IDEX_Data2 <= rd_data2;
                IDEX_IMMI <= immi;
                IDEX_IMMJ <= immj;
                IDEX_RT <= rt;
                IDEX_RD <= rd;
                IDEX_Shamt <= shamt;
            end

			// stall이 되는 기준 : decode 해보고 hazard 감지 -> 그 뒤에 있는 inst 들 정지
			// 즉 앞쪽 pipeline 내에 있는 것들은 그대로 가야함.
            EXMEM_Valid <= IDEX_Valid;
            EXMEM_Halt <= IDEX_Halt;
            EXMEM_RegWrite <= IDEX_RegWrite;
            EXMEM_MemtoReg <= IDEX_MemtoReg;
            EXMEM_MemWrite <= IDEX_MemWrite;
            EXMEM_PC <= IDEX_PC;
            EXMEM_ALUResult <= alu_result;
            EXMEM_Data <= IDEX_Data2;
            EXMEM_RegAddr <= RegAddr;

            MEMWB_Valid <= EXMEM_Valid;
            MEMWB_Halt <= EXMEM_Halt;
            MEMWB_RegWrite <= EXMEM_RegWrite;
            MEMWB_MemtoReg <= EXMEM_MemtoReg;
            MEMWB_PC <= EXMEM_PC;
            MEMWB_Data <= mem_read_data;
            MEMWB_ALUResult <= EXMEM_ALUResult;
            MEMWB_RegAddr <= EXMEM_RegAddr;
        end
    end

    HAZARD hazard(
        .valid(id_valid_inst && !id_halt),
        .opcode(opcode),
        .funct(funct),
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
        .RegWrite(ctrl_RegWrite),
        .MemtoReg(ctrl_MemtoReg),
        .MemWrite(ctrl_MemWrite),
        .PCSource(ctrl_PCSource),
        .SignExtend(ctrl_SignExtend),
        .ALUSrc(ctrl_ALUSrc),
        .ALUOp(ctrl_ALUOp),
        .RegDst(ctrl_RegDst)
    );

    RF rf (
        .clk(clk),
        .rst(rst),
        .rd_addr1(rd_addr1),
        .rd_addr2(rd_addr2),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2),
        .RegWrite(MEMWB_RegWrite),
        .wr_addr(MEMWB_RegAddr),
        .wr_data(RegData)
    );

    MEM mem (
        .clk(clk),
        .rst(rst),
        .inst_addr(inst_addr),
        .inst(inst),
        .mem_addr(EXMEM_ALUResult),
        .MemWrite(EXMEM_MemWrite),
        .mem_write_data(EXMEM_Data),
        .mem_read_data(mem_read_data)
    );

    ALU alu (
        .operand1(operand1),
        .operand2(operand2),
        .shamt(IDEX_Shamt),
        .funct(IDEX_ALUOp),
        .alu_result(alu_result)
    );
endmodule
