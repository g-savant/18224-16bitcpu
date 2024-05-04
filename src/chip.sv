`default_nettype none

// `include "types.vh"
// `include "reg_file.sv"
// `include "alu.sv"
// `include "control.sv"
// `include "components.sv"
// `include "decode.sv"

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);

    // Basic counter design as an example

    cpu_core cpu(       .clk(clock),
                        .rst(reset),
                        .ard_clk(io_in[10]),
                        .ard_data_ready(io_in[9]),
                        .ard_receive_ready(io_in[8]),
                        .in_bus(io_in[7:0]),
                        .out_bus(io_out[7:0]),
                        .bus_pc(io_out[8]),
                        .bus_mar(io_out[9]),
                        .bus_mdr(io_out[10]),
                        .halt(io_out[11]));

endmodule
