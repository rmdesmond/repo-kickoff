// Unit tests for the {{NAME}} library, in GoogleTest, run by CTest.
#include <gtest/gtest.h>

#include <cctype>
#include <string>

#include "{{NAME_SNAKE}}/{{NAME_SNAKE}}.hpp"

TEST(Version, StartsWithADigit)
{
    const std::string v = {{NAME_SNAKE}}::version();
    ASSERT_FALSE(v.empty());
    EXPECT_TRUE(std::isdigit(static_cast<unsigned char>(v[0])));
}

TEST(Placeholder, NamesTheLibrary)
{
    EXPECT_EQ({{NAME_SNAKE}}::placeholder(),
              "{{NAME}}: placeholder - nothing implemented yet");
}
