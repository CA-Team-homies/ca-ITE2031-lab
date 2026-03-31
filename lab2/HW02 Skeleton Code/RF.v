`timescale 1ns / 100ps

module RF (
	// You may also change the input and output ports (maybe changing reg to wire)
		input clk,
		input rst,
		// Read-related ports
		input [4:0] rd_addr1,
		input [4:0] rd_addr2,
		output reg [31:0] rd_data1,
		output reg [31:0] rd_data2,
		// Write-related ports
		input RegWrite,
		input [4:0] wr_addr,
		input [31:0] wr_data
	);

    reg [31:0] register_file [0:31];

	
	// Fill in the asynchronous functions
	always @(*) begin
		??
	end
	assign ??
    
	always @(posedge clk) begin
		if (rst) begin
			$readmemh("initial_reg.mem", register_file);
		end
		// FILL what happens synchronously
	end

endmodule
