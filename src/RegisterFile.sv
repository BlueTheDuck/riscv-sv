import Types::word;

`default_nettype none

module RegisterFile (
    input bit clk,
    input logic [4:0] rd_index,
    input logic [4:0] rs1_index,
    input logic [4:0] rs2_index,

    input  Types::uint32_t rd_in,
    output Types::uint32_t rs1_out,
    output Types::uint32_t rs2_out,

    input bit rd_w
);
  word regs[32];

  initial regs[0] = 0;
  generate
    genvar i;
    for (i = 1; i < 32; i++) begin : GEN_REG_INIT
      initial regs[i] = 'x;
    end
  endgenerate

  assign rs1_out = rs1_index != 0 ? regs[rs1_index] : 0;
  assign rs2_out = rs2_index != 0 ? regs[rs2_index] : 0;

  always_ff @(negedge clk) begin
    if (rd_w && rd_index != 0) begin
      regs[rd_index] <= rd_in;
    end
  end

`ifdef __DUMP_STATE__
  final begin
    $display(" - Register bank: ");
    for (int r = 0; r < 32; r += 4) begin
      $display("R%02d..R%02d: %08x, %08x, %08x, %08x", r, r + 3, regs[r], regs[r+1], regs[r+2],
               regs[r+3]);
    end
  end
`endif  // __DUMP_STATE__
`ifdef PRETTY_WAVETRACE
  // verilator lint_off UNUSEDSIGNAL
  word zero, ra, sp, gp, tp;
  word t0, t1, t2, t3, t4, t5, t6;
  word s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11;
  word a0, a1, a2, a3, a4, a5, a6, a7;
  assign zero = regs[0];
  assign ra   = regs[1];
  assign sp   = regs[2];
  assign gp   = regs[3];
  assign tp   = regs[4];
  assign t0   = regs[5];
  assign t1   = regs[6];
  assign t2   = regs[7];
  assign s0   = regs[8];
  assign s1   = regs[9];
  assign a0   = regs[10];
  assign a1   = regs[11];
  assign a2   = regs[12];
  assign a3   = regs[13];
  assign a4   = regs[14];
  assign a5   = regs[15];
  assign a6   = regs[16];
  assign a7   = regs[17];
  assign s2   = regs[18];
  assign s3   = regs[19];
  assign s4   = regs[20];
  assign s5   = regs[21];
  assign s6   = regs[22];
  assign s7   = regs[23];
  assign s8   = regs[24];
  assign s9   = regs[25];
  assign s10  = regs[26];
  assign s11  = regs[27];
  assign t3   = regs[28];
  assign t4   = regs[29];
  assign t5   = regs[30];
  assign t6   = regs[31];
  // verilator lint_on UNUSEDSIGNAL
`endif

  task automatic set_registers(word [31:0] values[32]);
    for (int i = 0; i < 32; i++) begin
      regs[i] = values[i];
    end
  endtask
endmodule
