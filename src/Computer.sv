`define KB(n) (n * 1024)

module Computer ();
  import Types::*;

  localparam TIMEOUT = 0.01ms;
  localparam DELAY_ONE_PERCENT = TIMEOUT / 100;

  bit clk, rst;
  uint32_t debug_current_pc, debug_instruction, debug_registers[32];
  bit debug_wait = 0;

  AvalonMmRead ibus ();
  AvalonMmRw dbus ();
  DualPortedMem #(
      .SIZE(8 * 1024)
  ) memory (
      .clk(clk),
      .rw_bus(dbus),
      .ro_bus(ibus)
  );

  Cpu cpu (
      .instruction_manager(ibus),
      .data_manager(dbus),
      .*
  );

  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ
  always_ff @(posedge clk) begin
    if (dbus.write && dbus.address == 32'hF0000000) begin
      $display("[%04t] exit(%h)", $time, dbus.host_to_agent);
      $finish;
    end
  end
  initial rst = 1;

  initial begin
    var string memory_init_file;
    $value$plusargs("INIT_FILE=%s", memory_init_file);
    if (memory_init_file == "") begin
      $error("INIT_FILE not specified.\n example: <exe> +INIT_FILE=rom.bin");
      $fatal;
    end
    memory.load_content(memory_init_file);

    $dumpfile("logs/computer.vcd");
    $dumpvars(0, Computer);
    fork
      do_test();
      timeout();
    join
  end

  final begin
    $display("Simulation finished at %t", $time);
    memory.dump_content("logs/ram.bin");
  end


  task automatic do_test();
`ifdef __DUMP_STATE__
    cpu.dump_state();
`endif
    #5 rst = 1;
    #9 rst = 0;
    #7 rst = 1;
    $display("Reset done");
`ifdef __DUMP_STATE__
    cpu.dump_state();
`endif
  endtask

  task automatic timeout();
    for (int i = 0; i < 100; i++) begin
      #DELAY_ONE_PERCENT;
      $display("Warning %d/100: %0t ticks elapsed", i + 1, $time);
    end
    $display("Simulation timeout at %t, finishing...", $time);
    $finish;
  endtask
endmodule
