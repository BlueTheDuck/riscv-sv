#!/bin/env python3

from dataclasses import dataclass
from enum import Enum
from typing import Dict, Literal
import sys

@dataclass
class Register():
  n: int

  def __format__(self, format_spec):
    alt_names = [ "zero", "ra", "sp",  "gp",  "tp", "t0", "t1", "t2", 
                  "s0",   "s1", "a0",  "a1",  "a2", "a3", "a4", "a5", 
                  "a6",   "a7", "s2",  "s3",  "s4", "s5", "s6", "s7", 
                  "s8",   "s9", "s10", "s11", "t3", "t4", "t5", "t6"]
    if '#' in format_spec:
      return alt_names[self.n]
    else:
      return f"x{self.n:1d}"
    
  def __eq__(self, other):
    if type(other) is int:
      return self.n == other
    elif type(other) is type(self):
      return self.n == self.other
    elif type(other) is str:
      this = f"{self}"
      this_alt = f"{self:#}"
      return this == other or this_alt == other      
    else:
      raise Exception(f"Invalid comparison between types Register and {type(other)!s}")
  

class Encoding(Enum):
  TYPE_R = "R"
  TYPE_I = "I"
  TYPE_S = "S"
  TYPE_B = "B"
  TYPE_U = "U"
  TYPE_J = "J"

def extract_opcode(word: int) -> Dict[str, int]:
  b65  = (word & 0b11_000_00) >> 5
  b432 = (word & 0b00_111_00) >> 2
  b01  =  word & 0b00_000_11
  if b01 != 0b11:
    return {"length": 16, "value": b01}
  elif b432 != 0b111:
    return {"length": 32, "value": (b65 << 3) | b432}
  else:
    raise Exception(">32b not suported")


class Instruction:
  word: int
  encoding: Encoding
  
  def __init__(self, word: int):
    self.word = word

  def opcode(self) -> int:
    if self.word & 0b11 != 3:
      return self.word & 0b11
    else:
      return self.word & 0b1111111
    
  def rd(self) -> int:
    return Register((self.word & 0x00000F80) >> 7)

  def rs1(self) -> int:
    return Register((self.word & 0x000F8000) >> 15)

  def rs2(self) -> int:
    return Register((self.word & 0x01F00000) >> 20)
  
  def f3(self) -> int:
    return (self.word & 0x00007000) >> 3 * 4
  
  def f7(self) -> int:
    return (self.word & 0xFE000000) >> 4 * 6 + 1

  def imm(self) -> int | None:
    sign = self.word & 0x80000000
    imm_val = 0
    if self.encoding == Encoding.TYPE_I:
      imm_val = (self.word & 0xFFF00000) >> 20
    elif self.encoding == Encoding.TYPE_S:
      imm4_0 = (self.word & 0x00000F80) >> 7
      imm11_5 = (self.word & 0xFE000000) >> 25
      imm_val = (imm11_5 << 5) | imm4_0
    elif self.encoding == Encoding.TYPE_B:
      imm11 = (self.word & 0x80000000) >> 31
      imm10_5 = (self.word & 0x7E000000) >> 25
      imm4_1 = (self.word & 0x00000F00) >> 8
      imm12 = (self.word & 0x00000080) >> 7
      imm_val = (imm11 << 12) | (imm10_5 << 5) | (imm4_1 << 1) | imm12
    elif self.encoding == Encoding.TYPE_U:
      imm_val = self.word & 0xFFFFF000
    elif self.encoding == Encoding.TYPE_J:
      imm20 = (self.word & 0x80000000) >> 31
      imm10_1 = (self.word & 0x7FE00000) >> 21
      imm11 = (self.word & 0x00100000) >> 20
      imm19_12 = (self.word & 0x000FF000) >> 12
      imm_val = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)
    else:
      imm_val = 0
    return -imm_val if sign else imm_val
  
  def decode(self) -> str:
    return f"{self.word:08X}"

class AluOpImm(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_I
    assert self.opcode() == 0b0010011
    
  def decode(self):
    mnemonics = [
      ["ADDI", "SUBI"],
       "SLLI",
       "SLTI",
       "SLTUI",
       "XORI",
      ["SRLI", "SRAI"],
       "ORI",
       "ANDI"
    ]
    mnemonic = mnemonics[self.f3()]
    if self.imm() == 0:
      return f"MV {self.rd():#}, {self.rs1():#}"
    elif self.rs1() == 0:
      return f"SET {self.rd():#}, {self.imm():X}"
    else:
      if type(mnemonic) is list:
        mnemonic = mnemonic[0] if self.f7() == 0 else mnemonic[1]
      return f"{mnemonic} {self.rd():#}, {self.rs1():#}, {self.imm()}"
  
class AluOp(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_R
    assert self.opcode() == 0b0110011
    
  def decode(self):
    nmemonics = [
      ["ADD", "SUB"],
       "SLL",
       "SLT",
       "SLTU",
       "XOR",
      ["SRL", "SRA"],
       "OR",
       "AND"
    ]
    nmemonic = nmemonics[self.f3()]

    if self.rs1() == 0 or self.rs2() == 0:
      rs = self.rs1() if self.rs1() !=0 else self.rs2()
      return f"MV {self.rd()}, {rs}"
    else:
      if type(nmemonic) is list:
        nmemonic = nmemonic[0] if self.f7() == 0 else nmemonic[1]
      return f"{nmemonic} {self.rd():#}, {self.rs1():#}, {self.rs2()}"

class Store(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_S
    assert self.opcode() == 0b0100011

  def nmemonic(self):
    ops = [
      "SB",
      "SH",
      "SW"
    ]
    return ops[self.f3()] or "S?"

  def decode(self):
    return f"{self.nmemonic()} {self.rs2():#}, {self.imm()}({self.rs1():#})"

class Load(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_I
  
  def decode(self):
    ops = [
      "LB",
      "LH",
      "LW",
      "L?",
      "LBU",
      "LHU"
    ]
    nmemonic = ops[self.f3()]
    return f"{nmemonic} {self.rd():#}, {self.imm()}({self.rs1():#})"

class Branch(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_B
  
  def decode(self):
    nmemonics = [
      "BEQ", "BNE", "B??", "B??"
      "BLT", "BGE", "BLTU", "BGEU"
    ]
    return f"{nmemonics[self.f3()]} {self.rs1():#}, {self.rs2():#}, {self.imm()}"

class Jalr(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_I
  
  def decode(self):
    if self.rd() == 0:
      return f"J {self.rs1():#}, {self.imm():X}"
    else:
      return f"JALR {self.rd():#}, {self.rs1():#}, {self.imm():X}"

class Jal(Instruction):
  def __init__(self, word):
    super().__init__(word)
    self.encoding = Encoding.TYPE_J
    assert self.opcode() == 0b1101111

  def decode(self):
    if self.rd() == 0:
      return f"J {self.imm():X}"
    else:
      return f"JAL {self.rd():#}, {self.imm():X}"

opcodes = {
  0:  Load,        1:  Instruction, 2:  Instruction, 3:  Instruction, 4:  AluOpImm,     5: Instruction, 6:  Instruction, 7:  Instruction,
  8:  Store,       9:  Instruction, 10: Instruction, 11: Instruction, 12: AluOp,       13: Instruction, 14: Instruction, 15: Instruction,
  16: Instruction, 17: Instruction, 18: Instruction, 19: Instruction, 20: Branch,      21: Instruction, 22: Instruction, 23: Instruction, 
  24: Instruction, 25: Jalr,        26: Instruction, 27: Jal,         28: Instruction, 29: Instruction, 30: Instruction, 31: Instruction
}

def parse(s: str) -> Instruction:
  ins = int(s, base=16)

  opcode_info = extract_opcode(ins)
  opcode = opcode_info["value"]
  length = opcode_info["length"]

  ins_word = opcodes[opcode](ins)

  return ins_word

if __name__ == "__main__":
  for input_word in sys.stdin:
    input_word = input_word.strip()
    try:
      ins = parse(input_word)
      print(f"{ins.decode()}", file=sys.stdout, flush=True)
    except Exception as e:
      print(f"Error {e!s}", file=sys.stderr, flush=True)
      print(f"{input_word} ?")
  exit(0)
