import Types::*;

module Computer ();
  bit clk, rst;
  AvalonMmRead ibus();
  AvalonMmRw dbus();

  Rom rom(
    .data_manager(ibus.Agent),
    .*
  );
  Ram ram(
    .data_manager(dbus.Agent),
    .*
  );
  Cpu cpu (
      .clk  (clk),
      .rst  (rst),
      .instruction_manager(ibus.Host),
      .data_manager(dbus.Host),
      .*
  );

  initial clk = 1;
  always #5 clk = !clk;
  always_ff @(posedge clk, negedge rst) begin
    cpu.dump_state();
  end
  initial rst = 1;

  /* always_ff @(posedge clk) begin
    if (ibus.agent.read) begin
      cpu_idata_in <= rom_dout;
      i_readdatavalid <= 1;
    end else begin
      cpu_idata_in <= cpu_idata_in;
      i_readdatavalid <= 0;
    end
  end */
  /* always_ff@(posedge clk) begin
    if(cpu.avalon_mm_read)
      $display("[Avalon MM] CPU <= RAM[%h]", cpu.avalon_mm_address);
    if(cpu.avalon_mm_write)
      $display("[Avalon MM] %08x => RAM[%h]", cpu.avalon_mm_src, cpu.avalon_mm_address);
  end */

  initial begin
    // $readmemh("rom.hex", rom);
    /* int fd = $fopen("rom.bin", "r");
    if (fd != 0) $fread(rom, fd, 0, 4096);
    else begin
      $fatal("rom.bin could not be opened");
    end
    $fclose(fd);
    bus_addr = 32'hZ;
    rom_dout = 32'hZ; */
    $dumpfile("trace.vcd");
    $dumpvars(0, Computer);
    cpu.dump_state();
    #5 rst = 1;
    #9 rst = 0;
    #7 rst = 1;
    // tick();
    // tick();
    // tick();
    $display("Reset done");
    #1000 $finish;
    /* for (int i = 0; i < 20; i++) begin
      tick();
    end */
    // $finish;
  end
  task automatic tick();
    `ifdef DEBUG
    cpu.dump_state();
    `endif
  endtask  //automatic
endmodule
