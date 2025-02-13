`default_nettype none

import Types::word;

module CrossBar (
    input bit clk,
    AvalonMmRw.Host bus_side,
    AvalonMmRead.Agent primary,
    AvalonMmRw.Agent secondary
);
  bit primary_idle;
  bit secondary_idle;

  assign primary_idle   = ~(primary.read || 0);
  assign secondary_idle = ~(secondary.read || secondary.write);

  enum int {
    IDLE,
    SERVING_PRIMARY,
    SERVING_SECONDARY
  } state;

  always_ff @(posedge clk) begin
    if (state == IDLE) begin
      if (!secondary_idle) state <= SERVING_SECONDARY;
      else if (!primary_idle) state <= SERVING_PRIMARY;
      else state <= IDLE;
    end else begin
      // if the transaction is done
      if (!bus_side.waitrequest && (!bus_side.read || bus_side.readdatavalid)) begin
        // we can go back to idle, but that may start another transaction
        // since `primary` has priority, we might starve `secondary`,
        // so we check if secondary needs attention before going
        // back to IDLE
        state <= IDLE;
      end
      /* if (!bus_side.waitrequest && (!bus_side.read || bus_side.readdatavalid)) begin
        state <= IDLE;
      end else state <= state; */
    end
  end

  /* 
  assign bus_side.address = state == SERVING_PRIMARY ? primary.address : 'z;
  assign bus_side.byteenable = state == SERVING_PRIMARY ? primary.byteenable : 'z;
  assign primary.waitrequest = bus_side.waitrequest;
  assign bus_side.host_to_agent = state == SERVING_PRIMARY ? 0 : 'z;
  assign bus_side.write = state == SERVING_PRIMARY ? 0 : 'z;
  assign primary.agent_to_host = bus_side.agent_to_host;
  assign bus_side.read = state == SERVING_PRIMARY ? primary.read : 'z;
  assign primary.readdatavalid = bus_side.readdatavalid;



  assign bus_side.address = state == SERVING_SECONDARY ? secondary.address : primary.address;
  assign bus_side.byteenable = state == SERVING_SECONDARY ? secondary.byteenable : primary.byteenable;

  assign primary.waitrequest = state == SERVING_SECONDARY ? (!primary_idle) : bus_side.waitrequest;
  assign secondary.waitrequest = state == SERVING_SECONDARY ? bus_side.waitrequest : (!primary_idle);

  assign bus_side.host_to_agent = state == SERVING_SECONDARY ? secondary.host_to_agent : 0;
  assign bus_side.write = state == SERVING_SECONDARY ? secondary.write : 0;

  assign primary.agent_to_host = bus_side.agent_to_host;
  assign secondary.agent_to_host = bus_side.agent_to_host;

  assign bus_side.read = state == SERVING_SECONDARY ? secondary.read : primary.read;

  assign primary.readdatavalid = state == SERVING_SECONDARY ? 0 : bus_side.readdatavalid;
  assign secondary.readdatavalid = state == SERVING_SECONDARY ? bus_side.readdatavalid : 0;
 */

  always_comb begin
    case (state)
      SERVING_PRIMARY: begin
        bus_side.address = primary.address;
        bus_side.byteenable = primary.byteenable;
        primary.waitrequest = bus_side.waitrequest;
        bus_side.host_to_agent = 'x;
        bus_side.write = 0;
        bus_side.read = primary.read;
        primary.agent_to_host = bus_side.agent_to_host;
        primary.readdatavalid = bus_side.readdatavalid;

        secondary.waitrequest = !secondary_idle;
        secondary.agent_to_host = 0;
        secondary.readdatavalid = 0;
      end
      SERVING_SECONDARY: begin
        bus_side.address = secondary.address;
        bus_side.byteenable = secondary.byteenable;
        secondary.waitrequest = bus_side.waitrequest;
        bus_side.host_to_agent = secondary.host_to_agent;
        bus_side.write = secondary.write;
        bus_side.read = secondary.read;
        secondary.agent_to_host = bus_side.agent_to_host;
        secondary.readdatavalid = bus_side.readdatavalid;

        primary.waitrequest = !primary_idle;
        primary.agent_to_host = 0;
        primary.readdatavalid = 0;
      end
      default: begin
        bus_side.address = 0;
        bus_side.byteenable = 0;
        bus_side.host_to_agent = 0;
        bus_side.write = 0;
        bus_side.read = 0;
        secondary.agent_to_host = 0;
        secondary.readdatavalid = 0;

        primary.agent_to_host = 0;
        primary.readdatavalid = 0;

        primary.waitrequest = !primary_idle;
        secondary.waitrequest = !secondary_idle;
      end
    endcase
  end
endmodule
