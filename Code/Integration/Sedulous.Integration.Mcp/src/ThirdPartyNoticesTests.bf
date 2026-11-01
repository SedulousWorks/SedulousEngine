using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Integration.Mcp;

/// The committed third-party notices (Dependencies/THIRD-PARTY-NOTICES.txt) are what the licence
/// files beside the dependencies assemble to now: a licence added, updated or removed without
/// running Code/Tools/third-party-notices.py fails a test run, not only a later check.
static class ThirdPartyNoticesTests
{
	[Test]
	public static void TheCommittedNoticesAreCurrent()
	{
#if BF_PLATFORM_LINUX
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let repo = scope String();
		PathParent(scope String(dataRoot)..TrimEnd('/'), repo);
		let script = PathJoin(repo, "Code/Tools/third-party-notices.py", .. scope .());
		Test.Assert(FileExists(script), script);
		let result = scope ProcessResult();
		Process.Run("/usr/bin/env", scope StringView[]("python3", script, "--check"), result);
		Test.Assert(result.ExitCode == 0, result.Output);
#endif
	}
}
