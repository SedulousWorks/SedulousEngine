using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.VG.SVG;
using Sedulous.GUI.VFS;

namespace Sedulous.GUI.VFS.Tests;

/// A minimal in-memory filesystem: serves stored byte blobs as MemoryStreams.
class MemFS : IFileSystem
{
	public Dictionary<String, List<uint8>> Files = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	public void Add(StringView path, Span<uint8> content)
	{
		if (Files.TryGetValueAlt(path, let existing))
		{
			existing.Clear(); // the file replaced
			existing.AddRange(content);
			return;
		}
		let bytes = new List<uint8>();
		bytes.AddRange(content);
		Files[new String(path)] = bytes;
	}

	public void AddText(StringView path, StringView text)
	{
		Add(path, Span<uint8>((uint8*)text.Ptr, text.Length));
	}

	public IStream Open(StringView path, FileMode mode)
	{
		if (!Files.TryGetValueAlt(path, let content))
			return null;
		let stream = new MemoryStream();
		if (content.Count != 0)
			stream.Write(Span<uint8>(content.Ptr, content.Count));
		stream.Seek(0, .Begin);
		return stream;
	}

	public bool Exists(StringView path) => Files.ContainsKeyAlt(path);
}

/// VfsResourceProvider: loads and decodes background-image assets from a VFS. A mock in-memory
/// IFileSystem exercises the plumbing; a real BMP round trip (SaveImage, a NativeFileSystem,
/// LoadImage) exercises the decode path.
class VfsResourceProviderTests
{
	private const String cBar = "<svg width=\"24\" height=\"12\"><rect width=\"24\" height=\"12\" fill=\"#ff0000\"/></svg>";

	[Test]
	public static void NullFilesystemReturnsNull()
	{
		let provider = scope VfsResourceProvider(null);
		Test.Assert(provider.LoadImage("anything.png") == null);
	}

	[Test]
	public static void AMissingFileReturnsNull()
	{
		let fs = scope MemFS();
		let provider = scope VfsResourceProvider(fs);
		Test.Assert(provider.LoadImage("nope.png") == null);
	}

	[Test]
	public static void UndecodableBytesReturnNull()
	{
		let fs = scope MemFS();
		uint8[16] junk = default;
		for (int i = 0; i < 16; i++)
			junk[i] = (uint8)i;
		fs.Add("bad.png", Span<uint8>(&junk[0], junk.Count));
		let provider = scope VfsResourceProvider(fs);
		Test.Assert(provider.LoadImage("bad.png") == null);
	}

	[Test]
	public static void LoadsAndDecodesARealImage()
	{
		// Write a 3x2 RGBA image to disk, then load it back through a NativeFileSystem + the provider.
		uint8[3 * 2 * 4] pixels = .(
			255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255,
			255, 255, 0, 255, 0, 255, 255, 255, 255, 0, 255, 255);
		let src = scope Sedulous.Image.Image(3, 2, .RGBA8, Span<uint8>(&pixels[0], pixels.Count));
		StringView file = "scratch_gui_vfs_roundtrip.bmp";
		defer { System.IO.File.Delete(file).IgnoreError(); }
		Test.Assert(ImageIO.SaveImage(src, file, .BMP) case .Ok);

		let fs = scope NativeFileSystem("."); // rooted at the test working directory
		let provider = scope VfsResourceProvider(fs);

		let loaded = provider.LoadImage(file);
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 3);
		Test.Assert(loaded.Height == 2);

		// The provider owns the image, one per path: a second load (a restyle asking again) is the same.
		let again = provider.LoadImage(file);
		Test.Assert(again != null);
		Test.Assert(again == loaded);
		Test.Assert(again.Width == 3);
	}

	// === Behaviour no Raptor test covers ===

	[Test]
	public static void LoadTextAppendsTheWholeFileAndAnEmptyOneSucceedsEmpty()
	{
		let fs = scope MemFS();
		fs.AddText("a.css", "button { color: #fff; }");
		fs.AddText("empty.css", "");
		let provider = scope VfsResourceProvider(fs);
		let text = scope String("/* */ ");
		Test.Assert(provider.LoadText("a.css", text));
		Test.Assert(text == "/* */ button { color: #fff; }");
		let empty = scope String();
		Test.Assert(provider.LoadText("empty.css", empty));
		Test.Assert(empty.IsEmpty);
		Test.Assert(!provider.LoadText("missing.css", empty));
		let none = scope VfsResourceProvider(null);
		Test.Assert(!none.LoadText("a.css", empty));
	}

	[Test]
	public static void AnEmptyFileIsNoImage()
	{
		let fs = scope MemFS();
		fs.AddText("empty.png", "");
		let provider = scope VfsResourceProvider(fs);
		Test.Assert(provider.LoadImage("empty.png") == null);
	}

	[Test]
	public static void AnSvgIsParsedOnceAndKeptAFailureIsTriedAgain()
	{
		let fs = scope MemFS();
		fs.AddText("bar.svg", cBar);
		let provider = scope VfsResourceProvider(fs);
		let first = provider.LoadSvg("bar.svg");
		Test.Assert(first != null);
		Test.Assert(provider.LoadSvg("bar.svg") == first); // kept: the same document

		Test.Assert(provider.LoadSvg("late.svg") == null); // not there yet
		fs.AddText("late.svg", cBar);
		let late = provider.LoadSvg("late.svg"); // asked again: it has arrived
		Test.Assert(late != null);
		Test.Assert(late != first);
	}

	[Test]
	public static void AnImageThatFailedToDecodeIsTriedAgain()
	{
		let fs = scope MemFS();
		uint8[4] junk = .(1, 2, 3, 4);
		fs.Add("swap.bmp", Span<uint8>(&junk[0], junk.Count));
		let provider = scope VfsResourceProvider(fs);
		Test.Assert(provider.LoadImage("swap.bmp") == null);

		// A real image arrives under the same path: the provider decodes it now.
		uint8[4] pixel = .(10, 20, 30, 255);
		let src = scope Sedulous.Image.Image(1, 1, .RGBA8, Span<uint8>(&pixel[0], 4));
		StringView file = "scratch_gui_vfs_retry.bmp";
		defer { System.IO.File.Delete(file).IgnoreError(); }
		Test.Assert(ImageIO.SaveImage(src, file, .BMP) case .Ok);
		let disk = scope NativeFileSystem(".");
		let bytes = scope List<uint8>();
		let stream = disk.Open(file, .Read);
		Test.Assert(stream != null);
		bytes.Resize((int)stream.Size());
		stream.Read(Span<uint8>(bytes.Ptr, bytes.Count));
		delete stream;
		fs.Add("swap.bmp", bytes);

		let loaded = provider.LoadImage("swap.bmp");
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 1);
	}
}
