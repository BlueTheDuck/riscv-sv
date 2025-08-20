`default_nettype none

module DataManagerUnit
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
    READY,
    SEND_READ_REQUEST,
    SEND_WRITE_REQUEST,
    WAITING_FOR_RESPONSE
  } state;

  assign port.read  = state == SEND_READ_REQUEST;
  assign port.write = state == SEND_WRITE_REQUEST;
  assign ready      = state == READY;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= READY;
    end else begin
      unique case (state)
        READY:
        if (read) begin
          port.address <= address;
          port.byteenable <= size_to_bytemask(size);
          state <= SEND_READ_REQUEST;
        end else if (write) begin
          port.address <= address;
          port.host_to_agent <= to_bus;
          port.byteenable <= size_to_bytemask(size);
          state <= SEND_WRITE_REQUEST;
        end

        SEND_READ_REQUEST:
        if (port.readdatavalid) begin
          from_bus <= truncate_word(port.agent_to_host, size, ~zero_extend);
          state <= READY;
        end else if (port.waitrequest) begin
          state <= SEND_READ_REQUEST;
        end else begin
          state <= WAITING_FOR_RESPONSE;
        end

        SEND_WRITE_REQUEST:
        if (port.waitrequest) begin
          state <= SEND_WRITE_REQUEST;
        end else begin
          state <= READY;
        end

        WAITING_FOR_RESPONSE:
        if (port.readdatavalid) begin
          from_bus <= truncate_word(port.agent_to_host, size, ~zero_extend);
          state <= READY;
        end
      endcase
    end
  end

  function word truncate_word(input uint32_t data, input int_size_t size, input bit zero_extend);
    case ({
      zero_extend, size
    })
      {1'b0, INT_SIZE_BYTE} : return signed'(data[7:0]);
      {1'b0, INT_SIZE_HALF} : return signed'(data[15:0]);
      {1'b0, INT_SIZE_WORD} : return data;
      {1'b1, INT_SIZE_BYTE} : return unsigned'(data[7:0]);
      {1'b1, INT_SIZE_HALF} : return unsigned'(data[15:0]);
      {1'b1, INT_SIZE_WORD} : return data;
      default: return 0;
    endcase
  endfunction

  function logic[3:0] size_to_bytemask(input int_size_t size);
    case (size)
      INT_SIZE_BYTE: return 4'b0001;
      INT_SIZE_HALF: return 4'b0011;
      INT_SIZE_WORD: return 4'b1111;
      default: return 0;
    endcase
  endfunction
endmodule
