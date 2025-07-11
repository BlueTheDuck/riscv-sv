`default_nettype none


module Cpu (
    input logic clk,
    input logic rst,

    AvalonMmRw.Host   data_manager,
    AvalonMmRead.Host instruction_manager,

    output Types::uint32_t debug_current_pc,
    output Types::uint32_t debug_instruction
);
  import Types::*;

  /* Registers */
  initial ir = 'x;
  uint32_t ir;

  /* Control signals */
  bit load_next_instruction;
  bit fetch_next_instruction;
  bit increment_pc;
  data_path_map_t data_path;
  bit invert_logic_result;
  bit branch, dbus_we;
  alu_mode_t alu_mode;
  bit [6:0] opcode;
  bit [4:0] rd_index, rs1_index, rs2_index;
  bit [2:0] instruction_f3;
  bit [6:0] instruction_f7;
  bit enable_rd_store, write_back_stage;
  /// Which bus are we waiting a response on?
  bit data_stall, instruction_stall;
  /// Delay execution
  bit stall;
  bit mu_read_valid, mu_write_done;

  /* Data path */
  int32_t alu_in_a, alu_in_b, alu_out;
  bit alu_out_zero;
  uint32_t rd_in, rs1_out, rs2_out;
  int32_t current_pc, next_pc;
  int32_t  instruction_immediate;
  int32_t  instruction_len;
  int32_t  pc_step;
  uint32_t data_from_bus;

  Decoder decoder (
      .ir(ir),
      .len(instruction_len),
      .opcode(opcode),
      .rd(rd_index),
      .rs1(rs1_index),
      .rs2(rs2_index),
      .imm(instruction_immediate),
      .f3(instruction_f3),
      .f7(instruction_f7)
  );
  ControlUnit cu (
      .clk(clk),
      .rst(rst),
      .stall(stall),
      .opcode(opcode),
      .f3(instruction_f3),
      .f7(instruction_f7),
      .data_path(data_path),
      .alu_mode(alu_mode),
      .invert_logic_result(invert_logic_result),
      .dbus_we(dbus_we),
      .is_branch(branch),

      .load_ir(load_next_instruction),
      .fetch_next_instruction(fetch_next_instruction),
      .en_pc_counter(increment_pc),
      .write_back_stage(write_back_stage)
  );
  RegisterFile regs (
      .clk(clk),
      .rd_index(rd_index),
      .rs1_index(rs1_index),
      .rs2_index(rs2_index),
      .rd_in(rd_in),
      .rs1_out(rs1_out),
      .rs2_out(rs2_out),
      .rd_w(enable_rd_store && write_back_stage)
  );
  always_comb begin : ALU_INPUT_A_MUX
    unique case (data_path.alu_in_a)
      ALU_IN_A_REG: alu_in_a = rs1_out;
      ALU_IN_A_PC:  alu_in_a = current_pc;
    endcase
  end
  always_comb begin : ALU_INPUT_B_MUX
    unique case (data_path.alu_in_b)
      ALU_IN_B_REG: alu_in_b = rs2_out;
      ALU_IN_B_IMM: alu_in_b = instruction_immediate;
    endcase
  end
  Alu alu (
      .in_a(alu_in_a),
      .in_b(alu_in_b),
      .mode(alu_mode),
      .out (alu_out)
  );

  always_comb begin : DEST_REG_MUX
    unique case (data_path.dest_reg_from)
      DEST_REG_FROM_NONE: rd_in = 0;
      DEST_REG_FROM_ALU:  rd_in = alu_out;
      DEST_REG_FROM_MEM:  rd_in = data_from_bus;
      DEST_REG_FROM_PC:   rd_in = next_pc;
    endcase
  end

  always_comb begin : PC_STEP_MUX
    bit take_branch = !(alu_out == 0) ^ invert_logic_result;
    if (take_branch && branch) begin
      pc_step = instruction_immediate;
    end else begin
      pc_step = instruction_len;
    end
  end

  Counter pc (
      .clk(clk),
      .rst(rst),
      .increment(increment_pc && !stall),
      .load(data_path.pc_src == PC_SRC_ALU && write_back_stage),
      .step(pc_step),
      .in(alu_out),
      .out(next_pc)
  );

  MemoryUnit mu (
      .clk(clk),
      .rst(rst),
      .read(data_path.dest_reg_from == DEST_REG_FROM_MEM),
      .write(dbus_we),
      .address(alu_out),
      .len(instruction_f3[1:0]),
      .zero_extend((instruction_f3 & 3'b100) != 0),
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
    end else if (load_next_instruction && instruction_manager.readdatavalid) begin
      ir <= instruction_manager.agent_to_host;
      current_pc <= next_pc;
      $display("IR <= %08x FROM %08x", instruction_manager.agent_to_host,
               instruction_manager.address);
    end else begin
      ir <= ir;
      current_pc <= current_pc;
    end
  end

  assign instruction_manager.byteenable = 4'b1111;
  assign instruction_manager.read = fetch_next_instruction;
  assign instruction_manager.address = next_pc;

  assign data_stall = !(mu_read_valid && mu_write_done);
  assign instruction_stall = (instruction_manager.read && !instruction_manager.readdatavalid)
                          || (instruction_manager.read && instruction_manager.waitrequest);
  assign stall = data_stall || instruction_stall;

  assign enable_rd_store = data_path.dest_reg_from != DEST_REG_FROM_NONE;

  assign alu_out_zero = alu_out == 0;

  function word swap_endianness(input word idata);
    return {idata[7:0], idata[15:8], idata[23:16], idata[31:24]};
  endfunction

`ifdef __DUMP_STATE__
  task automatic dump_state();
    $display("[%4d] CPU State:", $time());
    $display(" - PC := %08X", current_pc);
    $display(" - Data bus A: %s", data_path.alu_in_a == 0 ? "REG" : "PC");
    $display(" - Data bus B: %s", data_path.alu_in_b == 0 ? "REG" : "IMM");
    $display(" - Data bus C: %d", data_path.dest_reg_from);
    alu.dump_state();
  endtask
`endif  // __DUMP_STATE__

  task automatic execute_opcode(word opcode);
    $display("[%4t] execute_opcode(%08x)", $time, opcode);
    ir <= opcode;
    cu.set_execute();
  endtask
endmodule
