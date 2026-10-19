/* Module 4 target: the password only exists in memory at runtime. */
#include <stdio.h>
#include <string.h>

static const unsigned char seed[10] = {
	0x73, 0x66, 0x24, 0x2e, 0x76, 0x50, 0x13, 0x17, 0x47, 0x58
};

static void derive(char *out) {
	for (int i = 0; i < 10; i++)
		out[i] = (char)(seed[i] ^ (unsigned char)(i * 3 + 0x11));
	out[10] = '\0';
}

int main(void) {
	char expected[16];
	char input[64];

	derive(expected);
	printf("password: ");
	fflush(stdout);
	if (!fgets(input, sizeof(input), stdin)) {
		puts("no input");
		return 2;
	}
	input[strcspn(input, "\n")] = '\0';

	if (strcmp(input, expected) == 0) {
		puts("GUARD PASSED");
		return 0;
	}
	puts("GUARD DENIED");
	return 1;
}
