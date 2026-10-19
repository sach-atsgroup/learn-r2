/* Module 5 target: the secret is never printed and never compared in cleartext
 * until decode() has run. Emulate decode() instead of executing the program. */
#include <stdio.h>
#include <string.h>

static unsigned char box[16] = {
	0x1e, 0x3b, 0x3c, 0xce, 0xd0, 0xcf, 0xec, 0xf3,
	0x90, 0x8f, 0x9c, 0xa6, 0xbb, 0x5b, 0x67, 0x2c
};

static void decode(void) {
	for (int i = 0; i < 16; i++)
		box[i] ^= (unsigned char)(i * 13 + 0x5b);
}

int main(int argc, char **argv) {
	if (argc != 2) {
		puts("usage: 05_xorbox <secret>");
		return 2;
	}
	decode();
	if (strlen(argv[1]) == 16 && memcmp(argv[1], box, 16) == 0) {
		puts("BOX OPENED");
		return 0;
	}
	puts("BOX SHUT");
	return 1;
}
