/* Capstone: stripped, optimized, obfuscated strings, and a gate that cannot be
 * satisfied on this machine - only patched. */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static unsigned char secret[14] = {
	0xf0, 0x85, 0xb7, 0xbb, 0x36, 0x6a, 0x65, 0x3e,
	0xc3, 0xff, 0xe4, 0xd6, 0x4d, 0x01
};

__attribute__((noinline)) static void unmask(void) {
	for (int i = 0; i < 14; i++)
		secret[i] ^= (unsigned char)(i * 29 + 0xa7);
}

/* Reads a licence file that does not exist. Returns -1 forever. */
__attribute__((noinline)) static int licence_ok(void) {
	FILE *f = fopen("/etc/wave/licence.key", "rb");
	if (!f)
		return -1;
	char buf[8] = {0};
	size_t n = fread(buf, 1, sizeof buf - 1, f);
	fclose(f);
	if (n < 4)
		return -1;
	return (memcmp(buf, "WAVE", 4) == 0) ? 0x1337 : -1;
}

int main(int argc, char **argv) {
	if (argc != 2) {
		puts("usage: capstone <secret>");
		return 2;
	}
	unmask();
	if (strlen(argv[1]) != 14 || memcmp(argv[1], secret, 14) != 0) {
		puts("STAGE 1 FAILED");
		return 1;
	}
	if (licence_ok() != 0x1337) {
		puts("STAGE 2 FAILED: no licence");
		return 1;
	}
	puts("WAVE CAPSTONE CLEARED");
	return 0;
}
