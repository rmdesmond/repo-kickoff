/*
 * {{NAME}}: the library's public interface.
 *
 * Every public name starts with {{NAME_SNAKE}}_. The extern "C" block lets
 * C++ include this header.
 */
#ifndef {{NAME_SNAKE}}_H
#define {{NAME_SNAKE}}_H

#ifdef __cplusplus
extern "C" {
#endif

/* The library's version, for example "0.1.0". */
const char *{{NAME_SNAKE}}_version(void);

/*
 * A placeholder for the library's real work: returns the line
 * "{{NAME}}: placeholder - nothing implemented yet". Replace it.
 */
const char *{{NAME_SNAKE}}_placeholder(void);

#ifdef __cplusplus
}
#endif

#endif /* {{NAME_SNAKE}}_H */
