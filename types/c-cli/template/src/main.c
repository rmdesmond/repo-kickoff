/* {{NAME}}: the program's entry point. The logic lives in {{NAME_SNAKE}}.c. */
#include <stdio.h>

#include "{{NAME_SNAKE}}.h"

int main(int argc, char *argv[])
{
	return {{NAME_SNAKE}}_run(argc, argv, stdout, stderr);
}
