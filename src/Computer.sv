`define KB(n) (n * 1024)

module Computer ();
  bit clk, rst;
  AvalonMmRead ibus ();
  AvalonMmRw dbus ();
  AvalonMmRw bus ();
  DualPortedMem #(
      .SIZE(8 * 1024)
  ) memory (
      .clk(clk),
      .rw_bus(dbus.Agent),
      .ro_bus(ibus.Agent)
  );

  Cpu cpu (
      .instruction_manager(ibus.Host),
      .data_manager(dbus.Host),
      .*
  );

  initial clk = 1;
  // verilator lint_off BLKSEQ
  always #5 clk = !clk;
  // verilator lint_on BLKSEQ
  always_ff @(posedge clk, negedge rst) begin
    cpu.dump_state();
  end
  initial rst = 1;

  initial begin
    var string memory_init_file;
    $value$plusargs("INIT_FILE=%s", memory_init_file);
    if (memory_init_file == "") begin
      $error("INIT_FILE not specified.\n example: <exe> +INIT_FILE=rom.bin");
      $fatal;
    end
    memory.loadContentFrom(memory_init_file);

    $dumpfile("trace.vcd");
    $dumpvars(0, Computer);
    fork
      doTest();
      #1000 $finish;
    join
  end

  final begin
    $display("Simulation finished at %0t", $time);
    memory.dumpContentTo("ram.bin");
  end


  task automatic doTest();
    cpu.dump_state();
    #5 rst = 1;
    #9 rst = 0;
    #7 rst = 1;
    $display("Reset done");
  endtask  //automatic
  task automatic tick();
`ifdef DEBUG
    cpu.dump_state();
`endif
  endtask  //automatic
endmodule
