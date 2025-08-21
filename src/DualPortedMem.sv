module DualPortedMem #(
    parameter int SIZE = 1024
) (
    input bit clk,

    AvalonMmRw.Agent   rw_bus,
    AvalonMmRead.Agent ro_bus
);
  byte mem[SIZE];

  initial begin
    for (int i = 0; i < SIZE; i++) begin
      mem[i] = 8'hXX;
    end
  end

  assign rw_bus.agent_to_host = {
    mem[rw_bus.address+3], mem[rw_bus.address+2], mem[rw_bus.address+1], mem[rw_bus.address+0]
  };
  assign rw_bus.waitrequest = 0;
  assign rw_bus.readdatavalid = 1;


  assign ro_bus.agent_to_host = {
    mem[ro_bus.address+3], mem[ro_bus.address+2], mem[ro_bus.address+1], mem[ro_bus.address+0]
  };
  assign ro_bus.waitrequest = 0;
  assign ro_bus.readdatavalid = 1;

  always_ff @(posedge clk) begin
    if (rw_bus.write) begin
      $display("WRITE %04b, %08x", rw_bus.byteenable, rw_bus.address);
      for (int i = 0; i < 4; i++) begin
        if (rw_bus.byteenable[i]) begin
          if (rw_bus.address + i <= SIZE) begin
            mem[rw_bus.address+i] <= rw_bus.host_to_agent[i*8+:8];
            $display(" - MEM[%08X] <= %02X", (rw_bus.address + i), (rw_bus.host_to_agent[i*8+:8]));
          end
        end
      end
    end
  end

  task automatic load_content(string filename);
    int fd = $fopen(filename, "r");

    if (fd != 0) begin
      $fread(mem, fd, 0);
    end else begin
      $fatal("'%s' could not be opened", filename);
    end
    $fclose(fd);
  endtask

  task automatic dump_content(string filename);
    int fd = $fopen(filename, "wb");
    if (fd != 0) begin
      for (int i = 0; i < SIZE; i += 1) begin
        $fwrite(fd, "%c", mem[i]);
      end
      $fclose(fd);
      $display("Memory dumped to '%s'", filename);
    end else begin
      $fatal("'%s' could not be opened", filename);
    end
  endtask
endmodule
