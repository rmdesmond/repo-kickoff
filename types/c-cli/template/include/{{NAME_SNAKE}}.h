/*
 * {{NAME}}: the program's logic, as a small C library.
 *
 * main.c only calls {{NAME_SNAKE}}_run(); the unit tests call these
 * functions directly. The extern "C" block lets C++ (the GoogleTest tests)
 * include this header.
 */
#ifndef {{NAME_SNAKE}}_H
#define {{NAME_SNAKE}}_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* The program's version, for example "0.1.0". */
const char *{{NAME_SNAKE}}_version(void);

/* Writes the usage text to stream. */
void {{NAME_SNAKE}}_usage(FILE *stream);

/*
 * Runs the program with the given arguments (argv[0] is the program name),
 * writing normal output to out and errors to err. Returns the exit status:
 * 0 on success, 2 for a usage error.
 */
int {{NAME_SNAKE}}_run(int argc, char *argv[], FILE *out, FILE *err);

#ifdef __cplusplus
}
#endif

#endif /* {{NAME_SNAKE}}_H */
