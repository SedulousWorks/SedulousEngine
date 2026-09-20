using System;
using System.Collections;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Editor.Terrain;

/// The terrain page's stats column, read off the resolved product.
static class TerrainStats
{
	/// Appends one line per stat; the caller owns the strings.
	public static void Lines(TerrainResource product, List<String> outLines)
	{
		let grid = product.Heightfield.Get;
		if (grid != null)
		{
			let size = grid.Size;
			let k = TerrainChunks.ChunksPerSide(size);
			let ws = grid.WorldSize;
			outLines.Add(new $"Grid: {size} x {size}");
			outLines.Add(new $"World: {(int64)ws.X} x {(int64)ws.Y} m");
			outLines.Add(new $"Chunks: {k} x {k} = {k * k}");
		}
		else
			outLines.Add(new String("Heightfield: unresolved"));
		outLines.Add(new $"Palette layers: {product.PaletteCount}");
		outLines.Add(new $"Cast shadows: {product.CastShadows ? "yes" : "no"}");
	}
}
