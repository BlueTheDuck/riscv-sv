| Opcode | F3  | Branches if...         |
|--------|-----|------------------------|
| BEQ    | 000 | rs1 == rs2             |
| BNE    | 001 | rs1 != rs2             |
| BLT    | 100 | rs1 < rs2              |
| BGE    | 101 | rs1 >= rs2             |
| BLTU   | 110 | rs1 < rs2 (unsigned)   |
| BGEU   | 111 | rs1 >= rs2 (unsigned)  |

F3 = XYZ =>
- X: 0 = equal (BEQ, BNE) / 1 = less than
- Y: 0 = signed / 1 = unsigned
- Z: 0 = normal / 1 = negated
