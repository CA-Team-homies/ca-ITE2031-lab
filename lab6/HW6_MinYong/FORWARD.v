`timescale 1ns / 1ps
`include "GLOBAL.v"

// ===== [LAB6 신규 모듈] =====
// Lab5에는 존재하지 않던 모듈. EX stage ALU 입력에 대한 forwarding 선택 신호를 생성.
//
// [배경]
// Lab5에서는 forwarding이 없으므로, 이전 inst의 결과가 WB에서 RF에 쓰일 때까지
// STALL1/2/3으로 기다렸다. Lab6에서는 pipeline latch(EXMEM, MEMWB)에서 직접
// ALU 입력으로 데이터를 bypass함으로써 stall을 제거한다.
//
// ForwardA: operand1(rs) 선택
// ForwardB: operand2(rt) 선택  ← ALU용 + SW store data에도 사용
//   2'b00: 기존 RF 값 사용 (IDEX_Data1 / IDEX_Data2)
//   2'b01: EX/MEM forwarding → EXMEM_ALUResult (dist=1, R/I-type)
//   2'b10: MEM/WB forwarding → MEMWB result (dist=2)
//
// 우선순위: EX/MEM > MEM/WB
//   (같은 레지스터에 두 latch 모두 pending이면 더 최신 값인 EX/MEM을 우선)

module FORWARD (
    input  [4:0]  IDEX_RS,
    input  [4:0]  IDEX_RT,

    input         EXMEM_RegWrite,
    input  [4:0]  EXMEM_RegAddr,

    input         MEMWB_RegWrite,
    input  [4:0]  MEMWB_RegAddr,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

    always @(*) begin
        // ForwardA: operand1 (rs)
        if (EXMEM_RegWrite && (EXMEM_RegAddr != 5'd0) && (EXMEM_RegAddr == IDEX_RS))
            ForwardA = 2'b01; // EX/MEM forwarding (우선)
        else if (MEMWB_RegWrite && (MEMWB_RegAddr != 5'd0) && (MEMWB_RegAddr == IDEX_RS))
            ForwardA = 2'b10; // MEM/WB forwarding
        else
            ForwardA = 2'b00; // forwarding 없음
    end

    always @(*) begin
        // ForwardB: operand2 (rt)
        if (EXMEM_RegWrite && (EXMEM_RegAddr != 5'd0) && (EXMEM_RegAddr == IDEX_RT))
            ForwardB = 2'b01;
        else if (MEMWB_RegWrite && (MEMWB_RegAddr != 5'd0) && (MEMWB_RegAddr == IDEX_RT))
            ForwardB = 2'b10;
        else
            ForwardB = 2'b00;
    end

endmodule
