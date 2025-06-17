#!/bin/env python3


from dataclasses import dataclass
import sys


@dataclass
class Register():
  n: int

  def __format__(self, format_spec):
    alt_names = [ "Z", "RA", "SP",  "GP",  "TP", "t0", "t1", "t2", 
                  "s0",   "s1", "a0",  "a1",  "a2", "a3", "a4", "a5", 
                  "a6",   "a7", "s2",  "s3",  "s4", "s5", "s6", "s7", 
                  "s8",   "s9", "s10", "s11", "t3", "t4", "t5", "t6"]
    if '#' in format_spec:
      return alt_names[self.n]
    else:
      return f"x{self.n:1d}"
    
  def __eq__(self, other):
    if type(other) is type(self):
      return self.n == other.n
    
    return False
  

def extract_opcode(word: int):
  b65  = (word & 0b11_000_00) >> 5
  b432 = (word & 0b00_111_00) >> 2
  b01  =  word & 0b00_000_11
  if b01 != 0b11:
    return {"length": 16, "value": b01}
  elif b432 != 0b111:
    return {"length": 32, "value": (word & 0b1111111)}
  else:
    raise Exception(">32b not suported")

def sign_extend(value: int, initial_size: int) -> int:
  negative = 0xFFFFFFFF
  initial_sign_bit_mask = 1 << (initial_size-1)
  if value & initial_sign_bit_mask:
    top_bits = negative << initial_size
    return (value | top_bits) & negative
  else:
    return value


class Instruction:
  def __init__(self, word: int):
    self.word = word

  def decode(self):
    opcode = self.opcode()
    if opcode in opcodes:
      return opcodes[opcode](self.word)
    else:
      raise Exception(f"Unsupported opcode {opcode:02x} in instruction {self.word:08x}")

  def opcode(self) -> int:
    if self.word & 0b11 != 3:
      return self.word & 0b11
    else:
      return self.word & 0b1111111
    
  def rd(self) -> Register:
    return Register((self.word >> 7) & 0b11111)

  def rs1(self) -> Register:
    return Register((self.word >> 15) & 0b11111)

  def rs2(self) -> Register:
    return Register((self.word >> 20) & 0b11111)

  def f3(self) -> int:
    return (self.word & 0x00007000) >> 3 * 4
  
  def f7(self) -> int:
    return (self.word & 0xFE000000) >> 4 * 6 + 1

class InstructionRegisterEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)

class InstructionImmediateEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)

  def immediate(self) -> int:
    return (self.f7() << 5) | (self.rs2().n)

class InstructionStoreEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)
  
  def immediate(self) -> int:
    return (self.f7() << 5) | (self.rd().n)

class InstructionBranchEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)
  
  def immediate(self) -> int:
    imm4_1  = self.rd().n & 0b11110;
    imm11  = 0x800 if (0 != self.rd().n & 0b00001) else 0;
    imm10_5  = self.f7() & 0b0111111;
    imm12  = 0x1000 if (0 != self.f7() & 0b1000000) else 0;
    return (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | imm4_1
  
class InstructionUpperEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)
  
  def immediate(self) -> int:
    return self.word & 0xFFFFF000
  
class InstructionJumpEncoded(Instruction):
  def __init__(self, word: int):
    super().__init__(word)
  
  def immediate(self) -> int:
    imm20 = (self.word & 0x80000000) >> 31
    imm10_1 = (self.word & 0x7FE00000) >> 21
    imm11 = (self.word & 0x00100000) >> 20
    imm19_12 = (self.word & 0x000FF000) >> 12
    return (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)

class OpcodeLoad(InstructionImmediateEncoded):
  MNEMONICS = [
    "LB", # 0
    "LH", # 1
    "LW", # 2
    "--",
    "LBU",# 4 
    "LHU",# 5
    "---",
    "---",
    "---"
  ]
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    mnemonic = self.MNEMONICS[self.f3()]

    return f"{mnemonic} {self.rd():#}, 0x{self.immediate():03}({self.rs1():#})"

class OpcodeStore(InstructionStoreEncoded):
  MNEMONICS = [
    "SB", # 0
    "SH", # 1
    "SW", # 2
    "---",
    "---",
    "---",
    "---",
    "---",
  ]
  
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    mnemonic = self.MNEMONICS[self.f3()]
    return f"{mnemonic} {self.rs2():#}, 0x{self.immediate():03X}({self.rs1():#})"

class OpcodeAluOpImm(InstructionImmediateEncoded):
  MNEMONICS = [
    "ADD", # 0
    "SLL", # 1
    "SLT", # 2
    "SLTU", # 3
    "XOR", # 4
    "SRL", # 5
    "OR", # 6
    "AND", # 7
  ]
  MNEMONICS_F7 = {
    5: "SRA"
  }
  
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:

    if '#' in format_spec:
      if self.is_canonical_nop():
        return "NOP"
      elif self.is_move():
        return f"MV {self.rd():#}, {self.rs1():#}"
      elif self.is_load_imm():
        imm_extended = sign_extend(self.immediate(), 12)
        return f"LI {self.rd():#}, 0x{imm_extended:08X}"
      else:
        return self.format_normal()
    else:
      return self.format_normal()
    
  def format_normal(self) -> str:
    mnemonic = None
    if self.is_alternative_op():
      mnemonic = self.MNEMONICS_F7[self.f3()]
    else:
      mnemonic = self.MNEMONICS[self.f3()]
    if self.uses_5bit_imm():
      truncated_imm = self.immediate() & 0b11111
      return f"{mnemonic} {self.rd():#}, {self.rs1():#}, {truncated_imm}"
    else:
      return f"{mnemonic} {self.rd():#}, {self.rs1():#}, 0x{self.immediate():03X}"

  def uses_5bit_imm(self) -> bool:
    return self.f3() in [1, 5]

  def is_canonical_nop(self) -> bool:
    return self.is_move() and self.rd() == Register(0) and self.rs1() == Register(0)
  
  def is_move(self) -> bool:
    return self.is_add() and self.immediate() == 0
  
  def is_load_imm(self) -> bool:
    return self.is_add() and self.rs1() == Register(0)
  
  def is_add(self) -> bool:
    return self.f3() == 0
  
  def is_alternative_op(self) -> bool:
    alt_bit_set = self.f7() & 0x20 != 0
    alt_mnemonic = self.MNEMONICS_F7.get(self.f3(), None)
    return alt_mnemonic is not None and alt_bit_set
    
class OpcodeAluOp(InstructionRegisterEncoded):
  MNEMONICS = [
    "ADD", # 0
    "SLL", # 1
    "SLT", # 2
    "SLTU", # 3
    "XOR", # 4
    "SRL", # 5
    "OR", # 6
    "AND", # 7
  ]
  MNEMONICS_F7 = {
    0: "SUB",
    5: "SRA"
  }
  
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    mnemonic = None
    if self.is_alternative_op():
      mnemonic = self.MNEMONICS_F7[self.f3()]
    else:
      mnemonic = self.MNEMONICS[self.f3()]

    return f"{mnemonic} {self.rd():#}, {self.rs1():#}, {self.rs2():#}"

  def is_alternative_op(self) -> bool:
    alt_bit_set = self.f7() & 0x20 != 0
    alt_mnemonic = self.MNEMONICS_F7.get(self.f3(), None)
    return alt_mnemonic is not None and alt_bit_set

class OpcodeBranch(InstructionBranchEncoded):
  MNEMONICS = [
    "BEQ",
    "BNE",
    "---",
    "---",
    "BLT",
    "BGE",
    "BLTU",
    "BGEU",
    "---",
    "---"
  ]
  MNEMONICS_ZERO = {
    0: "BEQZ",
    1: "BNEZ",
    4: "BLTZ",
    5: "BGEZ",
  }
  
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    if '#' in format_spec and self.compares_zero():
      mnemonic = self.MNEMONICS_ZERO.get(self.f3(), None)
      return f"{mnemonic} {self.rs1():#}, 0x{self.immediate():03X}"
    else:
      mnemonic = self.MNEMONICS[self.f3()]
      return f"{mnemonic} {self.rs1():#}, {self.rs2():#}, 0x{self.immediate():03X}"

  def compares_zero(self) -> bool:
    return self.rs2() == Register(0) and self.f3() in self.MNEMONICS_ZERO

class OpcodeJalr(InstructionImmediateEncoded):
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    if '#' in format_spec and self.is_ret():
      return "RET"
    else:
      return f"JALR {self.rd():#}, {self.rs1():#}, 0x{self.immediate():03X}"
  
  def is_ret(self):
    return self.rd() == Register(0) and self.rs1() == Register(1) and self.immediate() == 0

class OpcodeLui(InstructionUpperEncoded):
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    return f"LUI {self.rd():#}, 0x{self.immediate():05X}"

class OpcodeAuipc(InstructionUpperEncoded):
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    return f"AUIPC {self.rd():#}, 0x{self.immediate():05X}"
  
class OpcodeJal(InstructionJumpEncoded):
  def __init__(self, word: int):
    super().__init__(word)
  
  def __format__(self, format_spec: str) -> str:
    return f"JAL {self.rd():#}, 0x{self.immediate():05X}"

class OpcodeSystem(InstructionImmediateEncoded):

  def __init__(self, word: int):
    super().__init__(word)

  def __format__(self, format_spec: str) -> str:
    if self.f3() == 0 and self.immediate() == 0 and self.rd() == Register(0) and self.rs1() == Register(0):
      return "ECALL"
    elif self.f3() == 0 and self.immediate() == 1 and self.rd() == Register(0) and self.rs1() == Register(0):
      return "EBREAK"
    else:
      raise Exception("Unknown system instruction")

opcodes = {
    0b0000011: OpcodeLoad,
    0b0100011: OpcodeStore,
    0b0010011: OpcodeAluOpImm,
    0b0110011: OpcodeAluOp,
    0b1100011: OpcodeBranch,
    0b1100111: OpcodeJalr,
    0b0110111: OpcodeLui,
    0b0010111: OpcodeAuipc,
    0b1101111: OpcodeJal,
    0b1110011: OpcodeSystem,
}

def parse(s: str):
  ins = int(s, base=16)

  opcode_info = extract_opcode(ins)
  instruction_index = opcode_info["value"]
  length = opcode_info["length"]

  ins_encoding = opcodes[instruction_index]
  if ins_encoding is None:
    raise Exception(f"Unsupported opcode {instruction_index:02x} in instruction {s}")

  return ins_encoding(ins)

if __name__ == "__main__":
  for input_word in sys.stdin:
    input_word = input_word.strip()
    try:
      ins = parse(input_word)
      print(f"{ins:#}", file=sys.stdout, flush=True)
    except Exception as e:
      print(f"Error {e!s}", file=sys.stderr, flush=True)
      print(f"{input_word}", file=sys.stdout, flush=True)
  exit(0)
