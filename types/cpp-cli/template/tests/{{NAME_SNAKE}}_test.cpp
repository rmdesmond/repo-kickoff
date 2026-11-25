// Unit tests for the {{NAME}} library, in GoogleTest. They call the library's
// functions directly, capturing their output in string streams.
#include <gtest/gtest.h>

#include <sstream>
#include <string>
#include <vector>

#include "{{NAME_SNAKE}}/{{NAME_SNAKE}}.hpp"

namespace {

struct Result {
    int status;
    std::string out;
    std::string err;
};

// Runs the program's logic with the given arguments and captures its output.
// Not named Run: inside a TEST body, that name is testing::Test::Run.
Result RunProgram(const std::vector<std::string> &args)
{
    std::ostringstream out;
    std::ostringstream err;
    Result result;
    result.status = {{NAME_SNAKE}}::run(args, out, err);
    result.out = out.str();
    result.err = err.str();
    return result;
}

} // namespace

TEST(Program, PrintsThePlaceholderLine)
{
    Result r = RunProgram({});
    EXPECT_EQ(r.status, 0);
    EXPECT_EQ(r.out, "{{NAME}}: placeholder - nothing implemented yet\n");
    EXPECT_EQ(r.err, "");
}

TEST(Program, HelpPrintsUsage)
{
    for (const char *flag : {"--help", "-h"}) {
        Result r = RunProgram({flag});
        EXPECT_EQ(r.status, 0) << flag;
        EXPECT_EQ(r.out.rfind("Usage: {{NAME}}", 0), 0u) << flag;
        EXPECT_EQ(r.err, "") << flag;
    }
}

TEST(Program, VersionPrintsNameAndVersion)
{
    Result r = RunProgram({"--version"});
    EXPECT_EQ(r.status, 0);
    EXPECT_EQ(r.out, "{{NAME}} " + {{NAME_SNAKE}}::version() + "\n");
}

TEST(Program, RejectsAnUnknownOption)
{
    Result r = RunProgram({"--nope"});
    EXPECT_EQ(r.status, 2);
    EXPECT_EQ(r.out, "");
    EXPECT_NE(r.err.find("unknown option: --nope"), std::string::npos);
    EXPECT_NE(r.err.find("Usage: {{NAME}}"), std::string::npos);
}

TEST(Program, RejectsAnUnexpectedArgument)
{
    Result r = RunProgram({"extra"});
    EXPECT_EQ(r.status, 2);
    EXPECT_EQ(r.out, "");
    EXPECT_NE(r.err.find("unexpected argument: extra"), std::string::npos);
}

TEST(Version, IsNotEmpty)
{
    EXPECT_FALSE({{NAME_SNAKE}}::version().empty());
}
