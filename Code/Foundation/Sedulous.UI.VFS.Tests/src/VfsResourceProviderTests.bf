using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.UI;
using Sedulous.UI.VFS;
using Sedulous.VFS;

namespace Sedulous.UI.VFS.Tests;

/// The style sheet resource provider, over a file system held in memory.
///
/// In memory rather than on disk because the provider is GLUE: what is worth pinning is how it
/// handles a missing file, an empty one and no file system at all, none of which need real IO.
class VfsResourceProviderTests
{
	/// A file system of strings.
	private class MemoryFileSystem : IFileSystem
	{
		public Dictionary<String, String> Files = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public void Add(StringView path, StringView content)
		{
			Files[new String(path)] = new String(content);
		}

		public IStream Open(StringView path, FileMode mode)
		{
			if (!Files.TryGetValueAlt(path, let content))
				return null;

			let stream = new MemoryStream();
			stream.Write(.((uint8*)content.Ptr, content.Length));
			stream.Seek(0, .Begin);
			return stream;
		}

		public bool Exists(StringView path) => Files.ContainsKeyAlt(path);
	}

	[Test]
	public static void LoadTextReadsAFilesBytes()
	{
		let files = scope MemoryFileSystem();
		files.Add("a.sss", "button { color: #fff; }");

		let provider = scope VfsResourceProvider(files);
		let text = scope String();

		Test.Assert(provider.LoadText("a.sss", text));
		Test.Assert(text == "button { color: #fff; }");
	}

	[Test]
	public static void AMissingFileFails()
	{
		let files = scope MemoryFileSystem();
		let provider = scope VfsResourceProvider(files);
		let text = scope String();

		Test.Assert(!provider.LoadText("nope.sss", text));
	}

	/// An EMPTY file succeeds with empty text. A sheet importing an empty one is odd but not
	/// broken, and failing would take the whole parse down with it.
	[Test]
	public static void AnEmptyFileSucceedsWithEmptyText()
	{
		let files = scope MemoryFileSystem();
		files.Add("empty.sss", "");

		let provider = scope VfsResourceProvider(files);
		let text = scope String();

		Test.Assert(provider.LoadText("empty.sss", text));
		Test.Assert(text.IsEmpty);
	}

	/// No file system at all fails gracefully rather than crashing: a UI with no IO wired is a
	/// normal state, not a broken one.
	[Test]
	public static void NoFileSystemFailsGracefully()
	{
		let provider = scope VfsResourceProvider(null);
		let text = scope String();

		Test.Assert(!provider.LoadText("x", text));
		Test.Assert(provider.LoadImage("x") == null);
	}

	/// Text that is not an image is refused rather than being handed back as one.
	[Test]
	public static void AFileThatWillNotDecodeIsNotAnImage()
	{
		let files = scope MemoryFileSystem();
		files.Add("notanimage.png", "this is not a PNG");

		let provider = scope VfsResourceProvider(files);

		Test.Assert(provider.LoadImage("notanimage.png") == null);
	}
}
