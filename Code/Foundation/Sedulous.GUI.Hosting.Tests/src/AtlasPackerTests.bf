using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Hosting.Tests;

/// The atlas's shelf packer: pictures in rows across a page, each row as tall as the first it
/// took; a picture on the shortest row it fits wasting no more than a third, else a new row under
/// the last; none when the page is full; emptied by a reset.
class AtlasPackerTests
{
	[Test]
	public static void PicturesGoAcrossARowATallerOneOnANewRowUnderIt()
	{
		let packer = scope ShelfPacker(64, 64);
		let a = packer.Place(18, 18);
		let b = packer.Place(18, 18);
		Test.Assert(a.HasValue);
		Test.Assert(b.HasValue);
		Test.Assert(a.Value.X == 0);
		Test.Assert(a.Value.Y == 0);
		Test.Assert(b.Value.X == 18); // beside it
		Test.Assert(b.Value.Y == 0);
		let tall = packer.Place(10, 34); // too tall for the first row
		Test.Assert(tall.HasValue);
		Test.Assert(tall.Value.Y == 18);
		Test.Assert(tall.Value.X == 0);
		// A small one goes on the row it wastes least of: the 18 high, not the 34.
		let small = packer.Place(10, 16);
		Test.Assert(small.HasValue);
		Test.Assert(small.Value.Y == 0);
		Test.Assert(small.Value.X == 36);
		// A short one would waste more than a third of either: a row of its own.
		let flat = packer.Place(10, 6);
		Test.Assert(flat.HasValue);
		Test.Assert(flat.Value.Y == 52);
		Test.Assert(packer.AreaUsed == 18 * 18 * 2 + 10 * 34 + 10 * 16 + 10 * 6);
	}

	[Test]
	public static void AFullPagePlacesNothingMoreAndAResetEmptiesIt()
	{
		let packer = scope ShelfPacker(32, 32);
		for (int i < 4)
			Test.Assert(packer.Place(16, 16).HasValue);
		Test.Assert(!packer.Place(16, 16).HasValue);
		Test.Assert(!packer.Place(40, 4).HasValue); // wider than the page
		packer.Reset();
		Test.Assert(packer.AreaUsed == 0);
		let again = packer.Place(16, 16);
		Test.Assert(again.HasValue);
		Test.Assert(again.Value.X == 0);
		Test.Assert(again.Value.Y == 0);
	}
}
