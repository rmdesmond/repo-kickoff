// Unit tests for the {{NAME}} library, in GoogleTest, run by CTest. They
// call the C functions directly: {{NAME_SNAKE}}.h wraps them in extern "C".
#include <gtest/gtest.h>

#include <cctype>

#include "{{NAME_SNAKE}}.h"

TEST(Version, StartsWithADigit)
{
	const char *version = {{NAME_SNAKE}}_version();
	ASSERT_NE(version, nullptr);
	EXPECT_TRUE(std::isdigit(static_cast<unsigned char>(version[0])));
}

TEST(Placeholder, NamesTheLibrary)
{
	EXPECT_STREQ({{NAME_SNAKE}}_placeholder(),
		     "{{NAME}}: placeholder - nothing implemented yet");
}
