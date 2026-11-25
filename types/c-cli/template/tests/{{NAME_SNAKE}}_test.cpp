// Unit tests for the {{NAME}} library, in GoogleTest. They call the C
// functions directly; {{NAME_SNAKE}}.h wraps them in extern "C".
#include <gtest/gtest.h>

#include <cstdio>
#include <string>
#include <vector>

#include "{{NAME_SNAKE}}.h"

namespace {

// Reads everything written to a temporary file.
std::string Contents(std::FILE *file)
{
	std::string text;
	std::rewind(file);
	int c;
	while ((c = std::fgetc(file)) != EOF) {
		text.push_back(static_cast<char>(c));
	}
	return text;
}

struct Result {
	int status;
	std::string out;
	std::string err;
};

// Runs the program's logic with the given arguments and captures its output.
// Not named Run: inside a TEST body, that name is testing::Test::Run.
Result RunProgram(std::vector<std::string> args)
{
	args.insert(args.begin(), "{{NAME}}");
	std::vector<char *> argv;
	for (std::string &arg : args) {
		argv.push_back(&arg[0]);
	}
	argv.push_back(nullptr);

	std::FILE *out = std::tmpfile();
	std::FILE *err = std::tmpfile();
	EXPECT_NE(out, nullptr);
	EXPECT_NE(err, nullptr);
	Result result;
	result.status = {{NAME_SNAKE}}_run(static_cast<int>(args.size()),
					   argv.data(), out, err);
	result.out = Contents(out);
	result.err = Contents(err);
	std::fclose(out);
	std::fclose(err);
	return result;
}

} // namespace

TEST(Run, PrintsThePlaceholderLine)
{
	Result r = RunProgram({});
	EXPECT_EQ(r.status, 0);
	EXPECT_EQ(r.out, "{{NAME}}: placeholder - nothing implemented yet\n");
	EXPECT_EQ(r.err, "");
}

TEST(Run, HelpPrintsUsage)
{
	for (const char *flag : {"--help", "-h"}) {
		Result r = RunProgram({flag});
		EXPECT_EQ(r.status, 0) << flag;
		EXPECT_EQ(r.out.rfind("Usage: {{NAME}}", 0), 0u) << flag;
	}
}

TEST(Run, VersionPrintsNameAndVersion)
{
	Result r = RunProgram({"--version"});
	EXPECT_EQ(r.status, 0);
	EXPECT_EQ(r.out, std::string("{{NAME}} ") + {{NAME_SNAKE}}_version() + "\n");
}

TEST(Run, RejectsAnUnknownArgument)
{
	Result r = RunProgram({"--nope"});
	EXPECT_EQ(r.status, 2);
	EXPECT_EQ(r.out, "");
	EXPECT_NE(r.err.find("unknown argument: --nope"), std::string::npos);
}

TEST(Version, IsNotEmpty)
{
	EXPECT_STRNE({{NAME_SNAKE}}_version(), "");
}
