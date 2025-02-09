module Alu (
    input  bit [31:0] in_a,
    input  bit [31:0] in_b,
    input  bit [ 2:0] op3,
    input  bit [ 6:0] op7,
    output bit [31:0] out
);
  always_comb begin
    /*0: add/sub
      1: sll
      2: slt
      3: sltu
      4: xor
      5: srl/sra
      6: or
      7: and
      */
    case (op3)
      3'b000:  out = in_a + in_b;  // add
      3'b001:  out = in_a << in_b[4:0];  // sll
      3'b010:  out = $signed(in_a) < $signed(in_b) ? 32'b1 : 32'b0;  // slt
      3'b011:  out = in_a < in_b ? 32'b1 : 32'b0;  // sltu
      3'b100:  out = in_a ^ in_b;  // xor
      3'b101:  out = in_a >> in_b[4:0];  // srl
      3'b110:  out = in_a | in_b;  // or
      3'b111:  out = in_a & in_b;  // and
      default: out = 32'b0;
    endcase
  end
  task automatic dump_state();
    $display(" - ALU: %08x %s %08x = %x", in_a, getOpSymbol(op3), in_b, out);
  endtask
  function automatic string getOpSymbol(bit [2:0] op3);
    case (op3)
      3'b000:  return "+";
      3'b001:  return "<<";
      3'b010:  return "<";
      3'b011:  return "<";
      3'b100:  return "^";
      3'b101:  return ">>";
      3'b110:  return "|";
      3'b111:  return "&";
      default: return "??";
    endcase
  endfunction
endmodule
