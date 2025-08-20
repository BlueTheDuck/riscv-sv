`default_nettype none

module MemoryUnit
  import Types::*;
(
    input bit clk,
    input bit rst,

    input word address,
    input int_size_t size,
    input bit zero_extend,

    input  bit  read,
    output word from_bus,

    input bit  write,
    input word to_bus,

    output bit ready,

    AvalonMmRw.Host port
);
  enum int {
    IDLE,
    PUT_REQUEST_ON_BUS,
    PUT_WRITE_ON_BUS,
    WAITING_FOR_RESPONSE
  } state;

  assign port.read  = state == PUT_REQUEST_ON_BUS;
  assign port.write = state == PUT_WRITE_ON_BUS;
  always_comb begin
    priority case (size)
      INT_SIZE_BYTE: port.byteenable = 4'b0001;
      INT_SIZE_HALF: port.byteenable = 4'b0011;
      INT_SIZE_WORD: port.byteenable = 4'b1111;
      default: port.byteenable = 0;
    endcase
  end
  assign ready = state == IDLE;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= IDLE;
    end else begin
      unique case (state)
        IDLE:
        if (read) begin
          port.address <= address;
          state <= PUT_REQUEST_ON_BUS;
        end else if (write) begin
          port.address <= address;
          port.host_to_agent <= to_bus;
          state <= PUT_WRITE_ON_BUS;
        end

        PUT_REQUEST_ON_BUS:
        if (port.readdatavalid) begin
          from_bus <= truncate_word(port.agent_to_host, size, ~zero_extend);
          state <= IDLE;
        end else if (port.waitrequest) begin
          state <= PUT_REQUEST_ON_BUS;
        end else begin
          state <= WAITING_FOR_RESPONSE;
        end

        PUT_WRITE_ON_BUS:
        if (port.waitrequest) begin
          state <= PUT_WRITE_ON_BUS;
        end else begin
          state <= IDLE;
        end

        WAITING_FOR_RESPONSE:
        if (port.readdatavalid) begin
          from_bus <= truncate_word(port.agent_to_host, size, ~zero_extend);
          state <= IDLE;
        end
      endcase
    end
  end

  function word truncate_word(input uint32_t data, input int_size_t size, input bit sign_extend);
    case ({
      sign_extend, size
    })
      {1'b1, INT_SIZE_BYTE} : return signed'(data[7:0]);
      {1'b1, INT_SIZE_HALF} : return signed'(data[15:0]);
      {1'b1, INT_SIZE_WORD} : return data;
      {1'b0, INT_SIZE_BYTE} : return unsigned'(data[7:0]);
      {1'b0, INT_SIZE_HALF} : return unsigned'(data[15:0]);
      {1'b0, INT_SIZE_WORD} : return data;
      default: return 0;
    endcase
  endfunction
endmodule
