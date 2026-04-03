using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

class AtlasRegionTests
{
	[Test]
	static void TestAtlasRegionDefaultConstructor()
	{
		let region = AtlasRegion();

		Test.Assert(region.X == 0);
		Test.Assert(region.Y == 0);
		Test.Assert(region.Width == 0);
		Test.Assert(region.Height == 0);
		Test.Assert(region.OffsetX == 0);
		Test.Assert(region.OffsetY == 0);
		Test.Assert(region.AdvanceX == 0);
		Test.Assert(region.IsEmpty);
	}

	[Test]
	static void TestAtlasRegionConstructor()
	{
		let region = AtlasRegion(10, 20, 32, 48, 2.0f, -5.0f, 30.0f);

		Test.Assert(region.X == 10);
		Test.Assert(region.Y == 20);
		Test.Assert(region.Width == 32);
		Test.Assert(region.Height == 48);
		Test.Assert(region.OffsetX == 2.0f);
		Test.Assert(region.OffsetY == -5.0f);
		Test.Assert(region.AdvanceX == 30.0f);
		Test.Assert(!region.IsEmpty);
	}

	[Test]
	static void TestAtlasRegionGetUVs()
	{
		let region = AtlasRegion(64, 128, 32, 48, 0, 0, 0);

		float u0 = 0, v0 = 0, u1 = 0, v1 = 0;
		region.GetUVs(512, 512, out u0, out v0, out u1, out v1);

		// u0 = 64 / 512 = 0.125
		// v0 = 128 / 512 = 0.25
		// u1 = (64 + 32) / 512 = 0.1875
		// v1 = (128 + 48) / 512 = 0.34375
		Test.Assert(Math.Abs(u0 - 0.125f) < 0.0001f);
		Test.Assert(Math.Abs(v0 - 0.25f) < 0.0001f);
		Test.Assert(Math.Abs(u1 - 0.1875f) < 0.0001f);
		Test.Assert(Math.Abs(v1 - 0.34375f) < 0.0001f);
	}
}
