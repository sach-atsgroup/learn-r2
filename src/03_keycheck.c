/* Module 3 target: solve the key by reading the disassembly only. */
#include <stdio.h>
#include <string.h>

/* The obfuscation table. px 16 bytes here and the key falls out. */
static const unsigned char tbl[16] = {
	0x78, 0x03, 0x67, 0x68, 0x72, 0x1b, 0x67, 0x04,
	0x37, 0x27, 0x3c, 0x47, 0x3d, 0xce, 0xad, 0xb2
};

static int length_gate(const char *s) { return strlen(s) == 16; }

static int prefix_gate(const char *s) { return s[0] == 'R' && s[1] == '2'; }

static int table_gate(const char *s) {
	for (int i = 0; i < 16; i++) {
		unsigned char mask = (unsigned char)(i * 7 + 0x2a);
		if (((unsigned char)s[i] ^ mask) != tbl[i])
			return 0;
	}
	return 1;
}

static int validate(const char *s) {
	if (!length_gate(s)) return 0;
	if (!prefix_gate(s)) return 0;
	if (!table_gate(s)) return 0;
	return 1;
}

int main(int argc, char **argv) {
	if (argc != 2) {
		puts("usage: 03_keycheck <key>");
		return 2;
	}
	if (validate(argv[1])) {
		puts("KEY ACCEPTED");
		return 0;
	}
	puts("KEY REJECTED");
	return 1;
}
