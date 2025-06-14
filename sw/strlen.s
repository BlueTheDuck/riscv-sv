.section .text
.global strlen

# size_t strlen(const char *s) {
#   const char *e = s;
#   while (*e != '\0') e++;
#   return e - s;
# }
strlen:
  mv   a5, a0
1:
  lbu  a4, 0(a5)
  bnez a4, 2f
  sub  a0, a5, a0
  ret
2:
  addi a5, a5, 1
  j    1b
