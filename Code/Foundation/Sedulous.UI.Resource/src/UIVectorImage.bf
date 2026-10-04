using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.UI.Resource;

/// The cooked form of a vector image: a validated `.svg` document. A theme names one with
/// `@icon` (the theme's cook embeds it); the product carries it for anything else that draws
/// one.
[Serializable(1)]
class UIVectorImageResource
{
	public String Svg = new .() ~ delete _;
}

/// A loaded vector image: its SVG text.
class UIVectorImage
{
	public String Svg = new .() ~ delete _;
}

/// Builds a cooked vector image record into a runtime one.
class UIVectorImageFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<UIVectorImage>();
	public Type CookedType => typeof(UIVectorImageResource);

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

		let record = stored as UIVectorImageResource;
		if (record == null)
			return null;

		let image = new UIVectorImage();
		image.Svg.Set(record.Svg);
		return image;
	}
}
