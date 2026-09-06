using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

class FileStreamTests
{
	private const String kScratch = "scratch_filestream";

	[Test]
	public static void WritesThenReadsAFile()
	{
		let path = PathJoin(kScratch, "roundtrip.bin", .. scope String());
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		{
			let file = scope FileStream(path, .Write);
			Test.Assert(file.IsValid);
			Test.Assert(file.WriteValue<int32>(0x11223344));
			Test.Assert(file.WriteValue<float>(2.5f));
			Test.Assert(file.Size() == 8);
		}

		{
			let file = scope FileStream(path, .Read);
			Test.Assert(file.IsValid);
			Test.Assert(file.Size() == 8);

			int32 a = 0;
			float b = 0;
			Test.Assert(file.ReadValue(out a));
			Test.Assert(file.ReadValue(out b));
			Test.Assert(a == 0x11223344);
			Test.Assert(b == 2.5f);
			Test.Assert(file.Tell() == 8);

			// Nothing left.
			int32 extra = 0;
			Test.Assert(!file.ReadValue(out extra));
		}

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void AnUnopenablePathIsInvalid()
	{
		let file = scope FileStream("no_such_directory_at_all/nothing.bin", .Read);
		Test.Assert(!file.IsValid);

		// An invalid stream answers rather than crashing, and refuses everything.
		Test.Assert(file.Size() == -1);
		Test.Assert(file.Tell() == -1);
		Test.Assert(file.Seek(0, .Begin) == -1);
		uint8[4] scratch = default;
		Test.Assert(file.Read(.(&scratch[0], 4)) == 0);
		Test.Assert(file.Write(.(&scratch[0], 4)) == 0);
	}

	/// Write truncates an existing file and Append does not. The two differ only when the
	/// file is already there, which is why the fixture writes twice.
	[Test]
	public static void WriteTruncatesAndAppendDoesNot()
	{
		let path = PathJoin(kScratch, "modes.bin", .. scope String());
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		{
			let file = scope FileStream(path, .Write);
			Test.Assert(file.WriteValue<int32>(1));
			Test.Assert(file.WriteValue<int32>(2));
		}

		// The first stream closed when it left scope, and both values reached the file.
		{
			let check = scope FileStream(path, .Read);
			Test.Assert(check.Size() == 8);
		}

		// Write again: the previous contents are gone.
		{
			let file = scope FileStream(path, .Write);
			Test.Assert(file.IsValid);
			Test.Assert(file.Size() == 0, "Write truncates");
			Test.Assert(file.WriteValue<int32>(3));
		}

		// Append: the existing contents stay, and the new value lands after them.
		{
			let file = scope FileStream(path, .Append);
			Test.Assert(file.IsValid);
			Test.Assert(file.WriteValue<int32>(4));
		}

		{
			let file = scope FileStream(path, .Read);
			Test.Assert(file.Size() == 8);
			int32 first = 0;
			int32 second = 0;
			Test.Assert(file.ReadValue(out first));
			Test.Assert(file.ReadValue(out second));
			Test.Assert(first == 3);
			Test.Assert(second == 4);
		}

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// ReadWrite creates the file if it is missing and keeps it if it is not, which is
	/// what separates it from both Read and Write.
	[Test]
	public static void ReadWriteCreatesThenPreserves()
	{
		let path = PathJoin(kScratch, "readwrite.bin", .. scope String());
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		{
			let file = scope FileStream(path, .ReadWrite);
			Test.Assert(file.IsValid, "created when missing");
			Test.Assert(file.WriteValue<int32>(5));
		}

		{
			let file = scope FileStream(path, .ReadWrite);
			Test.Assert(file.IsValid);
			Test.Assert(file.Size() == 4, "kept when present");

			int32 value = 0;
			Test.Assert(file.ReadValue(out value));
			Test.Assert(value == 5);
		}

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void SeekOriginsAgreeOnAFile()
	{
		let path = PathJoin(kScratch, "seek.bin", .. scope String());
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		{
			let file = scope FileStream(path, .Write);
			for (int32 i < 10)
				Test.Assert(file.WriteValue<uint8>((uint8)i));
		}

		{
			let file = scope FileStream(path, .Read);
			Test.Assert(file.Seek(3, .Begin) == 3);
			Test.Assert(file.Seek(2, .Current) == 5);
			Test.Assert(file.Seek(-1, .End) == 9);

			uint8 value = 0;
			Test.Assert(file.ReadValue(out value));
			Test.Assert(value == 9, "the last byte, reached from the end");
		}

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Closing invalidates the stream, so a use after it answers rather than reaching a
	/// released platform handle.
	[Test]
	public static void CloseInvalidates()
	{
		let path = PathJoin(kScratch, "close.bin", .. scope String());
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let file = scope FileStream(path, .Write);
		Test.Assert(file.IsValid);
		Test.Assert(file.WriteValue<int32>(1));
		file.Close();

		Test.Assert(!file.IsValid);
		Test.Assert(file.Size() == -1);
		Test.Assert(file.WriteValue<int32>(2) == false);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
}
