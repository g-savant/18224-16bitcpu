`include "core.sv"

module test();

  logic clk, rst;
  logic ard_clk;
  logic ard_data_ready;
  logic ard_receive_ready;
  logic[7:0] in_bus;
  logic[7:0] out_bus;
  logic bus_pc, bus_mar, bus_mdr, halt;

  logic[15:0][15:0] instr_memory;

  logic[15:0][15:0] data_memory;
  logic[15:0] pc, store_address, load_data;
  logic signed [15:0] result;
  logic[15:0] pc, address;
 
  cpu_core cpu(.*);


  assign ard_clk = clk;

  initial begin
    clk = 1'b0;
    forever #200 clk = ~clk;
  end

  task run_code();
    rst <= 1'b0;
    ard_receive_ready <= 1'b0;
    ard_data_ready <= 1'b0;
    data_memory <= 'd0;
    pc <= 'd0;
    in_bus <= 'd0;
    @(posedge clk);
    rst <= 1'b1;
    @(posedge clk);
    rst <= 1'b0;
    ard_receive_ready <= 1'b1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    while(~halt) begin
      if(bus_pc) begin
        pc <= {out_bus, pc[15:8]};
        @(posedge clk);
        pc <= {out_bus, pc[15:8]};
        @(posedge clk);
        ard_receive_ready <= 1'b0;
        ard_data_ready <= 1'b1;
        in_bus <= instr_memory[pc][7:0];
        @(posedge clk);
        ard_data_ready <= 1'b1;
        in_bus <= instr_memory[pc][15:8];
        @(posedge clk);
        if(instr_memory[pc][3:0] == I_TYPE || instr_memory[pc][3:0] == M_TYPE) begin
          ard_data_ready <= 1'b1;
          in_bus <= instr_memory[pc+1][7:0];
          @(posedge clk);
          ard_data_ready <= 1'b1;
          in_bus <= instr_memory[pc+1][15:8];
          @(posedge clk);
          ard_data_ready <= 1'b0;
        end else begin
          ard_data_ready <= 1'b0;
        end
        ard_receive_ready <= 1'b1;
        @(posedge clk);
      end else if(bus_mar) begin
        address <= {out_bus, address[15:8]};
        @(posedge clk);
        address <= {out_bus, address[15:8]};
        @(posedge clk);
        if(~bus_mdr) begin
          ard_receive_ready <= 1'b0;
          ard_data_ready <= 1'b1;
          in_bus <= data_memory[address][7:0];
          @(posedge clk);
          ard_data_ready <= 1'b1;
          in_bus <= data_memory[address][15:8];
          @(posedge clk);
          ard_data_ready <= 1'b0;
          ard_receive_ready <= 1'b1;
          @(posedge clk);
        end else begin
          load_data <= {out_bus, load_data[15:8]};
          @(posedge clk);
          load_data <= {out_bus, load_data[15:8]};
          @(posedge clk);
          data_memory[address] <= load_data;
          ard_receive_ready <= 1'b1;
          ard_data_ready <= 1'b0;
          @(posedge clk);
        end
      end else begin
        @(posedge clk);
      end
    end
  endtask


  initial begin
    logic[15:0] addr, a, b;
    addr = 16'd4;
    a = 16'd5;
    b = 16'd6;
    result = a - b;
    instr_memory[0] = {SUB, 3'd1, 3'd0, 3'd0, I_TYPE};
    instr_memory[1] = a;
    instr_memory[2] = {SUB, 3'd2 , 3'd0, 3'd0, I_TYPE};
    instr_memory[3] = b;
    instr_memory[4] = {SUB, 3'd3, 3'd1 , 3'd2, R_TYPE};
    instr_memory[5] = {SW, 3'b100, 3'd3, 3'd0, M_TYPE};
    instr_memory[6] = addr;
    instr_memory[7] = {LW, 3'b010, 3'd0, 3'd0, M_TYPE};
    instr_memory[8] = addr;
    instr_memory[9] = {13'd0, SYS_END};

    run_code();

    assert(data_memory[address] == result) begin
      $display("Data memory accurate");
    end 
    else begin
      $error ("Failed assertion! Memory at address %h should be %b but is %b", addr, result, $signed(data_memory[address]));
    end 

    assert(cpu.rf.reg_file[2] == result) begin
       $display("Register 2 accurate");
    end 
    else begin
      $error ("Failed assertion! Register 2 should be %d but is %d", result, cpu.rf.reg_file[2]);
    end

    $display("Subtract and Memory OP Test Case Passed!! Memory at address %h was %d, which is %d - %d.", addr, $signed(data_memory[address]), a, b);    

    result = a + b;

    instr_memory[0] = {ADD, 3'd1, 3'd0, 3'd0, I_TYPE};
    instr_memory[1] = a;
    instr_memory[2] = {ADD, 3'd2 , 3'd0, 3'd0, I_TYPE};
    instr_memory[3] = b;
    instr_memory[4] = {ADD, 3'd3, 3'd1 , 3'd2, R_TYPE};
    instr_memory[5] = {SW, 3'd0, 3'd3, 3'd0, M_TYPE};
    instr_memory[6] = addr;
    instr_memory[7] = {'b0, SYS_END};

    run_code();

    assert(data_memory[address] == result)
    else $error ("Failed assertion! Memory at address %h should be %b but is %b", addr, result, $signed(data_memory[address]));

    assert(cpu.rf.reg_file[3] == result)
    else $error ("Failed assertion! Register 3 should be %d but is %d", result, cpu.rf.reg_file[3]);

    assert(cpu.rf.reg_file[1] == a)
    else $error ("Failed assertion! Register 1 should be %d but is %d", a, cpu.rf.reg_file[1]);

    assert(cpu.rf.reg_file[2] == b)
    else $error ("Failed assertion! Register 2 should be %d but is %d", b, cpu.rf.reg_file[2]);

    $display("Add Test Case Passed!! Memory at address %h was %d, which is %d + %d.", addr, $signed(data_memory[address]), a, b);


    a = 16'b1010;
    b = 16'b1010;
    result = a & b;

    instr_memory[0] = {ADD, 3'd1, 3'd0, 3'd0, I_TYPE};
    instr_memory[1] = a;
    instr_memory[2] = {ADD, 3'd2 , 3'd0, 3'd0, I_TYPE};
    instr_memory[3] = b;
    instr_memory[4] = {AND, 3'd3, 3'd1 , 3'd2, R_TYPE};
    instr_memory[5] = {SW, 3'd0, 3'd3, 3'd0, M_TYPE};
    instr_memory[6] = addr;
    instr_memory[7] = {'b0, SYS_END};

    run_code();

    assert(data_memory[address] == result)
    else $error ("Failed assertion! Memory at address %h should be %b but is %b", addr, result, $signed(data_memory[address]));

    assert(cpu.rf.reg_file[3] == result)
    else $error ("Failed assertion! Register 3 should be %d but is %d", result, cpu.rf.reg_file[3]);

    assert(cpu.rf.reg_file[1] == a)
    else $error ("Failed assertion! Register 1 should be %d but is %d", a, cpu.rf.reg_file[1]);

    assert(cpu.rf.reg_file[2] == b)
    else $error ("Failed assertion! Register 2 should be %d but is %d", b, cpu.rf.reg_file[2]);

    $display("AND Test Case Passed!! Memory at address %h was %d, which is %d + %d.", addr, $signed(data_memory[address]), a, b);


    a = 16'b1010;
    b = 16'b1010;
    result = a | b;

    instr_memory[0] = {ADD, 3'd1, 3'd0, 3'd0, I_TYPE};
    instr_memory[1] = a;
    instr_memory[2] = {ADD, 3'd2 , 3'd0, 3'd0, I_TYPE};
    instr_memory[3] = b;
    instr_memory[4] = {OR, 3'd3, 3'd1 , 3'd2, R_TYPE};
    instr_memory[5] = {SW, 3'd0, 3'd3, 3'd0, M_TYPE};
    instr_memory[6] = addr;
    instr_memory[7] = {'b0, SYS_END};

    run_code();

    assert(data_memory[address] == result)
    else $error ("Failed assertion! Memory at address %h should be %b but is %b", addr, result, $signed(data_memory[address]));

    assert(cpu.rf.reg_file[3] == result)
    else $error ("Failed assertion! Register 3 should be %d but is %d", result, cpu.rf.reg_file[3]);

    assert(cpu.rf.reg_file[1] == a)
    else $error ("Failed assertion! Register 1 should be %d but is %d", a, cpu.rf.reg_file[1]);

    assert(cpu.rf.reg_file[2] == b)
    else $error ("Failed assertion! Register 2 should be %d but is %d", b, cpu.rf.reg_file[2]);

    $display("OR Test Case Passed!! Memory at address %h was %d, which is %d + %d.", addr, $signed(data_memory[address]), a, b);



    $display("ALL CASES PASSED!!!!");
    $finish; 
  end

endmodule