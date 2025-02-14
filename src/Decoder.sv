import Types::*;

module Decoder (
    input word ir,
    output int len,
    output bit [6:0] opcode,
    output bit [4:0] rd,
    output bit [4:0] rs1,
    output bit [4:0] rs2,
    output word imm,
    output bit [2:0] f3,
    output bit [6:0] f7
);
  typedef enum {
    NULL,
    FORMAT_R,
    FORMAT_I,
    FORMAT_S,
    FORMAT_B,
    FORMAT_U,
    FORMAT_J
  } format_t;

  bit signed [31:0] rtype_imm;
  bit signed [31:0] itype_imm;
  bit signed [31:0] stype_imm;
  bit signed [31:0] btype_imm;
  bit signed [31:0] utype_imm;
  bit signed [31:0] jtype_imm;

  bit enable_rd, enable_rs1, enable_rs2;
  bit f3_valid, f7_valid;
  format_t format;

  assign rd = enable_rd ? ir[11:7] : 0;
  assign rs1 = enable_rs1 ? ir[19:15] : 0;
  assign rs2 = enable_rs2 ? ir[24:20] : 0;
  assign rtype_imm = 0;
  assign itype_imm = {{20{ir[31]}}, ir[31:20]};
  assign stype_imm = {{20{ir[31]}}, ir[31:25], ir[11:7]};
  assign btype_imm = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
  assign utype_imm = {ir[31:12], 12'b0};
  assign jtype_imm = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:25], ir[24:21], 1'b0};
  assign f3 = f3_valid ? ir[14:12] : 0;
  assign f7 = f7_valid ? ir[31:25] : 0;

  assign opcode = ir[6:0];
  assign len = 4;

  always_comb begin
    case (opcode)
      OP_ALU:    format = FORMAT_R;
      OP_ALUI:   format = FORMAT_I;
      OP_LOAD:   format = FORMAT_I;
      OP_STORE:  format = FORMAT_S;
      OP_BRANCH: format = FORMAT_B;
      OP_JAL:    format = FORMAT_J;
      OP_JALR:   format = FORMAT_I;
      OP_LUI:    format = FORMAT_U;
      OP_AUIPC:  format = FORMAT_U;
      default:   format = NULL;
    endcase
    case (format)
      FORMAT_R: imm = rtype_imm;
      FORMAT_I: imm = itype_imm;
      FORMAT_S: imm = stype_imm;
      FORMAT_B: imm = btype_imm;
      FORMAT_U: imm = utype_imm;
      FORMAT_J: imm = jtype_imm;
      default:  imm = 0;
    endcase
    case (format)
      FORMAT_R: enable_rd = 1;
      FORMAT_I: enable_rd = 1;
      FORMAT_S: enable_rd = 0;
      FORMAT_B: enable_rd = 0;
      FORMAT_U: enable_rd = 1;
      FORMAT_J: enable_rd = 1;
      default:  enable_rd = 0;
    endcase
    case (format)
      FORMAT_R: enable_rs1 = 1;
      FORMAT_I: enable_rs1 = 1;
      FORMAT_S: enable_rs1 = 1;
      FORMAT_B: enable_rs1 = 1;
      FORMAT_U: enable_rs1 = 0;
      FORMAT_J: enable_rs1 = 0;
      default:  enable_rs1 = 0;
    endcase
    case (format)
      FORMAT_R: enable_rs2 = 1;
      FORMAT_I: enable_rs2 = 0;
      FORMAT_S: enable_rs2 = 1;
      FORMAT_B: enable_rs2 = 1;
      FORMAT_U: enable_rs2 = 0;
      FORMAT_J: enable_rs2 = 0;
      default:  enable_rs2 = 0;
    endcase
    case (format)
      FORMAT_R: f3_valid = 1;
      FORMAT_I: f3_valid = 1;
      FORMAT_S: f3_valid = 1;
      FORMAT_B: f3_valid = 1;
      FORMAT_U: f3_valid = 0;
      FORMAT_J: f3_valid = 0;
      default:  f3_valid = 0;
    endcase
    case (format)
      FORMAT_R: f7_valid = 1;
      FORMAT_I: f7_valid = 0;
      FORMAT_S: f7_valid = 0;
      FORMAT_B: f7_valid = 0;
      FORMAT_U: f7_valid = 0;
      FORMAT_J: f7_valid = 0;
      default:  f7_valid = 0;
    endcase

    if (format == NULL) begin
      $display("Unknown encoding for opcode: %b", opcode);
    end
  end
endmodule
