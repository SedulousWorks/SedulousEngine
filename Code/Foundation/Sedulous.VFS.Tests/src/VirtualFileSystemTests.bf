using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.VFS.Tests;

class VirtualFileSystemTests
{
	private const String kA = "scratch_vfs_a";
	private const String kB = "scratch_vfs_b";

	private static void Seed(StringView root, StringView name, StringView text)
	{
		RemoveDirectoryRecursive(root);
		Test.Assert(CreateDirectory(root));
		let full = PathJoin(root, name, .. scope String());
		Test.Assert(WriteFile(full, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	private static void ReadAll(IStream stream, String outText)
	{
		outText.Clear();
		uint8[64] buffer = default;
		let read = stream.Read(.(&buffer[0], 64));
		outText.Append(StringView((char8*)&buffer[0], read));
	}

	[Test]
	public static void SchemesRouteToTheirMounts()
	{
		Seed(kA, "file.txt", "from A");
		Seed(kB, "file.txt", "from B");

		let fsA = scope NativeFileSystem(kA);
		let fsB = scope NativeFileSystem(kB);
		let vfs = scope VirtualFileSystem();
		vfs.Mount("a", fsA);
		vfs.Mount("b", fsB);

		Test.Assert(vfs.Exists("a://file.txt"));
		Test.Assert(vfs.Exists("b://file.txt"));
		Test.Assert(!vfs.Exists("a://missing.txt"));

		let text = scope String();
		{
			let stream = vfs.Open("a://file.txt", .Read);
			Test.Assert(stream != null);
			defer delete stream;
			ReadAll(stream, text);
		}
		Test.Assert(text == "from A");

		{
			let stream = vfs.Open("b://file.txt", .Read);
			Test.Assert(stream != null);
			defer delete stream;
			ReadAll(stream, text);
		}
		Test.Assert(text == "from B", "the same locator resolves per scheme");

		Test.Assert(RemoveDirectoryRecursive(kA));
		Test.Assert(RemoveDirectoryRecursive(kB));
	}

	/// A path with no scheme names no mount. Guessing one would route it somewhere
	/// arbitrary, so it is refused at the call that made it.
	[Test]
	public static void SchemelessPathsAreRefused()
	{
		Seed(kA, "file.txt", "x");
		let fsA = scope NativeFileSystem(kA);
		let vfs = scope VirtualFileSystem();
		vfs.Mount("a", fsA);

		Test.Assert(!vfs.Exists("file.txt"));
		Test.Assert(vfs.Open("file.txt", .Read) == null);
		Test.Assert(!vfs.Exists("a:/file.txt"), "one slash is not the separator");
		Test.Assert(!vfs.Exists("nosuchscheme://file.txt"));

		Test.Assert(RemoveDirectoryRecursive(kA));
	}

	[Test]
	public static void SchemeSplitting()
	{
		Test.Assert(VirtualFileSystem.SplitScheme("data://Assets/a.png", let scheme, let locator));
		Test.Assert(scheme == "data");
		Test.Assert(locator == "Assets/a.png");

		// An empty locator is legitimate: it names the mount root.
		Test.Assert(VirtualFileSystem.SplitScheme("data://", let s2, let l2));
		Test.Assert(s2 == "data");
		Test.Assert(l2 == "");

		Test.Assert(!VirtualFileSystem.SplitScheme("no-scheme/here", let s3, let l3));
		Test.Assert(!VirtualFileSystem.SplitScheme("", let s4, let l4));

		// The FIRST separator splits, so a locator may contain one itself.
		Test.Assert(VirtualFileSystem.SplitScheme("a://b://c", let s5, let l5));
		Test.Assert(s5 == "a");
		Test.Assert(l5 == "b://c");
	}

	/// The router advertises no capabilities of its own: a caller resolves the mount and
	/// asks that. A router that claimed to be writable would have to guess which mount a
	/// write meant.
	[Test]
	public static void TheRouterAdvertisesNoCapabilities()
	{
		let vfs = scope VirtualFileSystem();
		IFileSystem asFileSystem = vfs;
		Test.Assert((asFileSystem as IWritableFileSystem) == null);
		Test.Assert((asFileSystem as IEnumerableFileSystem) == null);
		Test.Assert((asFileSystem as IStatFileSystem) == null);
	}

	[Test]
	public static void MountsResolveAndReplace()
	{
		Seed(kA, "file.txt", "from A");
		Seed(kB, "file.txt", "from B");

		let fsA = scope NativeFileSystem(kA);
		let fsB = scope NativeFileSystem(kB);
		let vfs = scope VirtualFileSystem();

		Test.Assert(vfs.GetMount("data") == null);
		vfs.Mount("data", fsA);
		Test.Assert(vfs.GetMount("data") == fsA);
		Test.Assert(vfs.MountCount == 1);

		// Mounting the same scheme swaps the backend rather than shadowing it.
		vfs.Mount("data", fsB);
		Test.Assert(vfs.GetMount("data") == fsB);
		Test.Assert(vfs.MountCount == 1);

		let text = scope String();
		let stream = vfs.Open("data://file.txt", .Read);
		Test.Assert(stream != null);
		ReadAll(stream, text);
		delete stream;
		Test.Assert(text == "from B");

		Test.Assert(vfs.Unmount("data"));
		Test.Assert(vfs.MountCount == 0);
		Test.Assert(!vfs.Exists("data://file.txt"));
		Test.Assert(!vfs.Unmount("data"));

		Test.Assert(RemoveDirectoryRecursive(kA));
		Test.Assert(RemoveDirectoryRecursive(kB));
	}

	/// A mount is reached through the router but is still the same object, so its
	/// capabilities are the ones it actually has.
	[Test]
	public static void AResolvedMountKeepsItsCapabilities()
	{
		Seed(kA, "file.txt", "x");
		let fsA = scope NativeFileSystem(kA);
		let vfs = scope VirtualFileSystem();
		vfs.Mount("a", fsA);

		let resolved = vfs.GetMount("a");
		Test.Assert(resolved != null);
		let writable = resolved as IWritableFileSystem;
		Test.Assert(writable != null);

		uint8[1] payload = .(7);
		Test.Assert(writable.Save("written.bin", .(&payload[0], 1)) case .Ok);
		Test.Assert(vfs.Exists("a://written.bin"));

		Test.Assert(RemoveDirectoryRecursive(kA));
	}
}
