using System;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.VFS.Tests;

class DataRootTests
{
	private const String kScratch = "scratch_vfs_dataroot";

	[Test]
	public static void DiscoveryFindsTheMarkedDirectory()
	{
		RemoveDirectoryRecursive(kScratch);

		// <scratch>/Bin/App is the "executable" directory; the root is <scratch>/Data.
		let binDir = PathJoin(kScratch, "Bin/App", .. scope String());
		Test.Assert(CreateDirectory(PathJoin(kScratch, "Bin", .. scope String())));
		Test.Assert(CreateDirectory(binDir));

		let dataDir = PathJoin(kScratch, "Data", .. scope String());
		Test.Assert(CreateDirectory(dataDir));

		let found = scope String();
		FindDataRootFrom(binDir, found);
		Test.Assert(found.IsEmpty, "a Data directory without the marker is not a root");

		// The marker is what makes it one.
		let marker = PathJoin(dataDir, cDataRootMarker, .. scope String());
		Test.Assert(WriteFile(marker, Span<uint8>()) case .Ok);
		Test.Assert(IsDataRoot(dataDir));

		FindDataRootFrom(binDir, found);
		Test.Assert(!found.IsEmpty, "walked up from the executable directory");
		Test.Assert(found.EndsWith("Data"));
		Test.Assert(IsDataRoot(found));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// The first iteration covers "<start>/Data", which is the relocated distribution
	/// where Data sits beside the executable rather than above it.
	[Test]
	public static void DataBesideTheExecutableIsFound()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let dataDir = PathJoin(kScratch, "Data", .. scope String());
		Test.Assert(CreateDirectory(dataDir));
		Test.Assert(WriteFile(PathJoin(dataDir, cDataRootMarker, .. scope String()), Span<uint8>()) case .Ok);

		let found = scope String();
		FindDataRootFrom(kScratch, found);
		Test.Assert(!found.IsEmpty);
		Test.Assert(IsDataRoot(found));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// A miss is empty rather than a guess. The caller decides what to do about it, and
	/// FindDataRoot says so in the log rather than leaving unexplained missing assets.
	[Test]
	public static void AMissIsEmpty()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let found = scope String();
		FindDataRootFrom(kScratch, found);
		Test.Assert(found.IsEmpty);

		Test.Assert(!IsDataRoot(kScratch));
		Test.Assert(!IsDataRoot("no_such_directory_anywhere"));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// An empty root gives the relative path back unchanged, so a caller can pass
	/// FindDataRoot straight through and keep a fallback for the empty case.
	[Test]
	public static void DataPathJoinsOrPassesThrough()
	{
		Test.Assert(DataPath("/opt/game/Data", "Assets/a.png", .. scope String()) == "/opt/game/Data/Assets/a.png");
		Test.Assert(DataPath("", "Assets/a.png", .. scope String()) == "Assets/a.png");
	}

	/// Mounting the discovered root is the whole point, and it is two lines.
	[Test]
	public static void TheRootMountsAsAScheme()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let dataDir = PathJoin(kScratch, "Data", .. scope String());
		Test.Assert(CreateDirectory(dataDir));
		Test.Assert(WriteFile(PathJoin(dataDir, cDataRootMarker, .. scope String()), Span<uint8>()) case .Ok);
		Test.Assert(WriteFile(PathJoin(dataDir, "asset.txt", .. scope String()), .((uint8*)(void*)"payload", 7)) case .Ok);

		let root = scope String();
		FindDataRootFrom(kScratch, root);
		Test.Assert(!root.IsEmpty);

		let dataFs = scope NativeFileSystem(root);
		let vfs = scope VirtualFileSystem();
		vfs.Mount("data", dataFs);

		Test.Assert(vfs.Exists("data://asset.txt"));
		let stream = vfs.Open("data://asset.txt", .Read);
		Test.Assert(stream != null);
		delete stream;

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
	/// A valid override wins verbatim, and one without the marker is REFUSED rather than
	/// silently used: a mistyped path that becomes the root fails later and further away,
	/// on the first asset that is not where it should be.
	[Test]
	public static void AnOverrideIsValidatedBeforeItIsBelieved()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let dataDir = PathJoin(kScratch, "Data", .. scope String());
		Test.Assert(CreateDirectory(dataDir));
		Test.Assert(WriteFile(PathJoin(dataDir, cDataRootMarker, .. scope String()), Span<uint8>()) case .Ok);

		Test.Assert(ResolveDataRoot(dataDir, .. scope String()) == dataDir);
		Test.Assert(ResolveDataRoot(kScratch, .. scope String()).IsEmpty, "no marker inside it");
		Test.Assert(ResolveDataRoot("no_such_directory_anywhere", .. scope String()).IsEmpty);

		// No override falls through to the walk, which from a test binary under the build
		// output finds the repository's own Data.
		let discovered = ResolveDataRoot("", .. scope String());
		Test.Assert(!discovered.IsEmpty);
		Test.Assert(IsDataRoot(discovered));
		Test.Assert(discovered == FindDataRoot(.. scope String()));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Both spellings of the flag, a missing one, and one left dangling with no value.
	[Test]
	public static void TheOverrideIsReadFromEitherSpelling()
	{
		let flag = scope String("--data-root");
		let value = scope String("some/Data");
		let joined = scope String("--data-root=other/Data");
		let unrelated = scope String("--vk");

		Test.Assert(DataRootFromArguments(scope String[](flag, value), .. scope String())
			== "some/Data");
		Test.Assert(DataRootFromArguments(scope String[](unrelated, joined), .. scope String())
			== "other/Data");
		Test.Assert(DataRootFromArguments(scope String[](unrelated), .. scope String()).IsEmpty);
		Test.Assert(DataRootFromArguments(scope String[](flag), .. scope String()).IsEmpty,
			"dangling, so there is nothing to take");
		Test.Assert(DataRootFromArguments(Span<String>(), .. scope String()).IsEmpty);
	}
}
