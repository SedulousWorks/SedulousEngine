using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Terrain;

namespace Sedulous.Editor.Terrain;

/// The palette the splat panel shows: the first terrain in the scene with layers wins.
class LayerSet
{
	/// The palette layer count, unbounded.
	public uint32 Count = 0;
	/// The BASE layer's albedo asset, separate and never painted.
	public Guid BaseId = .();
	/// The palette albedo asset guids.
	public List<Guid> Ids = new .() ~ delete _;

	public static void Resolve(Scene scene, LayerSet outSet)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		if (manager == null)
			return;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (outSet.Count > 0)
					return;
				let res = component.Terrain.Get;
				if (res == null)
					return;
				outSet.BaseId = res.Base.Albedo.Id;
				for (let layer in res.Palette)
					outSet.Ids.Add(layer.Albedo.Id);
				outSet.Count = res.PaletteCount;
			});
	}
}
