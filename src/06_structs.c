/* Module 6 target: recover the layout from the offsets the code uses. */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

struct robot {
	uint32_t id;         /* +0x00 */
	uint8_t  mode;       /* +0x04 */
	char     name[16];   /* +0x05 */
	double   battery;    /* padded to 8 */
	uint16_t errors;
	uint64_t uptime_ms;
};

__attribute__((noinline)) uint32_t get_id(const struct robot *r) { return r->id; }
__attribute__((noinline)) uint8_t get_mode(const struct robot *r) { return r->mode; }
__attribute__((noinline)) const char *get_name(const struct robot *r) { return r->name; }
__attribute__((noinline)) double get_battery(const struct robot *r) { return r->battery; }
__attribute__((noinline)) uint16_t get_errors(const struct robot *r) { return r->errors; }
__attribute__((noinline)) uint64_t get_uptime(const struct robot *r) { return r->uptime_ms; }

__attribute__((noinline)) int is_degraded(const struct robot *r) {
	return r->battery < 20.0 || r->errors > 3;
}

int main(void) {
	struct robot r;
	memset(&r, 0, sizeof r);
	r.id = 7;
	r.mode = 2;
	strcpy(r.name, "advanced-01");
	r.battery = 55.5;
	r.errors = 1;
	r.uptime_ms = 123456;
	printf("%u %u %s %.1f %u %lu degraded=%d sizeof=%zu\n",
	       get_id(&r), get_mode(&r), get_name(&r), get_battery(&r),
	       get_errors(&r), (unsigned long)get_uptime(&r),
	       is_degraded(&r), sizeof(struct robot));
	return 0;
}
