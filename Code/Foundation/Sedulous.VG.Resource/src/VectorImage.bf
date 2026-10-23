using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.VG.Resource;

/// The cooked form of a vector image: a validated `.svg` document. The cook loads it as the
/// renderer reads it and fails on one it cannot, then ships the text; whatever draws it parses
/// it again. Nothing in it is a UI's: a theme's icon, a game's HUD art and an editor's glyph are
/// the same record, so it needs neither the renderer nor a UI to read.
[Serializable(1)]
class VectorImageResource
{
	public String Svg = new .() ~ delete _;
}

/// A loaded vector image: its SVG text.
class VectorImage
{
	public String Svg = new .() ~ delete _;
}

/// Builds a cooked vector image record into a runtime one.
class VectorImageFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<VectorImage>();
	public Type CookedType => typeof(VectorImageResource);

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Build(instance);

	public Object DecodeStage(Instance instance) => Build(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Build(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		defer delete stored;

		let record = stored as VectorImageResource;
		if (record == null)
			return null;

		let image = new VectorImage();
		image.Svg.Set(record.Svg);
		return image;
	}
}
