using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.VFS.Zip;
using Sedulous.Zip;

namespace Sedulous.VFS.Zip.Tests;

/// The files under one folder of a zip, read through the VFS: Data/Tests/Zip's project.zip
/// (from Sedulous.Zip.Tests' make-fixtures.sh), whose Game/ holds a stored noise.bin and a
/// deflated Level1.scene.
class ZipFileSystemTests
{
	private static void Fixture(StringView name, String outPath)
	{
		let root = FindDataRoot(.. scope String());
		PathJoin(root, scope $"Tests/Zip/{name}", outPath);
	}

	private static void ReadAll(IStream stream, List<uint8> outBytes)
	{
		outBytes.Count = (int)stream.Size();
		if (!outBytes.IsEmpty)
			Test.Assert(stream.Read(outBytes) == outBytes.Count);
	}

	/// The entry's bytes as the zip reader extracts them, to compare with what the VFS reads.
	private static void Extracted(StringView zipPath, StringView name, List<uint8> outBytes)
	{
		let file = scope FileStream(zipPath, .Read);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		for (let entry in zip.Entries)
		{
			if (entry.Name == name)
				Test.Assert(zip.Read(entry, outBytes, error), error);
		}
	}

	private static bool Same(List<uint8> a, List<uint8> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	private static bool Lists(List<DirEntry> entries, StringView name, bool isDirectory)
	{
		for (let entry in entries)
		{
			if ((entry.Name == name) && (entry.IsDirectory == isDirectory))
				return true;
		}
		return false;
	}

	[Test]
	public static void AFolderOfAZipReadsAsAFileSystemStoredFilesInPlaceAndDeflatedOnesInflated()
	{
		let zipPath = Fixture("project.zip", .. scope .());
		let fs = scope ZipFileSystem(zipPath, "Game");
		Test.Assert(fs.IsValid, scope String(fs.Error));
		Test.Assert(fs.EntryCount == 4);
		Test.Assert(fs.ArchivePath == zipPath);
		IFileSystem asFileSystem = fs;
		Test.Assert((asFileSystem as IEnumerableFileSystem) != null);
		Test.Assert((asFileSystem as IWritableFileSystem) == null);

		Test.Assert(fs.Exists("Project.xml"));
		Test.Assert(fs.Exists("Scenes")); // a folder with a file below it
		Test.Assert(fs.Exists("Scenes/Level1.scene"));
		Test.Assert(!fs.Exists("Game/Project.xml")); // named below the folder, not with it
		Test.Assert(!fs.Exists("Missing.txt"));

		let top = scope List<DirEntry>();
		defer { for (var listed in ref top) listed.Dispose(); }
		Test.Assert(fs.Enumerate("", top) case .Ok);
		Test.Assert(top.Count == 4, scope $"saw {top.Count}");
		Test.Assert(Lists(top, "Project.xml", false));
		Test.Assert(Lists(top, "Empty.txt", false));
		Test.Assert(Lists(top, "Audio", true));
		Test.Assert(Lists(top, "Scenes", true));
		let scenes = scope List<DirEntry>();
		defer { for (var child in ref scenes) child.Dispose(); }
		Test.Assert(fs.Enumerate("Scenes", scenes) case .Ok);
		Test.Assert(scenes.Count == 1);
		Test.Assert(Lists(scenes, "Level1.scene", false));

		// Stored: read in place, the same bytes the zip reader extracts, and a region to read it by.
		Test.Assert(fs.StoredRegion("Audio/noise.bin", let offset, let size));
		Test.Assert(size == 3000);
		Test.Assert(offset > 0);
		let expected = scope List<uint8>();
		let read = scope List<uint8>();
		{
			let noise = fs.Open("Audio/noise.bin", .Read);
			Test.Assert(noise != null);
			defer delete noise;
			Test.Assert(noise is FileRegionStream);
			Test.Assert(noise.Size() == 3000);
			ReadAll(noise, read);
			Extracted(zipPath, "Game/Audio/noise.bin", expected);
			Test.Assert(Same(read, expected));
			Test.Assert(noise.Seek(2990, .Begin) == 2990);
			uint8[32] tail = default;
			Test.Assert(noise.Read(.(&tail[0], 32)) == 10, "reads stop at the file's end, not the archive's");
			Test.Assert(tail[9] == expected[2999]);
		}

		// Deflated: inflated whole, and no region to read it in place by.
		Test.Assert(!fs.StoredRegion("Scenes/Level1.scene", ?, ?));
		{
			let scene = fs.Open("Scenes/Level1.scene", .Read);
			Test.Assert(scene != null);
			defer delete scene;
			Test.Assert(scene.Size() == 8092);
			ReadAll(scene, read);
			Extracted(zipPath, "Game/Scenes/Level1.scene", expected);
			Test.Assert(Same(read, expected));
		}

		Test.Assert(fs.Open("Project.xml", .Write) == null, "read-only");
		Test.Assert(fs.Open("Missing.txt", .Read) == null);

		// The whole archive, with no folder: names keep their own. A trailing slash on a folder
		// names the same folder.
		let whole = scope ZipFileSystem(zipPath, "");
		Test.Assert(whole.IsValid);
		Test.Assert(whole.Exists("Game/Project.xml"));
		let slashed = scope ZipFileSystem(zipPath, "Game/");
		Test.Assert(slashed.Exists("Project.xml"));
		let other = scope ZipFileSystem(zipPath, "Gam");
		Test.Assert(other.IsValid);
		Test.Assert(other.EntryCount == 0, "a folder is matched whole, never as a prefix");

		let missing = scope ZipFileSystem("scratch_no_such.zip", "Game");
		Test.Assert(!missing.IsValid);
		Test.Assert(!missing.Error.IsEmpty);
		Test.Assert(!missing.Exists("Project.xml"));
		Test.Assert(missing.Open("Project.xml", .Read) == null);
		Test.Assert(missing.Enumerate("", scope List<DirEntry>()) case .Err(.NotFound));
	}

	/// Mounted in a VirtualFileSystem, a zip's folder answers as any other backend does.
	[Test]
	public static void AZipFolderMountsLikeADirectory()
	{
		let zipPath = Fixture("project.zip", .. scope .());
		let fs = scope ZipFileSystem(zipPath, "Game");
		let vfs = scope VirtualFileSystem();
		vfs.Mount("game", fs);
		Test.Assert(vfs.Exists("game://Project.xml"));
		let stream = vfs.Open("game://Project.xml", .Read);
		Test.Assert(stream != null);
		defer delete stream;
		let bytes = scope List<uint8>();
		ReadAll(stream, bytes);
		Test.Assert(StringView((char8*)bytes.Ptr, bytes.Count) == "<Project name=\"Game\"/>\n");
	}
}
