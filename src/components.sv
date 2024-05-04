`default_nettype none

module instr_shift_register(
  input logic rst, clk,
  input logic data_ready,
  input logic[7:0] serial_in,
  output logic[15:0] instruction, //to compensate for double word
  output logic[15:0] imm,
  output logic valid, error,
  output logic halt
);

  logic[4:0] count;

  opcode_t opcode;

  assign error = 1'b0;
  assign valid = ((opcode != M_TYPE & opcode != I_TYPE) & count == 2) | ((opcode == M_TYPE | opcode == I_TYPE) & count == 4);

  assign opcode = instruction[2:0];


  assign halt = (opcode == SYS_END & valid);
  
  // assign error =  (opcode != R_TYPE) & 
  //                 (opcode != I_TYPE) & 
  //                 (opcode != B_TYPE) & 
  //                 (opcode != J_TYPE) & 
  //                 (opcode != M_TYPE) & 
  //                 (opcode != SYS_END) & count >= 2;

  always_ff @(posedge clk) begin
    if(rst) begin
      instruction <= 'd0;
      count <= 'd0;
      imm <= 'd0;
    end else begin
      if(data_ready) begin
        count <= count + 1;
        if(count >= 2) begin
          if(opcode == M_TYPE | opcode == I_TYPE & count < 4) begin
            imm <= {serial_in, imm[15:8]};
            count <= count + 1;
          end
        end else begin
          instruction <= {serial_in, instruction[15:8]};
        end
      end else count <= 'd0;
    end
  end
endmodule

module pc_shift_reg(
  input logic load, rst, clk,
  input logic shift_out,
  input logic[15:0] prll_in,
  output logic[15:0] prll_out,
  output logic[7:0] serial_out,
  output logic error
);

  logic low_b;

  assign serial_out = low_b ? prll_out[7:0] : prll_out[15:8];

  always_ff @(posedge clk) begin
    if(rst) begin
      prll_out <= 'd0;
      error <= 1'b0;
      low_b <= 1'b1;
    end else begin
      if(load) begin
        prll_out <= prll_in;
      end else if(shift_out) begin
        low_b <= ~low_b;
      end else begin
        prll_out <= prll_out;
      end
    end
  end

endmodule

module eight_bit_spispo(
  input logic load, rst, clk,
  input logic shift_out, shift_in,
  input logic[7:0] serial_in,
  input logic[15:0] prll_in,
  output logic[15:0] prll_out,
  output logic[7:0] serial_out,
  output logic error
);

  logic low_b;

  assign error = (shift_out & shift_in) | (load & shift_in) | (load & shift_out);

  assign serial_out = low_b ? prll_out[7:0] : prll_out[15:8];

  always_ff @(posedge clk) begin
    if(rst) begin
      prll_out <= 'd0;
      low_b <= 1'b1;
    end else begin
      if(load) begin
        prll_out <= prll_in;
      end else if(shift_in) begin
        prll_out <= {prll_out[7:0], serial_in};
      end else if(shift_out) begin
        low_b <= ~low_b;
      end else begin
        prll_out <= prll_out;
      end
    end
  end

endmodule