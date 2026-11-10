using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Integration.Mcp;

/// What the engine SDK packs (Code/Tools/pack-sdk.py) still builds a project: every dependency of a
/// packed project packed, every path a packed project's configs and compile-time reads name packed,
/// and what a project's workspace generation reads of an SDK present. A project, a data file or a
/// dependency added without the packer following fails a test run, not the release. The check
/// packs nothing.
static class SdkPackingTests
{
	[Test]
	public static void TheSdkPackerFindsEverythingAProjectBuildNeeds()
	{
#if BF_PLATFORM_LINUX
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let repo = scope String();
		PathParent(scope String(dataRoot)..TrimEnd('/'), repo);
		let script = PathJoin(repo, "Code/Tools/pack-sdk.py", .. scope .());
		Test.Assert(FileExists(script), script);
		let result = scope ProcessResult();
		Process.Run("/usr/bin/env", scope StringView[]("python3", script, "--check", "--platform", "Linux64"), result);
		Test.Assert(result.ExitCode == 0, result.Output);
#endif
	}
}
