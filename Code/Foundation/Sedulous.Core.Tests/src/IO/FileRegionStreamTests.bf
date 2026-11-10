using System;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

/// Part of a file read as a stream of its own: positions are the region's, reads stop at its
/// end rather than the file's, and a region running past the file is refused.
class FileRegionStreamTests
{
	private const String kScratch = "scratch_fileregion";

	/// Writes the bytes 0..99 to a fresh file in the scratch folder.
	private static void WriteHundredBytes(String outPath)
	{
		PathJoin(kScratch, "region.bin", outPath);
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let file = scope FileStream(outPath, .Write);
		for (int i < 100)
			Test.Assert(file.WriteValue<uint8>((uint8)i));
	}

	[Test]
	public static void ARegionReadsItsOwnBytesAndStopsAtItsEnd()
	{
		let path = WriteHundredBytes(.. scope String());
		{
			let region = scope FileRegionStream(path, 40, 20);
			Test.Assert(region.IsValid);
			Test.Assert(region.Size() == 20);
			Test.Assert(region.Tell() == 0);

			uint8 first = 0;
			Test.Assert(region.ReadValue(out first));
			Test.Assert(first == 40, "position 0 is the region's first byte");

			// Asked for more than is left: the region's end, not the file's.
			uint8[32] rest = default;
			Test.Assert(region.Read(.(&rest[0], 32)) == 19);
			Test.Assert(rest[18] == 59);
			Test.Assert(region.Read(.(&rest[0], 32)) == 0);

			Test.Assert(region.Seek(-5, .End) == 15);
			Test.Assert(region.ReadValue(out first));
			Test.Assert(first == 55);
			Test.Assert(region.Seek(-3, .Current) == 13);
			Test.Assert(region.ReadValue(out first));
			Test.Assert(first == 53);
			Test.Assert(region.Seek(20, .Begin) == 20);
			Test.Assert(region.Seek(21, .Begin) == -1, "past the region's end");
			Test.Assert(region.Seek(-1, .Begin) == -1);

			Test.Assert(region.Write(.(&rest[0], 4)) == 0, "read-only");
		}
		{
			// The whole file is a region too, and so is its last byte.
			let whole = scope FileRegionStream(path, 0, 100);
			Test.Assert(whole.IsValid);
			let last = scope FileRegionStream(path, 99, 1);
			Test.Assert(last.IsValid);
		}
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void ARegionPastTheFileIsInvalid()
	{
		let path = WriteHundredBytes(.. scope String());
		{
			let pastEnd = scope FileRegionStream(path, 90, 11);
			Test.Assert(!pastEnd.IsValid);
			Test.Assert(pastEnd.Size() == -1);
			uint8 value = 0;
			Test.Assert(!pastEnd.ReadValue(out value));

			let beyond = scope FileRegionStream(path, 101, 0);
			Test.Assert(!beyond.IsValid);
			// An offset and size whose sum wraps around is past the end too.
			let wraps = scope FileRegionStream(path, 50, uint64.MaxValue - 10);
			Test.Assert(!wraps.IsValid);

			let missing = scope FileRegionStream(PathJoin(kScratch, "missing.bin", .. scope String()), 0, 0);
			Test.Assert(!missing.IsValid);
		}
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
}
