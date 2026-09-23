using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Vegetation;

namespace Sedulous.Engine.Vegetation;

/// A layer of PLACED instances, which the Paint Props brush stamps and the manager buckets
/// per chunk.
///
/// The instances are TERRAIN LOCAL, like the procedural scatter's, so the whole set follows
/// the terrain's transform without being rewritten.
[Reflect(.All)]
class PropVegetationLayer : VegetationLayerBase
{
	/// The placed instances.
	///
	/// NOT an inspector row: a list of matrices has no editor, and the brush IS the editor.
	[Hidden]
	public List<Float4x4> Instances = new .() ~ delete _;

	public this() {}

	/// The rules a STAMP applies, which is the shared set: slope, height, scale, alignment
	/// and the fade. There is no source, so the placement never grows anything on its own.
	public ScatterLayer ToScatterLayer()
	{
		var layer = ScatterLayer();
		FillScatterLayer(ref layer);
		layer.Placement = .Uniform;
		layer.Density = 0.0f;
		return layer;
	}

	public override void Serialize(ISerializer ar)
	{
		SerializeBase(ar);
		ar.Key("instances");
		SerializeList(ar, Instances);
	}
}
