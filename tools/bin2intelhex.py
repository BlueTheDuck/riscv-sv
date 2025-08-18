#!/bin/env python3
import argparse

def checksum(word_size: int, address: int, kind: int, data: bytes) -> int:
  assert kind in [0, 1]
  assert word_size in [1, 4]
  total_sum = word_size + sum(address.to_bytes(length=2)) + kind +  sum(data)
  lsb = total_sum.to_bytes(length=4)[-1]
  return (~lsb + 1) & 0xFF

parser = argparse.ArgumentParser(description="Convert binary file to Intel HEX format.")
parser.add_argument("input_file", type=str, help="Path to the input binary file.")
parser.add_argument("word_size", type=int, choices=[8, 32], help="Word size: 8 or 32.")
args = parser.parse_args()

output_file = None
if args.input_file.endswith(".bin"):
  output_file = args.input_file[:-4] + ".hex"
else:
  output_file = args.input_file + ".hex"

word_size = args.word_size >> 3

with open(output_file, "w") as output:
  with open(args.input_file, "rb") as input:
    addr = 0
    while True:
      data = input.read(word_size)
      if len(data) < word_size:
        break
      dump_data = data.hex()
      check = checksum(word_size, addr, 0, data)
      print(f":{word_size:02d}{addr:04x}00{dump_data}{check:02x}", file=output)
      addr += 1
  print(":00000001FF", file=output)
