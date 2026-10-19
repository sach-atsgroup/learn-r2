/* Module 1 target: a handful of named functions with different shapes. */
#include <stdio.h>
#include <string.h>

static int leaf(int x) { return x + 1; }

static int two_blocks(int x) { return x < 0 ? -x : x; }

static int four_blocks(int x) {
	if (x & 1) {
		if (x > 100) return 3;
		return 2;
	}
	if (x > 100) return 1;
	return 0;
}

static int loopy(const char *s) {
	int n = 0;
	while (*s) {
		if (*s == 'a') n++;
		s++;
	}
	return n;
}

int main(int argc, char **argv) {
	int acc = leaf(argc) + two_blocks(-argc) + four_blocks(argc);
	if (argc > 1) acc += loopy(argv[1]);
	printf("acc=%d\n", acc);
	return 0;
}
