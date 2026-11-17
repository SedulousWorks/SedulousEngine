using System;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Mcp.Tests;

/// McpPathPolicy: every path argument was taken as given, so an agent could be led to write a
/// screenshot over any file, or import one from anywhere. The policy allows the project and the
/// folders the host names, nothing else.
class McpPathPolicyTests
{
	[Test]
	public static void ThePolicyAllowsTheProjectAndTheNamedFoldersNothingElse()
	{
		let policy = scope McpPathPolicy();
		let resolved = scope String();
		let refusal = scope String();
		Test.Assert(!policy.Check("/home/someone/project/a.png", resolved, refusal)); // nothing allowed yet
		policy.SetProject("/home/someone/project");
		policy.AddFolder("/home/someone/Downloads");
		Test.Assert(policy.Check("/home/someone/project/Sources/a.png", resolved, refusal..Clear()), refusal);
		Test.Assert(resolved == "/home/someone/project/Sources/a.png");
		Test.Assert(policy.Check("/home/someone/Downloads/rock.glb", resolved, refusal), refusal);
		Test.Assert(!policy.Check("/home/someone/project/../.ssh/id_rsa", resolved, refusal));
		Test.Assert(resolved.IsEmpty);
		Test.Assert(!policy.Check("/home/someone/project2/a.png", resolved, refusal));
		Test.Assert(!policy.Check("", resolved, refusal));
		refusal.Clear();
		Test.Assert(!policy.Check("/etc/passwd", resolved, refusal));
		Test.Assert(refusal.Contains("--allow-path"), refusal);
		Test.Assert(refusal.Contains("/home/someone/project") && refusal.Contains("/home/someone/Downloads"), refusal);

		// An optional argument: absent or empty keeps the tool's default; given, it is checked.
		let arguments = JsonValue.MakeObject();
		defer delete arguments;
		Test.Assert(policy.CheckArgument(arguments, "path", resolved, refusal) && resolved.IsEmpty);
		arguments.Set("path", JsonValue.MakeString(""));
		Test.Assert(policy.CheckArgument(arguments, "path", resolved, refusal) && resolved.IsEmpty);
		arguments.Set("path", JsonValue.MakeString("/etc/x.png"));
		Test.Assert(!policy.CheckArgument(arguments, "path", resolved, refusal));
		arguments.Set("path", JsonValue.MakeString("/home/someone/Downloads/x.png"));
		Test.Assert(policy.CheckArgument(arguments, "path", resolved, refusal) && (resolved == "/home/someone/Downloads/x.png"));

		// No project: only the folders.
		policy.SetProject("");
		Test.Assert(!policy.Check("/home/someone/project/a.png", resolved, refusal));
	}

	/// A relative path is taken against the working directory, as the file it names would be.
	[Test]
	public static void ARelativePathIsTakenAgainstTheWorkingDirectory()
	{
		let policy = scope McpPathPolicy();
		let cwd = GetCurrentDirectory(.. scope .());
		policy.AddFolder(cwd);
		policy.AddFolder(cwd); // listed once
		Test.Assert(policy.FolderCount == 1);
		let resolved = scope String();
		let refusal = scope String();
		Test.Assert(policy.Check("shots/a.png", resolved, refusal), refusal);
		let expected = PathNormalizeLexically(PathJoin(cwd, "shots/a.png", .. scope .()), .. scope .());
		Test.Assert(resolved == expected);
		Test.Assert(!policy.Check("../outside.png", resolved, refusal));
	}

	/// A tool that takes a path outside the project says so with openWorldHint, its class kept.
	[Test]
	public static void OpenWorldKeepsTheClassAndSaysItReachesOut()
	{
		let server = scope McpServer();
		server.RegisterTool("import", "reads a file from outside", scope SchemaBuilder().Build(), ToolAnnotations.Creates.OpenWorld,
			new (arguments, outResult, outError) => true);
		let line = scope String();
		Test.Assert(server.HandleLine("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}", line) == .Answered);
		let response = JsonValue.Parse(line);
		defer delete response;
		let hints = response.Get("result").Get("tools").At(0).Get("annotations");
		Test.Assert(hints.Get("openWorldHint").AsBool());
		Test.Assert(!hints.Get("readOnlyHint").AsBool());
		Test.Assert(!hints.Get("destructiveHint").AsBool());
		Test.Assert(!hints.Get("idempotentHint").AsBool());
		Test.Assert(server.Paths != null);
	}
}
