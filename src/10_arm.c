/* Module 10 target: cross-built for aarch64, run under qemu-aarch64. */
#include <stdio.h>
#include <string.h>

static const unsigned char tbl[5] = { 0x7a, 0x12, 0x08, 0x7c, 0x7b };

__attribute__((noinline)) static int check(const char *s) {
	if (strlen(s) != 5)
		return 0;
	for (int i = 0; i < 5; i++) {
		unsigned char mask = (unsigned char)(i * 5 + 0x3b);
		if (((unsigned char)s[i] ^ mask) != tbl[i])
			return 0;
	}
	return 1;
}

int main(int argc, char **argv) {
	if (argc != 2) {
		puts("usage: 10_arm <key>");
		return 2;
	}
	if (check(argv[1])) {
		puts("ARM CLEARED");
		return 0;
	}
	puts("ARM REJECTED");
	return 1;
}
