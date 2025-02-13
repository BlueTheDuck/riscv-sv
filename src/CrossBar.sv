`default_nettype none

import Types::word;

module CrossBar (
    input bit clk,
    AvalonMmRw.Host bus_side,
    AvalonMmRead.Agent instruction_manager,
    AvalonMmRw.Agent data_manager
);
  bit instruction_manager_idle;
  bit data_manager_idle;

  assign instruction_manager_idle = ~(instruction_manager.read || 0);
  assign data_manager_idle = ~(data_manager.read || data_manager.write);

  enum int {
    IDLE,
    SERVING_INSTRUCTION_MANAGER,
    SERVING_DATA_MANAGER
  } state;

  always_ff @(posedge clk) begin
    if (state == IDLE) begin
      if (!data_manager_idle) state <= SERVING_DATA_MANAGER;
      else if (!instruction_manager_idle) state <= SERVING_INSTRUCTION_MANAGER;
      else state <= IDLE;
    end else begin
      if (!bus_side.waitrequest && (!bus_side.read || bus_side.readdatavalid)) begin
        state <= IDLE;
      end else state <= state;
    end
  end

  always_comb begin
    case (state)
      SERVING_INSTRUCTION_MANAGER: begin
        bus_side.address = instruction_manager.address;
        bus_side.byteenable = instruction_manager.byteenable;
        instruction_manager.waitrequest = bus_side.waitrequest;
        bus_side.host_to_agent = 'x;
        bus_side.write = 0;
        bus_side.read = instruction_manager.read;
        instruction_manager.agent_to_host = bus_side.agent_to_host;
        instruction_manager.readdatavalid = bus_side.readdatavalid;

        data_manager.waitrequest = !data_manager_idle;
        data_manager.agent_to_host = 0;
        data_manager.readdatavalid = 0;
      end
      SERVING_DATA_MANAGER: begin
        bus_side.address = data_manager.address;
        bus_side.byteenable = data_manager.byteenable;
        data_manager.waitrequest = bus_side.waitrequest;
        bus_side.host_to_agent = data_manager.host_to_agent;
        bus_side.write = data_manager.write;
        bus_side.read = data_manager.read;
        data_manager.agent_to_host = bus_side.agent_to_host;
        data_manager.readdatavalid = bus_side.readdatavalid;

        instruction_manager.waitrequest = !instruction_manager_idle;
        instruction_manager.agent_to_host = 0;
        instruction_manager.readdatavalid = 0;
      end
      default: begin
        bus_side.address = 0;
        bus_side.byteenable = 0;
        bus_side.host_to_agent = 0;
        bus_side.write = 0;
        bus_side.read = 0;

        data_manager.agent_to_host = 0;
        data_manager.readdatavalid = 0;

        instruction_manager.agent_to_host = 0;
        instruction_manager.readdatavalid = 0;

        instruction_manager.waitrequest = !instruction_manager_idle;
        data_manager.waitrequest = !data_manager_idle;
      end
    endcase
  end
endmodule
