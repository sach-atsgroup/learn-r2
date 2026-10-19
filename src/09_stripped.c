/* Module 9 target: built -O2 and stripped. No symbols, a jump table, inlining. */
#include <stdio.h>
#include <string.h>

__attribute__((noinline)) static int dispatch(char c) {
	switch (c) {
	case 'A': return 1;
	case 'B': return 2;
	case 'C': return 3;
	case 'D': return 4;
	case 'E': return 5;
	case 'F': return 6;
	case 'G': return 7;
	case 'H': return 8;
	case 'I': return 9;
	case 'J': return 10;
	case 'K': return 11;
	case 'L': return 12;
	default:  return 0;
	}
}

int main(int argc, char **argv) {
	if (argc != 2) {
		puts("usage: 09_stripped <key>");
		return 2;
	}
	const char *s = argv[1];

	if (strlen(s) != 12)
		return 1;
	if (dispatch(s[0]) != 7)
		return 1;
	if (s[11] != '!')
		return 1;

	unsigned sum = 0;
	for (int i = 0; i < 12; i++)
		sum += (unsigned char)s[i];
	if (sum != 0x3b4)
		return 1;

	puts("STRIPPED CLEARED");
	return 0;
}
