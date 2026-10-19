/* Module 7 target: patch a copy of the built binary so it exits 0. */
#include <stdio.h>

__attribute__((noinline)) static int days_left(void) { return -41; }

int main(void) {
	if (days_left() <= 0) {
		puts("TRIAL EXPIRED");
		return 1;
	}
	puts("WAVE UNLOCKED");
	return 0;
}
