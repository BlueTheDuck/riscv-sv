#include "bsp.h"

#include <string.h>

///   (skip 4 kilobytes, process 512 bytes, output 16 characters per line)
/// > hexdump -s 4k -n 512 -e '"%08_ax: " 16/1 "%1c " "\n"' ram.bin
///   00001000: a b c d e f g h i j k l m n o p
///   00001010: q r s t u v w x y z   A B C D E
///   00001020: F G H I J K L M N O P Q R S T U
///   00001030: V W X Y Z
///   00001040:
///   *
///   00001100: n o p q r s t u v w x y z a b c
///   00001110: d e f g h i j k l m   N O P Q R
///   00001120: S T U V W X Y Z A B C D E F G H
///   00001130: I J K L M
///   00001140:
///   *
void rot13(const char *string, char *encoded) {
  uint32_t len = strlen(string);
  encoded[len] = '\0'; // Null-terminate the encoded string
  for (size_t i = 0; i < len; i++) {
    if (string[i] >= 'a' && string[i] <= 'm') {
      encoded[i] = string[i] + 13;
    } else if (string[i] >= 'n' && string[i] <= 'z') {
      encoded[i] = string[i] - 13;
    } else if (string[i] >= 'A' && string[i] <= 'M') {
      encoded[i] = string[i] + 13;
    } else if (string[i] >= 'N' && string[i] <= 'Z') {
      encoded[i] = string[i] - 13;
    } else {
      encoded[i] = string[i]; // Non-alphabetic characters remain unchanged
    }
  }
}

/// > hexdump -e '"%08_ax: " 4/4 "%8d " "\n"' ram.bin
///   00001000:        1        1        2        3
///   00001010:        5        8       13       21
///   00001020:       34       55       89      144
///   00001030:      233      377      610      987
///   00001040:     1597     2584     4181     6765
///   00001050:    10946    17711    28657    46368
///   00001060:    75025   121393   196418   317811
///   00001070:   514229   832040  1346269  2178309
void fibonacci(uint32_t fibos[32]) {
  fibos[0] = 1;
  fibos[1] = 1;
  for (uint32_t i = 2; i < 32; i++) {
    fibos[i] = fibos[i - 1] + fibos[i - 2];
  }
}

static const char str[] = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ";
uint32_t fibos[32] = {0};
char encoded[256] = {0};
char decoded[256] = {0};

uint32_t main() {
  fibonacci(fibos);
  rot13(str, encoded);
  rot13(encoded, decoded);
  return 0;
}
