// {{NAME}}: the program's logic, as a small C++ library.
//
// main.cpp only calls {{NAME_SNAKE}}::run(); the unit tests call these
// functions directly.
#ifndef {{NAME_SNAKE}}_{{NAME_SNAKE}}_HPP
#define {{NAME_SNAKE}}_{{NAME_SNAKE}}_HPP

#include <ostream>
#include <string>
#include <vector>

namespace {{NAME_SNAKE}} {

// The program's version, for example "0.1.0".
std::string version();

// Writes the usage text to out.
void usage(std::ostream &out);

// Runs the program with the given arguments (without the program name),
// writing normal output to out and errors to err. Returns the exit status:
// 0 on success, 2 for a usage error.
int run(const std::vector<std::string> &args, std::ostream &out,
        std::ostream &err);

} // namespace {{NAME_SNAKE}}

#endif // {{NAME_SNAKE}}_{{NAME_SNAKE}}_HPP
