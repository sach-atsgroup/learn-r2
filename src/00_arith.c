/* Module 0 target: read these with objdump -d, not by running them. */
#include <stdio.h>

int triple_plus(int a, int b) { return a * 3 + b; }

int fork_in_road(int x) {
	if (x > 10)
		return x - 10;
	return x * 2;
}

int sixth_arg(int a, int b, int c, int d, int e, int f) {
	(void)a; (void)b; (void)c; (void)d;
	return e - f;
}

unsigned accumulate(unsigned n) {
	unsigned s = 0;
	for (unsigned i = 1; i <= n; i++)
		s += i * i;
	return s;
}

int main(void) {
	puts("nothing to see here; read the disassembly");
	return 0;
}
