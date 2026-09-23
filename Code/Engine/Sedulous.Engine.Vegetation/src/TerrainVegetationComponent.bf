using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Vegetation;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Engine.Vegetation;

/// The one list layout of data version 1, until the two lists landed: every layer carried
/// every field, and a placement of three, the retired Scattered, made it a prop layer.
///
/// READ ONLY, and never written. Delete it once every scene has been re-saved.
static class VegetationLayerV1
{
	/// The retired Scattered enumerator's value, which is what marked a prop layer.
	public const uint8 cPlacementScattered = 3;

	/// One version 1 layer, read into whichever of the two kinds its placement names.
	///
	/// The field order is version 1's, which is the base's prefix INTERLEAVED with the
	/// procedural fields rather than split: a binary read is positional, so this walks the
	/// old order exactly and sorts the values afterwards.
	public static void Read(ISerializer ar, VegetationLayerBase outBase, ref uint8 outPlacement,
		ref uint32 outSplatLayer, ref float outSplatThreshold, ref uint32 outMaskPlane,
		ref float outDensity, List<Float4x4> outInstances)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", outBase.Name);
		SerializeValue(ar, "mesh", ref outBase.Mesh.Id);
		SerializeValue(ar, "material", ref outBase.Material.Id);
		SerializeValue(ar, "placement", ref outPlacement);
		SerializeValue(ar, "splatLayer", ref outSplatLayer);
		SerializeValue(ar, "splatThreshold", ref outSplatThreshold);
		SerializeValue(ar, "maskPlane", ref outMaskPlane);
		SerializeValue(ar, "density", ref outDensity);
		ar.Key("scaleRange");
		Sedulous.Core.Serialization.Serialize(ar, ref outBase.ScaleRange);
		SerializeValue(ar, "maxSlopeDegrees", ref outBase.MaxSlopeDegrees);
		ar.Key("heightRange");
		Sedulous.Core.Serialization.Serialize(ar, ref outBase.HeightRange);
		SerializeValue(ar, "alignToNormal", ref outBase.AlignToNormal);
		SerializeValue(ar, "fadeStart", ref outBase.FadeStart);
		SerializeValue(ar, "fadeEnd", ref outBase.FadeEnd);
		SerializeValue(ar, "castShadows", ref outBase.CastShadows);
		SerializeValue(ar, "maxInstancesPerChunk", ref outBase.MaxInstancesPerChunk);
		SerializeValue(ar, "visible", ref outBase.Visible);
		ar.Key("instances");
		SerializeList(ar, outInstances);
	}

	/// Copies the shared fields across, the two kinds sharing a base rather than a layout.
	public static void CopyBase(VegetationLayerBase from, VegetationLayerBase to)
	{
		to.Name.Set(from.Name);
		to.Mesh = from.Mesh;
		to.Material = from.Material;
		to.ScaleRange = from.ScaleRange;
		to.MaxSlopeDegrees = from.MaxSlopeDegrees;
		to.HeightRange = from.HeightRange;
		to.AlignToNormal = from.AlignToNormal;
		to.FadeStart = from.FadeStart;
		to.FadeEnd = from.FadeEnd;
		to.CastShadows = from.CastShadows;
		to.MaxInstancesPerChunk = from.MaxInstancesPerChunk;
		to.Visible = from.Visible;
	}
}

/// The vegetation over one terrain: its layers, on the terrain component's entity, or on a
/// child of it since the manager walks the ancestry.
///
/// TWO layer lists rather than one. A procedural layer is grown from a source and a prop
/// layer is placed by hand, and one list carrying both meant a procedural layer dragged an
/// empty instance array while a prop layer carried a density and a splat threshold that
/// meant nothing, with nothing saying which entries a brush owned.
[SerializableComponent("terrainVegetation", 2, 1)]
[DisplayName("Terrain Vegetation")]
[Category("Terrain")]
struct TerrainVegetationComponent : ISerializable, IComponentResources
{
	/// Grown from a source. OWNED, but created and freed by the manager: a struct component
	/// cannot carry a field destructor.
	[DisplayName("Procedural Layers")]
	public List<ProceduralVegetationLayer> ProceduralLayers = null;
	/// Placed by the Paint Props brush. Owned the same way.
	[DisplayName("Prop Layers")]
	public List<PropVegetationLayer> PropLayers = null;
	/// The painted mask, density planes over the footprint; none means no Mask placement
	/// grows. A procedural layer with Mask or SplatTimesMask placement names its plane.
	[Description("The painted vegetation mask, one density plane per layer that uses Mask placement; the Paint Vegetation brush paints it.")]
	public Ref<VegetationMask> Mask = .(Guid());
	public bool Visible = true;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Mask.Bind(manager);
		for (let layer in ProceduralLayers)
			layer.ResolveResources(manager);
		for (let layer in PropLayers)
			layer.ResolveResources(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		// The legacy reader: version 1's single list, split by the placement it carried. The
		// component's declared floor is what lets the payload in at all, and the scene
		// re-saves as version 2.
		if ((ar.Mode == .Read) && (ar.Version == 1))
		{
			ReadVersionOne(ar);
			return;
		}

		SerializeValue(ar, "mask", ref Mask.Id);
		ar.Key("proceduralLayers");
		SerializeList(ar, ProceduralLayers);
		ar.Key("propLayers");
		SerializeList(ar, PropLayers);
		SerializeValue(ar, "visible", ref Visible);
	}

	private void ReadVersionOne(ISerializer ar) mut
	{
		SerializeValue(ar, "mask", ref Mask.Id);

		var count = (uint32)0;
		ar.Key("layers");
		ar.BeginArray(ref count);
		for (uint32 i = 0; i < count; i++)
		{
			let staging = scope VegetationLayerBase();
			let instances = scope List<Float4x4>();
			uint8 placement = VegetationLayerV1.cPlacementScattered;
			uint32 splatLayer = 0;
			float splatThreshold = 0.25f;
			uint32 maskPlane = 0;
			float density = 2.0f;
			VegetationLayerV1.Read(ar, staging, ref placement, ref splatLayer,
				ref splatThreshold, ref maskPlane, ref density, instances);

			if (placement == VegetationLayerV1.cPlacementScattered)
			{
				let prop = new PropVegetationLayer();
				VegetationLayerV1.CopyBase(staging, prop);
				prop.Instances.AddRange(instances);
				PropLayers.Add(prop);
			}
			else
			{
				// The retired enumerator's NEIGHBOURS keep their values, so the stored number
				// still names the placement it always did.
				let grown = new ProceduralVegetationLayer();
				VegetationLayerV1.CopyBase(staging, grown);
				grown.Placement = (VegetationPlacement)placement;
				grown.SplatLayer = splatLayer;
				grown.SplatThreshold = splatThreshold;
				grown.MaskPlane = maskPlane;
				grown.Density = density;
				ProceduralLayers.Add(grown);
			}
		}
		ar.EndArray();

		SerializeValue(ar, "visible", ref Visible);
	}
}
