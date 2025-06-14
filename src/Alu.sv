import Types::*;

module Alu (
    input bit [31:0] in_a,
    input bit [31:0] in_b,
    input alu_mode_t mode,
    output bit [31:0] out
);
  bit [4:0] displacement;
  assign displacement = in_b[4:0];

  always_comb begin
    unique casez ({
      mode.operation
    })
      ALU_NULL: out = 0;
      ALU_ADD: out = in_a + in_b;
      ALU_SUB: out = in_a - in_b;
      ALU_SHIFT_LEFT_LOGICAL: out = in_a << displacement;
      ALU_SHIFT_RIGHT_LOGICAL: out = unsigned'(in_a) >> displacement;
      ALU_SHIFT_RIGHT_ARITHMETIC: out = signed'(in_a) >>> displacement;
      ALU_SET_LESS_THAN: begin
        if(mode.signedness == SIGNED)
          out = signed'(in_a) < signed'(in_b) ? 1 : 0;
        else
          out = unsigned'(in_a) < unsigned'(in_b) ? 1 : 0;
      end
      ALU_XOR: out = in_a ^ in_b;
      ALU_AND: out = in_a & in_b;
      ALU_OR: out = in_a | in_b;
      ALU_EQ: begin
        out = (in_a == in_b) ? 1 : 0;
      end
      default: begin
        out = 0;
      end
    endcase
  end
`ifdef __DUMP_STATE__
  task automatic dump_state();
    $display(" - ALU: %08x %s %08x = %x", in_a, getOpSymbol(mode.operation), in_b, out);
  endtask
  function automatic string getOpSymbol(alu_op_t op);
    unique case (op)
      ALU_NULL: return "NULL";
      ALU_ADD: return "+";
      ALU_SUB: return "-";
      ALU_SHIFT_LEFT_LOGICAL: return "<<";
      ALU_SHIFT_RIGHT_LOGICAL: return ">>";
      ALU_SHIFT_RIGHT_ARITHMETIC: return ">>>";
      ALU_SET_LESS_THAN: return "<";
      ALU_XOR: return "^";
      ALU_AND: return "&";
      ALU_OR: return "|";
      default: return "UNKNOWN";
    endcase
  endfunction
`endif // __DUMP_STATE__
endmodule
