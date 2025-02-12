import Types::*;

module Ram (
    input bit clk,
    AvalonMmRw.Agent data_manager
);


  word memory[word];

  int  delay;
  assign data_manager.waitrequest = data_manager.write && (delay > 0);
  assign data_manager.readdatavalid = data_manager.read && (delay == 0);

  assign data_manager.agent_to_host = (delay <= 1) ? memory[data_manager.address] : 'x;

  always_ff @(posedge clk) begin
    if (delay == 1 && data_manager.write) begin
      $display("[Avalon Agent] About to fullfil request!");
      memory[data_manager.address] <= data_manager.host_to_agent;
      $display("[Avalon Agent] memory[%h] <= %h", data_manager.address,
               data_manager.host_to_agent);
    end
  end

  always_ff @(posedge clk) begin
    if (delay > 0) begin
      if (!data_manager.write && !data_manager.read) delay <= 0;
      else delay <= delay - 1;
    end else if (data_manager.write) begin
      if (delay == 0) begin
        $display("[Avalon Agent] Write requested");
        delay <= 4;
      end
    end else if (data_manager.read) begin
      if (data_manager.write) begin
        if (delay == 0) begin
          $display("[Avalon Agent] Read requested");
          delay <= 2;
        end
      end
    end
  end

`ifdef DUMP_FINAL_STATE
  final begin
    foreach (memory[addr]) begin
      $display("Memory[%0d] = %0h", addr, memory[addr]);
    end
  end
`endif
endmodule
