/* Module 6 target: a virtual call, like the Qt/C++ code in the WAVE repos. */
#include <cstdio>

class Tool {
public:
	virtual ~Tool() {}
	virtual int prepare() { return 1; }
	virtual int apply(int dose) { return dose; }
	virtual const char *name() const { return "tool"; }
};

class Sprayer : public Tool {
public:
	int prepare() override { return 2; }
	int apply(int dose) override { return dose * 3; }
	const char *name() const override { return "sprayer"; }
};

class UvLamp : public Tool {
public:
	int prepare() override { return 4; }
	int apply(int dose) override { return dose + 100; }
	const char *name() const override { return "uvlamp"; }
};

static int run(Tool *t, int dose) { return t->prepare() + t->apply(dose); }

int main(int argc, char **) {
	Sprayer s;
	UvLamp u;
	Tool *t = (argc > 1) ? static_cast<Tool *>(&u) : static_cast<Tool *>(&s);
	std::printf("%s -> %d\n", t->name(), run(t, 7));
	return 0;
}
