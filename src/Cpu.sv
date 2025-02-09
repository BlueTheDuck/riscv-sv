`default_nettype none

// `include "AvalonMm.sv"

import Types::*;

module Cpu (
    input logic clk,
    input logic rst,

    AvalonMmRw.Host   data_manager,
    AvalonMmRead.Host instruction_manager
);

  // Registers
  initial ir = 'x;
  word ir;

  // Control signals
  bit hold;
  bit load_next_instruction;
  bit en_iaddr;
  bit enable_pc_counter;
  cu_t control_signals;
  bit [9:0] alu_op;
  bit [4:0] rd_index, rs1_index, rs2_index;
  bit [2:0] decoder_f3;
  bit [6:0] decoder_f7;

  // Data paths
  word alu_in_a, alu_in_b, alu_out;
  word rd_in, dout1, dout2;
  word curr_pc, next_pc;
  word decoder_imm;
  int instruction_len;

  wire [6:0] opcode;
  Decoder decoder (
      .ir(ir),
      .len(instruction_len),
      .opcode(opcode),
      .rd(rd_index),
      .rs1(rs1_index),
      .rs2(rs2_index),
      .imm(decoder_imm),
      .f3(decoder_f3),
      .f7(decoder_f7)
  );
  ControlUnit cu (
      .clk(clk),
      .rst(rst),
      .hold(hold),
      .opcode(opcode),
      .active(control_signals),

      .load_ir(load_next_instruction),
      .en_iaddr(en_iaddr),
      .enable_pc_counter(enable_pc_counter)
  );
  RegisterFile regs (
      .clk(clk),
      .rd(rd_index),
      .rs1(rs1_index),
      .rs2(rs2_index),
      .din(rd_in),
      .dout1(dout1),
      .dout2(dout2),
      .rd_w(control_signals.rb_store && !hold),
      .rs1_en(1),
      .rs2_en(1)
  );
  Mux #(
      .INS(2)
  ) alu_input_a_selector (
      .sel(control_signals.alu_in_a),
      .in ('{dout1, curr_pc}),
      .out(alu_in_a)
  );
  Mux #(
      .INS(2)
  ) alu_input_b_selector (
      .sel(control_signals.alu_in_b),
      .in ('{dout2, decoder_imm}),
      .out(alu_in_b)
  );
  Mux #(
      .INS(2),
      .W  (10)
  ) alu_operation_mode (
      .sel(control_signals.alu_mode),
      .in ('{{decoder_f7, decoder_f3}, 0}),
      .out(alu_op)
  );
  Alu alu (
      .in_a(alu_in_a),
      .in_b(alu_in_b),
      .op3 (alu_op[2:0]),
      .op7 (alu_op[9:3]),
      .out (alu_out)
  );


  Mux #(
      .INS(3)
  ) destination_register_data_selector (
      .sel(control_signals.dest_reg_from),
      .in ('{alu_out, data_manager.agent_to_host, next_pc}),
      .out(rd_in)
  );

  ProgramCounter pc (
      .clk(clk),
      .rst(rst),
      .enabled(enable_pc_counter && !hold),
      .load(control_signals.pc_load),
      .step(instruction_len),
      .in(alu_out),
      .next_pc(next_pc),
      .curr_pc(curr_pc)
  );

  assign hold =    (data_manager.write       && data_manager.waitrequest)
                || (data_manager.read        && !data_manager.readdatavalid)
                || (instruction_manager.read && !instruction_manager.readdatavalid)
                || (instruction_manager.read && instruction_manager.waitrequest);

  assign data_manager.address = alu_out;
  assign data_manager.host_to_agent = dout2;
  assign data_manager.byteenable = 4'b1111;
  assign data_manager.read = control_signals.dbus_re;
  assign data_manager.write = control_signals.dbus_we;

  assign instruction_manager.byteenable = 4'b1111;

  always_ff @(posedge clk, negedge rst) begin
    if (rst == 0) ir <= 0;
    else if (load_next_instruction && instruction_manager.readdatavalid) begin
      ir <= swap_endianness(instruction_manager.agent_to_host);
      $display("IR <= %08x", swap_endianness(instruction_manager.agent_to_host));
    end else ir <= ir;
  end
  assign instruction_manager.read = en_iaddr;
  assign instruction_manager.address = en_iaddr ? curr_pc : 0;

  function word swap_endianness(input word idata);
    return {idata[7:0], idata[15:8], idata[23:16], idata[31:24]};
  endfunction

  task automatic dump_state();
    $display("[%4d] CPU State:", $time());
    $display(" - Data bus A: %s", control_signals.alu_in_a == 0 ? "REG" : "PC");
    $display(" - Data bus B: %s", control_signals.alu_in_b == 0 ? "REG" : "IMM");
    $display(" - Data bus C: %d", control_signals.dest_reg_from);
    alu.dump_state();
    pc.dump_state();
  endtask
endmodule
