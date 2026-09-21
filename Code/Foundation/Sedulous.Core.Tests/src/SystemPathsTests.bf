using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// GetEnvironmentVariable and UserDataDir.
class SystemPathsTests
{
	[Test]
	public static void AnEnvironmentVariableIsFoundOrReportedAbsent()
	{
		let value = scope String();
		Test.Assert(GetEnvironmentVariable("PATH", value) case .Ok);
		Test.Assert(!value.IsEmpty, "PATH is set on every platform we target");

		let missing = scope String();
		Test.Assert(GetEnvironmentVariable("ENV_DEFINITELY_NOT_SET_XYZ_123", missing) case .Err);
	}

	[Test]
	public static void TheUserDataDirectoryResolves()
	{
		let path = scope String();
		GetUserDataDirectory(path);
		Test.Assert(!path.IsEmpty);
		Test.Assert(path.EndsWith(UserDataDirectoryName),
			scope $"the application's own folder is joined on: {path}");
	}

	/// A caller can ask for another name, which is what a tool shipping beside the engine
	/// does so it does not share the engine's folder.
	[Test]
	public static void ADifferentApplicationNameGetsADifferentFolder()
	{
		let mine = scope String();
		let theirs = scope String();
		GetUserDataDirectory(mine, "SomeTool");
		GetUserDataDirectory(theirs, "OtherTool");
		Test.Assert(mine != theirs);
		Test.Assert(mine.EndsWith("SomeTool"));
	}

}
