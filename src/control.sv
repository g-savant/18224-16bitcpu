`default_nettype none

//need to add repeat state if error;
//NRZI may be a good idea

module control(
  input logic ard_data_ready, clk, rst, ard_receive_ready, halt, valid_instr,
  input dec_sig_t signals, 
  output ctrl_sig_t ctrl,
  output logic bus_pc, bus_mdr, bus_mar, error);

  enum logic[4:0] {OP, 
                  SSHIFT_ADDR1,SSHIFT_ADDR2, SSHIFT_DATA1,SSHIFT_DATA2, 
                  ADDR_SHIFT1, ADDR_SHIFT2, WAIT_LOAD, WAIT, WAITPC_INSTR,
                  LOAD_MEM1, LOAD_MEM2,
                  PC_OUT1, PC_OUT2, INSTR_SHIFT,
                  DONE, WAIT_SENDPC, START, LOAD_PC1, LOAD_PC2} cs, ns;

  


  //ard_ready -> pc out -> ard_data_ready -> instruction_in -> op ->--->
  //                                                                 \
  //                                                                  \->sendpc
  always_comb begin 
    ctrl.instr_shift_in = 1'b0;
    ctrl.pc_shift_out = 1'b0;
    ctrl.mdr_shift_out = 1'b0;
    ctrl.mar_shift_out = 1'b0;
    ctrl.mdr_shift_in = 1'b0;
    ctrl.mdr_load = 1'b0;
    ctrl.mar_load = 1'b0;
    ctrl.go = 1'b0;
    bus_pc = 1'b0;
    bus_mdr = 1'b0;
    bus_mar = 1'b0;
    error = 1'b0;
    ctrl.pc_en = 1'b0;
    ns = WAIT_SENDPC;
    case(cs)
      OP: begin
        ctrl.go = 1'b1;
        ctrl.pc_en = 1'b1;
        if(signals.opcode == M_TYPE) begin
          ns = WAIT_LOAD;
          ctrl.mar_load = 1'b1;
          ctrl.mdr_load =1'b1;
        end else begin
          ns = WAIT_SENDPC;
        end
      end
      WAIT_LOAD: begin
        if(ard_receive_ready) begin
          ns = ADDR_SHIFT1;
        end else ns = WAIT_LOAD;
      end
        //put ctrl.go into instruction decode
        //no ops when not ctrl.go
      ADDR_SHIFT1:begin
        ctrl.mar_shift_out = 1'b1;
        bus_mar = 1'b1;
        ns = ADDR_SHIFT2;
      end
      ADDR_SHIFT2: begin
        if(signals.opcode == M_TYPE & (signals.mem_op == LW | signals.mem_op == LB | signals.mem_op == LHW)) begin 
          ns = WAIT;
          bus_mar = 1'b1;
          ctrl.mar_shift_out = 1'b1;
        end else if(signals.opcode == M_TYPE & (signals.mem_op == SW | signals.mem_op == SB | signals.mem_op == SHW)) begin
          ns = SSHIFT_DATA1;
          bus_mar = 1'b1;
          ctrl.mar_shift_out = 1'b1;
        end else begin
          error <= 1'b1;
          ns = ADDR_SHIFT2;
        end 
      end
      SSHIFT_DATA1:begin
        ctrl.mdr_shift_out = 1'b1;
        bus_mdr = 1'b1;
        ns = SSHIFT_DATA2;
      end
      SSHIFT_DATA2:begin
        ctrl.mdr_shift_out = 1'b1;
        bus_mdr = 1'b1;
        ns = WAIT_SENDPC;
      end
      WAIT: begin
        if(ard_data_ready) begin
          ns = LOAD_MEM1;
        end else ns = WAIT;
      end
      LOAD_MEM1: begin
        ctrl.mdr_shift_in = 1'b1;
        ns = LOAD_MEM2;
      end
      LOAD_MEM2: begin
        ctrl.mdr_shift_in = 1'b1;
        ns = WAIT_SENDPC;
      end
      WAIT_SENDPC: begin
        if(ard_receive_ready) begin
          ns = PC_OUT1;
        end else ns = WAIT_SENDPC;
      end
      PC_OUT1: begin
        ctrl.pc_shift_out = 1'b1;
        bus_pc = 1'b1;
        ns = PC_OUT2;
      end
      PC_OUT2: begin
        ctrl.pc_shift_out = 1'b1;
        bus_pc = 1'b1;
        ns = WAITPC_INSTR;
      end
      WAITPC_INSTR: begin
        if(ard_data_ready) begin
          ns = INSTR_SHIFT;
          ctrl.instr_shift_in = 1'b1;
        end 
      end
      INSTR_SHIFT: begin
        if(valid_instr) begin
          ctrl.instr_shift_in = 1'b0;
          ctrl.go = (halt) ? 1'b0 : 1'b1;
          ns = (halt) ? DONE : OP;
        end else begin
          ns = INSTR_SHIFT;
          ctrl.instr_shift_in = 1'b1;
          ctrl.go = 1'b0;
        end
      end
      DONE: begin
        ns = DONE;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if(rst) cs <= WAIT_SENDPC;
    else cs <= ns;
  end



endmodule