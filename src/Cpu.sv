`default_nettype none

import Types::*;

module Cpu (
    input logic clk,
    input logic rst,

    AvalonMmRw.Host   data_manager,
    AvalonMmRead.Host instruction_manager,

    output word debug_current_pc,
    output word debug_instruction
);

  /* Registers */
  initial ir = 'x;
  word ir;

  /* Control signals */
  bit load_next_instruction;
  bit en_iaddr;
  bit enable_pc_counter;
  ins_ctrl_signals_t ins_signals;
  bit [4:0] rd_sel, rs1_sel, rs2_sel;
  bit [2:0] ins_f3;
  bit [6:0] ins_f7;
  bit enable_rd_store, write_back_stage;
  /// Which bus are we waiting a response on?
  bit data_stall, instruction_stall;
  /// Delay execution
  bit stall;
  bit comp_result;
  bit mu_read_valid, mu_write_done;
  alu_mode_t alu_mode;
  bit alu_out_zero, invert_logic_result;

  /* Data path */
  word alu_in_a, alu_in_b, alu_out;
  word rd_in, rs1_out, rs2_out;
  word current_pc, next_pc;
  word ins_imm;
  int instruction_len;
  int pc_step;
  word data_from_bus;

  wire [6:0] opcode;
  Decoder decoder (
      .ir(ir),
      .len(instruction_len),
      .opcode(opcode),
      .rd(rd_sel),
      .rs1(rs1_sel),
      .rs2(rs2_sel),
      .imm(ins_imm),
      .f3(ins_f3),
      .f7(ins_f7)
  );
  ControlUnit cu (
      .clk(clk),
      .rst(rst),
      .stall(stall),
      .opcode(opcode),
      .f3(ins_f3),
      .f7(ins_f7),
      .active(ins_signals),
      .alu_mode(alu_mode),
      .invert_logic_result(invert_logic_result),

      .load_ir(load_next_instruction),
      .en_iaddr(en_iaddr),
      .en_pc_counter(enable_pc_counter),
      .write_back_stage(write_back_stage)
  );
  RegisterFile regs (
      .clk(clk),
      .rd_sel(rd_sel),
      .rs1_sel(rs1_sel),
      .rs2_sel(rs2_sel),
      .rd_in(rd_in),
      .rs1_out(rs1_out),
      .rs2_out(rs2_out),
      .rd_w(enable_rd_store && write_back_stage)
  );
  Mux #(
      .INS(2)
  ) alu_input_a_selector (
      .sel(ins_signals.alu_in_a),
      .in ('{rs1_out, current_pc}),
      .out(alu_in_a)
  );
  Mux #(
      .INS(2)
  ) alu_input_b_selector (
      .sel(ins_signals.alu_in_b),
      .in ('{rs2_out, ins_imm}),
      .out(alu_in_b)
  );
  Alu alu (
      .in_a(alu_in_a),
      .in_b(alu_in_b),
      .mode(alu_mode),
      .out (alu_out)
  );
  assign alu_out_zero = alu_out == 0;

  Mux #(
      .INS(4)
  ) destination_register_data_selector (
      .sel(ins_signals.dest_reg_from),
      .in ('{0, alu_out, data_from_bus, next_pc}),
      .out(rd_in)
  );

  Mux #(
      .INS(2)
  ) pc_step_src (
      .sel((!alu_out_zero ^ invert_logic_result) && ins_signals.branching),
      .in ('{instruction_len, ins_imm}),
      .out(pc_step)
  );

  ProgramCounter pc (
      .clk(clk),
      .rst(rst),
      .enabled(enable_pc_counter && !stall),
      .load(ins_signals.pc_src == PC_SRC_ALU && cu.write_back_stage),
      .step(pc_step),
      .in(alu_out),
      .next_pc(next_pc)
  );

  MemoryUnit mu (
      .clk(clk),
      .rst(rst),
      .read(ins_signals.dbus_re),
      .write(ins_signals.dbus_we),
      .address(alu_out),
      .len(ins_f3[1:0]),
      .zero_extend((ins_f3 & 3'b100) != 0),
      .to_bus(rs2_out),
      .from_bus(data_from_bus),
      .read_valid(mu_read_valid),
      .write_done(mu_write_done),
      .port(data_manager)
  );

  always_ff @(posedge clk, negedge rst) begin
    if (rst == 0) begin
      ir <= 0;
      current_pc <= 0;
    end
    else if (load_next_instruction && instruction_manager.readdatavalid) begin
      ir <= instruction_manager.agent_to_host;
      current_pc <= next_pc;
      $display("IR <= %08x FROM %08x", (instruction_manager.agent_to_host), (instruction_manager.address));
    end else ir <= ir;
  end

  assign instruction_manager.byteenable = 4'b1111;
  assign instruction_manager.read = en_iaddr;
  assign instruction_manager.address = en_iaddr ? next_pc : 0;

  assign data_stall = !(mu_read_valid && mu_write_done);
  assign instruction_stall = (instruction_manager.read && !instruction_manager.readdatavalid)
                          || (instruction_manager.read && instruction_manager.waitrequest);
  assign stall = data_stall || instruction_stall;

  assign enable_rd_store = ins_signals.dest_reg_from != DEST_REG_FROM_NONE;

  function word swap_endianness(input word idata);
    return {idata[7:0], idata[15:8], idata[23:16], idata[31:24]};
  endfunction

`ifdef __DUMP_STATE__
  task automatic dump_state();
    $display("[%4d] CPU State:", $time());
    $display(" - PC := %08X", current_pc);
    $display(" - Data bus A: %s", ins_signals.alu_in_a == 0 ? "REG" : "PC");
    $display(" - Data bus B: %s", ins_signals.alu_in_b == 0 ? "REG" : "IMM");
    $display(" - Data bus C: %d", ins_signals.dest_reg_from);
    alu.dump_state();
  endtask
`endif  // __DUMP_STATE__

  task automatic execute_opcode(word opcode);
    $display("[%4t] execute_opcode(%08x)", $time, opcode);
    ir <= opcode;
    cu.set_execute();
  endtask
endmodule
