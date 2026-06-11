`timescale 1ns / 100ps

module RF (
	// You may also change the input and output ports (maybe changing reg to wire)
		input clk,
		input rst,
		// Read-related ports
		input [4:0] rd_addr1,
		input [4:0] rd_addr2,
		// >>>>> should we change the reg output to wire output ?? <<<<<
		output reg [31:0] rd_data1,
		output reg [31:0] rd_data2,
		// Write-related ports
		input RegWrite,
		input [4:0] wr_addr,
		input [31:0] wr_data
	);

    reg [31:0] register_file [0:31];

	
	// Fill in the asynchronous functions
	// async 
	// -> when read address's changes 
	// -> read the data in register file.

    // * <-> rd_addr1, rd_addr2 ...
    // 기존 single/multi cycle 에서는 한 싸이클 안에 RF read(async) 와 RF write(sync)가 같이
    // 일어날 일이 없었어서 rd_addr1, rd_addr2로 해주어도 큰 문제가 없었음. 
    // But 지금은 한 싸이클 이내에 일어날 수 있어서 *로 해주어야함.
    // 즉 예를 들어 WB 이후 ID 가 필요한 상황; forwarding 이 있었다면 internal forwarding인 상황 같은 경우 큰 문제가 생긴다.
	always @(*) begin
		if (RegWrite && (wr_addr == rd_addr1)) rd_data1 = wr_data;
		else rd_data1 = register_file[rd_addr1];

		if (RegWrite && (wr_addr == rd_addr2)) rd_data2 = wr_data;
		else rd_data2 = register_file[rd_addr2];
	end
	// there are no wires to connect.
	//assign ??
    
	always @(posedge clk) begin
		if (rst) begin
			$readmemh("initial_reg1.mem", register_file);
		end
		// Since we use reg array variable : register_file as storage.
		// -> non-blocking : "<=" should be used. 
		if(RegWrite) begin
			register_file[wr_addr] <= wr_data;
		end
		// FILL what happens synchronously
	end

endmodule
