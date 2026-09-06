using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.VFS.Tests;

class SourcePathTests
{
	private static void Check(StringView raw, StringView expected)
	{
		let path = scope SourcePath(raw);
		Test.Assert(path.Value == expected, scope $"'{raw}' normalized to '{path.Value}', expected '{expected}'");
	}

	[Test]
	public static void NormalizationTable()
	{
		Check("Fonts/Roboto.ttf", "Fonts/Roboto.ttf");

		// A Windows-authored path heals rather than breaking every other platform.
		Check(@"Fonts\Roboto.ttf", "Fonts/Roboto.ttf");
		Check(@"a\b\c/d", "a/b/c/d");

		// Redundant structure is dropped.
		Check("a//b", "a/b");
		Check("./a/./b", "a/b");
		Check("a/", "a");
		Check("", "");

		// Violations normalize to EMPTY: a missing reference, never a wrong one.
		Check("/absolute/path", "");
		Check("../escape", "");
		Check("a/../b", "");
		Check("C:/volume", "");
		Check("scheme://locator", "");
	}

	/// ".." is rejected wherever it appears, not only at the front. A normalizer that
	/// collapses "a/../b" to "b" would let a reference climb out of its mount and back
	/// into somewhere it was never allowed.
	[Test]
	public static void DotDotIsRejectedRatherThanResolved()
	{
		Check("a/../b", "");
		Check("a/b/../c", "");
		Check("a/..", "");
		Check("..", "");

		// A name that merely begins with dots is a normal name.
		Check("..hidden/file.txt", "..hidden/file.txt");
		Check(".dataroot", ".dataroot");
	}

	[Test]
	public static void Accessors()
	{
		let path = scope SourcePath("Fonts/Sub/Roboto.ttf");
		Test.Assert(path.FileName == "Roboto.ttf");
		Test.Assert(path.Stem == "Roboto");
		Test.Assert(path.Directory == "Fonts/Sub");
		Test.Assert(path.GetExtension(.. scope String()) == "ttf");

		let bare = scope SourcePath("Roboto.ttf");
		Test.Assert(bare.FileName == "Roboto.ttf");
		Test.Assert(bare.Stem == "Roboto");
		Test.Assert(bare.Directory == "", "a bare filename has no directory");

		let noExtension = scope SourcePath("Fonts/README");
		Test.Assert(noExtension.Stem == "README");
		Test.Assert(noExtension.GetExtension(.. scope String()) == "");

		let empty = scope SourcePath("");
		Test.Assert(empty.IsEmpty);
		Test.Assert(empty.FileName == "");
	}

	/// The extension selects an importer, so it must not depend on how the file happened
	/// to be named.
	[Test]
	public static void TheExtensionIsLowercased()
	{
		Test.Assert(scope SourcePath("A/B.TTF").GetExtension(.. scope String()) == "ttf");
		Test.Assert(scope SourcePath("A/B.PnG").GetExtension(.. scope String()) == "png");

		// A trailing dot is not an extension.
		Test.Assert(scope SourcePath("A/B.").GetExtension(.. scope String()) == "");
	}

	/// Case sensitive on every platform. One rule everywhere means a Windows-authored
	/// mismatch fails a test rather than a user on Linux.
	[Test]
	public static void ComparisonIsCaseSensitive()
	{
		let lower = scope SourcePath("fonts/roboto.ttf");
		let upper = scope SourcePath("Fonts/Roboto.ttf");
		Test.Assert(!lower.Equals(upper));
		Test.Assert(lower.Equals(scope SourcePath("fonts/roboto.ttf")));
		Test.Assert(lower.Equals("fonts/roboto.ttf"));
	}

	/// The wire shape is a plain string, identical to the String field this replaces, so
	/// data written before the type existed still loads.
	[Test]
	public static void TheWireShapeIsAPlainString()
	{
		let stream = scope MemoryStream();
		{
			// Written the way an older build would have: a bare string.
			let writer = scope BinaryWriter(stream);
			Test.Assert(writer.WriteString(@"Fonts\Roboto.ttf"));
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let loaded = scope SourcePath();
		{
			let reader = scope BinarySerializer(stream, .Read);
			loaded.Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		// And it healed on the way in, with no version bump anywhere.
		Test.Assert(loaded.Value == "Fonts/Roboto.ttf");
	}

	[Test]
	public static void RoundTrips()
	{
		let stream = scope MemoryStream();
		{
			let source = scope SourcePath("Textures/Ground/Albedo.png");
			let writer = scope BinarySerializer(stream, .Write);
			source.Serialize(writer);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope SourcePath();
		{
			let reader = scope BinarySerializer(stream, .Read);
			target.Serialize(reader);
		}
		Test.Assert(target.Value == "Textures/Ground/Albedo.png");
	}
}
