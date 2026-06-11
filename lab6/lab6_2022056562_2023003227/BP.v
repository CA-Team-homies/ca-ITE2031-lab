`timescale 1ns / 1ps
`include "GLOBAL.v"

module BP (
    input clk,
    input rst,

    input [31:0] pc,
    // NT -> 0, T -> 1
    output pred_taken,
    // T라면 실제 값
    output [31:0] pred_target,

    // ID stage: branch/jump resolve 후 업데이트
    // branch inst가 resolve되었을 때, 그 결과
    input update_en,
    // control inst의 PC 값.
    input [31:0] update_pc,
    // 단순 jump와 branch를 구분... jump 라면 1
    input update_type,
    // 실제로 PC가 PC+4가 아니었니? -> jump는 항상 1로 처리
    input update_taken,
    input [31:0] update_target
);
    // 2bit를 저장해두어야한다... valid bit ~ Jump or Branch... 
    reg btb_valid [0:63];
    reg btb_type [0:63];
    reg [23:0] btb_tag [0:63];
    reg [31:0] btb_target [0:63];

    // 2-bit saturation counter! 
    reg [1:0] pht [0:255];

    // 
    wire btb_hit;
    // PC를 분해시킬 것.
    wire [5:0] idx;
    wire [23:0] tag ;
    wire [7:0] pht_idx;
    // 실제로 어떻게 되었는지.. 즉 update_enable이 들어왔을 때 update 시켜줘야함.
    wire [5:0] upd_idx;
    wire [23:0] upd_tag;
    wire [7:0] upd_pht_idx;

    // pc 분해하기.
    assign idx = pc[7:2];
    assign tag = pc[31:8];
    assign pht_idx = pc[9:2];

    assign upd_idx = update_pc[7:2];
    assign upd_tag = update_pc[31:8];
    assign  upd_pht_idx = update_pc[9:2];

    // BTB hit -> valid이고 tag 일치
    assign btb_hit = btb_valid[idx] && (btb_tag[idx] == tag);
    // branch 였을 때, T라고 예측? -> 10, 11.
    assign pht_taken = pht[pht_idx][1];
    // Jump일때는 그냥 1로 구현... 어짜피 PC가 훅 바뀌는게맞다.
    assign pred_taken = btb_hit && (btb_type[idx] ? 1 : pht_taken);
    assign pred_target = btb_hit ? btb_target[idx] : 32'b0;

    // initializer... CPU_tb 처럼
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1) begin
                btb_valid[i] <= 1'b0;
                btb_type[i] <= 1'b0;
                btb_tag[i] <= 24'b0;
                btb_target[i] <= 32'b0;
            end
            for (i = 0; i < 256; i = i + 1) begin
                pht[i] <= 2'b01; // 초기값: weakly NT -> 1
            end
        end
        if (update_en) begin
            // update 해야하면...
            btb_valid[upd_idx] <= 1'b1;
            btb_type[upd_idx] <= update_type;
            btb_tag[upd_idx] <= upd_tag;
            btb_target[upd_idx] <= update_target;
            if (update_taken) if (pht[upd_pht_idx] != 2'b11) pht[upd_pht_idx] <= pht[upd_pht_idx] + 2'b01;
            else if (pht[upd_pht_idx] != 2'b00) pht[upd_pht_idx] <= pht[upd_pht_idx] - 2'b01;
        end
    end
endmodule
