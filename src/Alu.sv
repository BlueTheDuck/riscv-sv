module Alu (
    input Types::int32_t in_a,
    input Types::int32_t in_b,
    input Types::alu_mode_t mode,
    output Types::int32_t out
);
  import Types::*;

  bit [4:0] displacement;
  assign displacement = in_b[4:0];

  always_comb begin
    unique case (mode.operation)
      ALU_NULL: out = 0;
      ALU_ADD: out = in_a + in_b;
      ALU_SUB: out = in_a - in_b;
      ALU_SHIFT_LEFT: begin
        if(mode.signedness == UNSIGNED)
          out = in_a << displacement;
        else
          $fatal("ALU_SHIFT_LEFT arithmetic (signed) is not supported");
      end
      ALU_SHIFT_RIGHT: begin
        if (mode.signedness == UNSIGNED)
          out = unsigned'(in_a) >> displacement;
        else
          out = signed'(in_a) >>> displacement;
      end
      ALU_SET_LESS_THAN: begin
        if (mode.signedness == SIGNED)
          out = signed'(in_a) < signed'(in_b) ? 1 : 0;
        else
          out = unsigned'(in_a) < unsigned'(in_b) ? 1 : 0;
      end
      ALU_XOR: out = in_a ^ in_b;
      ALU_AND: out = in_a & in_b;
      ALU_OR: out = in_a | in_b;
      ALU_EQ: out = (in_a == in_b) ? 1 : 0;

      default: out = 0;
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
      ALU_SHIFT_LEFT: return "<<";
      ALU_SHIFT_RIGHT: return ">>";
      ALU_SET_LESS_THAN: return "<";
      ALU_XOR: return "^";
      ALU_AND: return "&";
      ALU_OR: return "|";
      default: return "UNKNOWN";
    endcase
  endfunction
`endif  // __DUMP_STATE__
endmodule
