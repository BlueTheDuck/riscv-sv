import Types::*;

typedef struct packed {
  bit [6:0] f7;
  bit [4:0] rs2, rs1;
  bit [2:0] f3;
  bit [4:0] rd;
  bit [6:0] op;
} op_r_t;
typedef struct packed {
  bit [11:0] imm;
  bit [4:0]  rs1;
  bit [2:0]  f3;
  bit [4:0]  rd;
  bit [6:0]  op;
} op_i_t;

module CpuTb ();

  bit clk, rst;
  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ

  AvalonMmRw data_manager ();
  AvalonMmRead instruction_manager ();
  // Feed NOP; makes sure the CPU has something to read
  // We use cpu.execute_opcode to change the opcode
  assign instruction_manager.readdatavalid = 1;
  assign instruction_manager.agent_to_host = op_i_t'{
          imm: 0,
          rs1: 0,
          f3: 0,
          rd: 0,
          op: OP_ALUI
      };  // NOP

  Cpu cpu (
      .clk(clk),
      .rst(rst),
      .data_manager(data_manager.Host),
      .instruction_manager(instruction_manager.Host),
      .debug_current_pc(),
      .debug_instruction()
  );

  initial begin
    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, CpuTb);
    $display("Starting CPU Testbench...");
    reset();
    fork
      do_test();
      #1000 begin
        $display("Testbench timed out, stopping simulation.");
        $finish;
      end
    join
  end

  task automatic do_test();
    $display("Doing test");
    cpu.execute_opcode(op_i_t'{imm: 1, rs1: 10, f3: 0, rd: 11, op: OP_ALUI});  // x11 = x10 + 1
    cpu.regs.set_registers('{
      10: 4,
      default: 0
    });
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $display("Test completed successfully.");
    $finish;
  endtask

  task automatic reset();
    $display("[%05t] Resetting CPU", $time);
    rst <= 1;
    #1;
    rst <= 0;
    @(posedge clk);
    rst <= 1;
  endtask
endmodule
