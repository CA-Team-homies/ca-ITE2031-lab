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
    
    // BTB가 뭐라고 예측했는지,,,
    reg        IFID_PredTaken;
    reg [31:0] IFID_PredTarget;

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
    // forwarding 내부 구현을 위해서 이제 RS도 어떤 reg인지 파악해야함.
    reg [4:0]  IDEX_RS;

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
    // 그레서 WB 할 값이 뭔지를 저장... Forwarding을 해주어야하기 때문에, 해당로직 전에 미리 계산해두기.
    wire [31:0] MEMWB_Result;

    // 내부에서 사용할 reg 들...
    reg [31:0] PC_next;
    reg [31:0] ext_imm;
    reg [4:0]  RegAddr;
    reg [31:0] RegData;
    reg [31:0] operand2;
    reg [1:0]  stall_count;

    // Forward 모듈로 분리
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;

    // branch early resolution의 유일한 단점...
    // forwarding logic에 편승이 안되어서 직접 해주어야한다 -> 변수 만들어주기
    reg [31:0] branch_data1;
    reg [31:0] branch_data2;


    // Split the instructions
    // Instruction-related wires
    // ID stage 분리시켜서 사용할 wire들.
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

    // wire [31:0] operand1;
    // 기존엔 operand1 = IDEX_Data1 으로 처리했으나, 현재는 forwarding 내부 구현을 해보자...
    // operand2 는 R이냐 I냐에 따라 다르니, forwarding data 변수를 만들어서 그걸 기존 변수에 넣어주는 걸로
    wire [31:0] operand1_fwd;
    wire [31:0] alu_result;
    wire [31:0] data2_fwd;


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

    // BP에 연결해주어서, 실제로 사용할 wire들; BP에서 알아서 연산해서 주었을 것이니 그냥 사용하면 될듯
    wire bp_pred_taken;
    wire [31:0] bp_pred_target;

    // JR 인 경우 생각을 또 해주어야한다...
    // 실제 target address, 혹은 내가 잘못 예측했니?
    wire [31:0] actual_target;
    wire jr_inst;
    wire mispredict;

    // IF/ID field split
    assign opcode = IFID_Inst[31:26];
    assign rs     = IFID_Inst[25:21];
    assign rt     = IFID_Inst[20:16];
    assign rd     = IFID_Inst[15:11];
    assign shamt  = IFID_Inst[10:6];
    assign funct  = IFID_Inst[5:0];
    assign immi   = IFID_Inst[15:0];
    assign immj   = IFID_Inst[25:0];

    assign rd_addr1  = rs;
    assign rd_addr2  = rt;
    assign inst_addr = PC;

    // lw -> data , 보통은 ALU op -> ALUResult, JR의 경우도 있긴하다;
    assign MEMWB_Result =
        (MEMWB_MemtoReg == 2'd0) ? MEMWB_Data      :
        (MEMWB_MemtoReg == 2'd1) ? MEMWB_ALUResult : MEMWB_PC;

    // 뭘 WB 해줄지 이제 정했으니까, forwarding 여부에 따라서 값을 넣어주기/.
    assign operand1_fwd =
        (ForwardA == 2'b01) ? EXMEM_ALUResult :
        (ForwardA == 2'b10) ? MEMWB_Result    : IDEX_Data1;

    // 경우에 따라서 현재 Ex중인게 R인 경우 -> ALUResult, sw 면 MEMWB_Result.
    assign data2_fwd =
        (ForwardB == 2'b01) ? EXMEM_ALUResult :
        (ForwardB == 2'b10) ? MEMWB_Result    : IDEX_Data2;

    // ID stage에서 decode중인 inst가 nop인지, halt inst는 아닌지 확인해야함.
    assign id_valid_inst = IFID_Valid;
    assign id_halt       = id_valid_inst && (IFID_Inst == 32'b0);

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
    // 이제 branch data 를 따로 만들어주었으니 이걸로 비교
    assign branch_taken =
        id_valid_inst && !id_halt &&
        (((opcode == `OP_BEQ) && (branch_data1 == branch_data2)) ||
         ((opcode == `OP_BNE) && (branch_data1 != branch_data2)));

    // branch target 과 jump target 값 일단 만들어 두기.
    assign id_branch_target = IFID_PC + {{14{immi[15]}}, immi, 2'b00};
    assign id_jump_target   = {IFID_PC[31:28], immj, 2'b00};

    // c.f. PCSource -> 1이면 branch, 2면 J나 Jal, 3이면 Jr
    assign control_taken =
        id_valid_inst && !id_halt &&
        ((id_PCSource == 2'd2) ||
         (id_PCSource == 2'd3) ||
         ((id_PCSource == 2'd1) && branch_taken));

    // 현재 ID stage에서 stall 인가?
    assign stall_active = (stall_count != 2'b00) || (stall != 2'b00);

    // ID stage에서, 실제로 어디로 가야할지...?
    // if 문 못쓰니까 ㄹㅈㄷ...
    // JR이세요? + J/Jal 이세요? + branch였는데 taken이세요? 다 아니면 그냥 PC + 4...
    assign actual_target =
        (id_PCSource == 2'd3) ? rd_data1        : 
        (id_PCSource == 2'd2) ? id_jump_target   :
        branch_taken          ? id_branch_target : IFID_PC;

    // control inst 였는데,
    // NT != T, T != NT 면 당연히 mis pred. but... T = T 인데, Tag miss로 안맞을수도 있구나;;
    assign mispredict =
        id_valid_inst && !id_halt && !stall_active &&
        (id_PCSource != 2'd0) &&
        ((IFID_PredTaken != control_taken) ||
         (IFID_PredTaken && control_taken && (IFID_PredTarget != actual_target)));

    // JR인 경우에만 id_PCSource가 3.
    assign jr_inst = id_valid_inst && !id_halt && (id_PCSource == 2'd3);

    // assign control_flush = control_taken && !stall_active;
    // 이제 예측이 생겼기 때문에, stall 상태가 아니고, 잘못 예측했거나 JR이었을 경우에 flush 해주어야함.
    assign control_flush = !stall_active && (mispredict || jr_inst);

    //assign halt = (IFID_Inst == 32'b0);
    // 뒤쪽 pipeline에 아직 명령어가 돌고 있을 수도 있다...
    assign halt = MEMWB_Valid && MEMWB_Halt;

    always @(*) begin
        // branch early resolution side effect !!!
        // lw 직후의 branch -> 2 cycle stall.
        // lw 이후와 그 다음의 branch -> 1 cycle stall.
        // 그 외의 inst 직후의 branch -> 1 cycle stall.
        if (EXMEM_RegWrite && (EXMEM_RegAddr == rs)) branch_data1 = EXMEM_ALUResult;
        else if (MEMWB_RegWrite && (MEMWB_RegAddr == rs)) branch_data1 = MEMWB_Result;
        else branch_data1 = rd_data1;  // 그 외라면 기존 처럼 rd_data1 사용하기.

        if (EXMEM_RegWrite && (EXMEM_RegAddr == rt)) branch_data2 = EXMEM_ALUResult;
        else if (MEMWB_RegWrite && (MEMWB_RegAddr == rt)) branch_data2 = MEMWB_Result;
        else branch_data2 = rd_data2;
        
        // SignExtend -> EX stage 에서 사용할 operand에 쓰일 extend 종류 결정
        // -> Ex stage signal...
        ext_imm = IDEX_SignExtend ? {{16{IDEX_IMMI[15]}}, IDEX_IMMI}
                                  : {16'b0, IDEX_IMMI};
        
        // JR 혹은 예측이 틀렸을 경우, 미리 원래대로 돌려두어야한다..
        if (control_flush) begin
            case (id_PCSource)
                2'd0: PC_next = PC + 4; 
                2'd1: PC_next = branch_taken ? id_branch_target : (PC + 4); // for beq and bne
                2'd2: PC_next = id_jump_target; // for J and Jal ...; pc = target
                2'd3: PC_next = rd_data1; // only for JR...; JR rs -> pc = rs
            endcase
        end
        else begin
            PC_next = bp_pred_taken ? bp_pred_target : (PC + 4);
        end

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

        // // ALUSrc 는 EX stage signal...
        // operand2 = IDEX_ALUSrc ? ext_imm : IDEX_Data2;
        // 이제 forwarding 적용되었으므로, latch 값이 아니라 fwd 값 사용.
        operand2 = IDEX_ALUSrc ? ext_imm : data2_fwd;
    end

    always @(posedge clk) begin
        if (rst) begin
            PC <= 32'd0;

            IFID_Valid      <= 1'b0;
            IFID_PC         <= 32'd0;
            IFID_Inst       <= 32'd0;
            // [LAB6 추가] 리셋 시 BP 예측 필드도 초기화
            IFID_PredTaken  <= 1'b0;
            IFID_PredTarget <= 32'd0;

            IDEX_Valid      <= 1'b0;
            IDEX_Halt       <= 1'b0;
            IDEX_RegWrite   <= 1'b0;
            IDEX_MemtoReg   <= 2'b00;
            IDEX_MemWrite   <= 1'b0;
            IDEX_PCSource   <= 2'b00;
            IDEX_SignExtend <= 1'b0;
            IDEX_ALUSrc     <= 1'b0;
            IDEX_ALUOp      <= 4'b0000;
            IDEX_RegDst     <= 2'b00;
            IDEX_PC         <= 32'd0;
            IDEX_Data1      <= 32'd0;
            IDEX_Data2      <= 32'd0;
            IDEX_IMMI       <= 16'd0;
            IDEX_IMMJ       <= 26'd0;
            IDEX_RT         <= 5'd0;
            IDEX_RD         <= 5'd0;
            // [LAB6 추가]
            IDEX_RS         <= 5'd0;
            IDEX_Shamt      <= 5'd0;

            EXMEM_Valid     <= 1'b0;
            EXMEM_Halt      <= 1'b0;
            EXMEM_RegWrite  <= 1'b0;
            EXMEM_MemtoReg  <= 2'b00;
            EXMEM_MemWrite  <= 1'b0;
            EXMEM_PC        <= 32'd0;
            EXMEM_ALUResult <= 32'd0;
            EXMEM_Data      <= 32'd0;
            EXMEM_RegAddr   <= 5'd0;

            MEMWB_Valid     <= 1'b0;
            MEMWB_Halt      <= 1'b0;
            MEMWB_RegWrite  <= 1'b0;
            MEMWB_MemtoReg  <= 2'b00;
            MEMWB_PC        <= 32'd0;
            MEMWB_Data      <= 32'd0;
            MEMWB_ALUResult <= 32'd0;
            MEMWB_RegAddr   <= 5'd0;

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

            if (stall_active) begin
                // stall 상태면 -> IF 단계 그대로 유지 + ID/EX로 넘어가는 애들 nop 넣어주기.

                // 굳이 안써도 되지만 명시적으로 적어주기.
                PC              <= PC;
                IFID_Valid      <= IFID_Valid;
                IFID_PC         <= IFID_PC;
                IFID_Inst       <= IFID_Inst;
                IFID_PredTaken  <= IFID_PredTaken;
                IFID_PredTarget <= IFID_PredTarget;

                IDEX_Valid      <= 1'b0;
                IDEX_Halt       <= 1'b0;
                IDEX_RegWrite   <= 1'b0;
                IDEX_MemtoReg   <= 2'b00;
                IDEX_MemWrite   <= 1'b0;
                IDEX_PCSource   <= 2'b00;
                IDEX_SignExtend <= 1'b0;
                IDEX_ALUSrc     <= 1'b0;
                IDEX_ALUOp      <= 4'b0000;
                IDEX_RegDst     <= 2'b00;
                IDEX_PC         <= 32'd0;
                IDEX_Data1      <= 32'd0;
                IDEX_Data2      <= 32'd0;
                IDEX_IMMI       <= 16'd0;
                IDEX_IMMJ       <= 26'd0;
                IDEX_RT         <= 5'd0;
                IDEX_RD         <= 5'd0;
                IDEX_RS         <= 5'd0;
                IDEX_Shamt      <= 5'd0;
            end
            else begin
                PC <= PC_next;

                // flush 면 이전 IF stage inst -> 즉 IFID latch에 있는 것들 없애주기.
                if (control_flush) begin
                    IFID_Valid      <= 1'b0;
                    IFID_PC         <= 32'd0;
                    IFID_Inst       <= 32'd0;
                    IFID_PredTaken  <= 1'b0;
                    IFID_PredTarget <= 32'd0;
                end
                else begin
                    IFID_Valid      <= 1'b1;
                    IFID_PC         <= PC + 4;
                    IFID_Inst       <= inst;
                    // ㄹㅇ inst... -> 해당 inst에 대해서 BP가 예측하는 값 받아오기.
                    IFID_PredTaken  <= bp_pred_taken;
                    IFID_PredTarget <= bp_pred_target;
                end

                IDEX_Valid      <= id_valid_inst;
                IDEX_Halt       <= id_halt;
                IDEX_RegWrite   <= id_RegWrite;
                IDEX_MemtoReg   <= id_MemtoReg;
                IDEX_MemWrite   <= id_MemWrite;
                IDEX_PCSource   <= id_PCSource;
                IDEX_SignExtend <= id_SignExtend;
                IDEX_ALUSrc     <= id_ALUSrc;
                IDEX_ALUOp      <= id_ALUOp;
                IDEX_RegDst     <= id_RegDst;
                IDEX_PC         <= IFID_PC;
                // branch early resolution 때문에, branch_data를 따로 만들어두었었다.
                // 그런데 여기에 forwarding이 되어있을 수도 있다...
                // 왜 why... >> ID stage << 에서 branch를 계산하고 싶어서 미리 forwarding 받아온것...
                IDEX_Data1      <= branch_data1;
                IDEX_Data2      <= rd_data2;
                IDEX_IMMI       <= immi;
                IDEX_IMMJ       <= immj;
                IDEX_RT         <= rt;
                IDEX_RD         <= rd;
                IDEX_RS         <= rs;
                IDEX_Shamt      <= shamt;
            end

            // stall이 되는 기준 : decode 해보고 hazard 감지 -> 그 뒤에 있는 inst 들 정지
            // 즉 앞쪽 pipeline 내에 있는 것들은 그대로 가야함.
            EXMEM_Valid     <= IDEX_Valid;
            EXMEM_Halt      <= IDEX_Halt;
            EXMEM_RegWrite  <= IDEX_RegWrite;
            EXMEM_MemtoReg  <= IDEX_MemtoReg;
            EXMEM_MemWrite  <= IDEX_MemWrite;
            EXMEM_PC        <= IDEX_PC;
            EXMEM_ALUResult <= alu_result;
            // forwarding...
            EXMEM_Data      <= data2_fwd;
            EXMEM_RegAddr   <= RegAddr;

            MEMWB_Valid     <= EXMEM_Valid;
            MEMWB_Halt      <= EXMEM_Halt;
            MEMWB_RegWrite  <= EXMEM_RegWrite;
            MEMWB_MemtoReg  <= EXMEM_MemtoReg;
            MEMWB_PC        <= EXMEM_PC;
            MEMWB_Data      <= mem_read_data;
            MEMWB_ALUResult <= EXMEM_ALUResult;
            MEMWB_RegAddr   <= EXMEM_RegAddr;
        end
    end

    // [LAB5 원본 HAZARD 인스턴스]
    // HAZARD hazard(
    //     .valid(id_valid_inst && !id_halt),
    //     .opcode(opcode),
    //     .funct(funct),
    //     .rs(rs),
    //     .rt(rt),
    //     .dest_EX(RegAddr),
    //     .dest_MEM(EXMEM_RegAddr),
    //     .dest_WB(MEMWB_RegAddr),       // [제거] internal forwarding으로 dist=3 stall 불필요
    //     .RegWrite_EX(IDEX_RegWrite),
    //     .RegWrite_MEM(EXMEM_RegWrite),
    //     .RegWrite_WB(MEMWB_RegWrite),   // [제거]
    //     .stall(stall)
    // );
    //
    // [LAB6 변경] dest_WB/RegWrite_WB 제거, MemtoReg_EX/MEM 추가 (LW 판별용)
    FORWARD forward (
        .IDEX_RS      (IDEX_RS),
        .IDEX_RT      (IDEX_RT),
        .EXMEM_RegWrite(EXMEM_RegWrite),
        .EXMEM_RegAddr (EXMEM_RegAddr),
        .MEMWB_RegWrite(MEMWB_RegWrite),
        .MEMWB_RegAddr (MEMWB_RegAddr),
        .ForwardA      (ForwardA),
        .ForwardB      (ForwardB)
    );

    HAZARD hazard (
        .valid        (id_valid_inst && !id_halt),
        .opcode       (opcode),
        .funct        (funct),
        .rs           (rs),
        .rt           (rt),
        .dest_EX      (RegAddr),
        .RegWrite_EX  (IDEX_RegWrite),
        .MemtoReg_EX  (IDEX_MemtoReg),
        .dest_MEM     (EXMEM_RegAddr),
        .RegWrite_MEM (EXMEM_RegWrite),
        .MemtoReg_MEM (EXMEM_MemtoReg),
        .stall        (stall)
    );

    CTRL ctrl (
        .opcode    (opcode),
        .funct     (funct),
        .RegWrite  (ctrl_RegWrite),
        .MemtoReg  (ctrl_MemtoReg),
        .MemWrite  (ctrl_MemWrite),
        .PCSource  (ctrl_PCSource),
        .SignExtend(ctrl_SignExtend),
        .ALUSrc    (ctrl_ALUSrc),
        .ALUOp     (ctrl_ALUOp),
        .RegDst    (ctrl_RegDst)
    );

    RF rf (
        .clk      (clk),
        .rst      (rst),
        .rd_addr1 (rd_addr1),
        .rd_addr2 (rd_addr2),
        .rd_data1 (rd_data1),
        .rd_data2 (rd_data2),
        .RegWrite (MEMWB_RegWrite),
        .wr_addr  (MEMWB_RegAddr),
        .wr_data  (RegData)
    );

    MEM mem (
        .clk           (clk),
        .rst           (rst),
        .inst_addr     (inst_addr),
        .inst          (inst),
        .mem_addr      (EXMEM_ALUResult),
        .MemWrite      (EXMEM_MemWrite),
        .mem_write_data(EXMEM_Data),
        .mem_read_data (mem_read_data)
    );

    // [LAB5] ALU alu (.operand1(operand1), ...)
    // [LAB6 변경] operand1 → operand1_fwd (ForwardA 인라인 로직 반영)
    //             operand2 → operand2 (data2_fwd 기반으로 always 블록에서 계산)
    ALU alu (
        .operand1  (operand1_fwd),
        .operand2  (operand2),
        .shamt     (IDEX_Shamt),
        .funct     (IDEX_ALUOp),
        .alu_result(alu_result)
    );

    // [LAB6 추가] BP 인스턴스
    // Lab5에는 없던 모듈. IF stage에서 BTB/PHT lookup, ID stage에서 update.
    BP bp (
        .clk          (clk),
        .rst          (rst),
        .if_pc        (PC),
        .pred_taken   (bp_pred_taken),
        .pred_target  (bp_pred_target),
        .update_en    (id_valid_inst && !id_halt && !stall_active &&
                       (id_PCSource == 2'd1 || id_PCSource == 2'd2)),
        .update_pc    (IFID_PC - 4),
        .update_type  (id_PCSource == 2'd2),  // 0=branch, 1=jump
        .update_taken (control_taken),
        .update_target(
            (id_PCSource == 2'd2) ? id_jump_target   :
            branch_taken          ? id_branch_target  :
                                    IFID_PC
        )
    );

endmodule