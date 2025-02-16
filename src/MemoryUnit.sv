`default_nettype none

import Types::word;

module MemoryUnit (
    input bit clk,
    input bit rst,

    input bit read,
    input bit write,
    input word address,
    input bit [1:0] len,
    input bit zero_extend,
    input word to_bus,
    output word from_bus,
    output bit ready,

    AvalonMmRw.Host port
);
  enum {
    READY,
    READING,
    WRITING,
    DONE
  } state;

  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      state <= READY;
    end else if (state == READY) begin
      if (read && !write) begin
        state <= READING;
      end else if (!read && write) begin
        state <= WRITING;
      end else begin
        state <= READY;
      end
    end else if (state == READING) begin
      if (port.readdatavalid && !port.waitrequest) begin
        state <= DONE;
      end else begin
        state <= state;
      end
    end else if (state == WRITING) begin
      if (!port.waitrequest) begin
        state <= DONE;
      end else begin
        state <= state;
      end
    end else if (state == DONE) begin
      if (!read && !write) begin
        state <= READY;
      end else begin
        state <= state;
      end
    end
  end

  assign port.read = state == READING;
  assign port.write = state == WRITING;
  assign port.address = address;
  assign ready = state == READY || state == DONE;
  assign from_bus = mask_bytes(port.agent_to_host, len, zero_extend);
  assign port.host_to_agent = mask_bytes(to_bus, len, zero_extend);

  always_comb
    case (len)
      0: port.byteenable = 4'b0001;
      1: port.byteenable = 4'b0011;
      2: port.byteenable = 4'b1111;
      default: port.byteenable = 0;
    endcase

  function word mask_bytes(input word data, input bit [1:0] len, input bit zero_extend);
    casez ({
      zero_extend, len
    })
      3'b000:  return 32'(signed'(data[7:0]));
      3'b001:  return 32'(signed'(data[15:0]));
      3'b010:  return data;
      3'b100:  return {24'b0, data[7:0]};
      3'b101:  return {16'b0, data[15:0]};
      default: return 0;
    endcase
  endfunction
endmodule
