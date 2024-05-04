`default_nettype none


//enabling forwarding
module reg_file(
  input logic rst, clk, rd_we,
  input logic[2:0] rs1, rs2, rd,
  input logic[15:0] rd_data,
  output logic[15:0] rs1_data, rs2_data
);

logic[15:0] reg_file[7:1];

always_comb begin
  if(rs1 == 0) rs1_data = 16'd0;
  else rs1_data = reg_file[rs1];

  if(rs2 == 0) rs2_data = 16'd0;
  else rs2_data = reg_file[rs2];

  //forwarding
  if(rd == rs1 & rs1 != 0) rs1_data = rd_data;
  if(rd == rs2 & rs2 != 0) rs2_data = rd_data;
end

always_ff @(posedge clk) begin
  if(rst) begin
    for(int i = 1; i < 8; i++) begin
      reg_file[i] <= 16'd0;
    end
  end else begin
    if(rd_we) reg_file[rd] <= rd_data;
  end
end



endmodule