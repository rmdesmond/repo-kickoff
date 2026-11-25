// {{NAME}}: the program's entry point. The logic lives in {{NAME_SNAKE}}.cpp.
#include <iostream>
#include <string>
#include <vector>

#include "{{NAME_SNAKE}}/{{NAME_SNAKE}}.hpp"

int main(int argc, char *argv[])
{
    const std::vector<std::string> args(argv + 1, argv + argc);
    return {{NAME_SNAKE}}::run(args, std::cout, std::cerr);
}
