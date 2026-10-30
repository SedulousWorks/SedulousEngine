using System;
using System.Collections;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Editor.Terrain;

/// What a cooked terrain is, as the page's read-only rows say it: a name and its value.
class TerrainFact
{
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;

	public this(StringView name, StringView value)
	{
		Name.Set(name);
		Value.Set(value);
	}

	/// The facts of `product` (its grid, world size, chunks, layers, shadows), appended; the caller
	/// deletes them. Pure, so tested without a host.
	public static void Of(TerrainResource product, List<TerrainFact> outFacts)
	{
		let grid = product.Heightfield.Get;
		if (grid != null)
		{
			let size = grid.Size;
			let chunks = TerrainChunks.ChunksPerSide(size);
			let world = grid.WorldSize;
			outFacts.Add(new .("Grid", scope String()..AppendF("{} x {}", size, size)));
			outFacts.Add(new .("World", scope String()..AppendF("{} x {} m", (int64)world.X, (int64)world.Y)));
			outFacts.Add(new .("Chunks", scope String()..AppendF("{} x {} ({})", chunks, chunks, chunks * chunks)));
		}
		else
			outFacts.Add(new .("Grid", "No heightfield"));
		outFacts.Add(new .("Paint layers", scope String()..AppendF("{}", product.PaletteCount)));
		outFacts.Add(new .("Casts shadows", product.CastShadows ? "Yes" : "No"));
	}
}
