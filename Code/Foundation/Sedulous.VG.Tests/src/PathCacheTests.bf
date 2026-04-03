namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class PathCacheTests
{
	[Test]
	public static void SamePath_ReturnsCached()
	{
		let cache = scope PathCache();

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		let verts1 = scope List<VGVertex>();
		let idx1 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts1, idx1);

		let count1 = verts1.Count;

		let verts2 = scope List<VGVertex>();
		let idx2 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts2, idx2);

		// Same results
		Test.Assert(verts2.Count == count1);
		Test.Assert(idx2.Count == idx1.Count);
	}

	[Test]
	public static void DifferentStyle_Retessellates()
	{
		let cache = scope PathCache();

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		let verts1 = scope List<VGVertex>();
		let idx1 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts1, idx1);

		let verts2 = scope List<VGVertex>();
		let idx2 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Blue, .EvenOdd, false, verts2, idx2);

		// Should have same geometry count but different colors
		Test.Assert(verts2.Count == verts1.Count);
	}

	[Test]
	public static void Invalidate_Clears()
	{
		let cache = scope PathCache();

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		let verts1 = scope List<VGVertex>();
		let idx1 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts1, idx1);

		cache.Invalidate(path);

		// After invalidation, getting again should still work (retessellate)
		let verts2 = scope List<VGVertex>();
		let idx2 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts2, idx2);

		Test.Assert(verts2.Count > 0);
	}

	[Test]
	public static void Clear_RemovesAll()
	{
		let cache = scope PathCache();

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		let verts = scope List<VGVertex>();
		let idx = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts, idx);

		cache.Clear();

		// After clear, should be able to add again
		let verts2 = scope List<VGVertex>();
		let idx2 = scope List<uint32>();
		cache.GetOrTessellateFill(path, Color.Red, .EvenOdd, false, verts2, idx2);
		Test.Assert(verts2.Count > 0);
	}
}
