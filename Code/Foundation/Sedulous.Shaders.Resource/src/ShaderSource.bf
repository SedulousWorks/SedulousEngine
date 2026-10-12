using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Resource;

/// A cooked shader: a name, per stage HLSL (the cook's expanded source: a properties block
/// already replaced by its set-2 declarations), the entry point each stage's function is called
/// in it, each stage's declared variant lattice, and the material property table the properties
/// block declared (the layout every material on this shader is cooked with).
[Serializable(3)]
class ShaderSource
{
	public String Name = new String() ~ delete _;
	public String VertexSource = new String() ~ delete _;
	public String FragmentSource = new String() ~ delete _;
	public String VertexEntryPoint = new String() ~ delete _;
	public String FragmentEntryPoint = new String() ~ delete _;
	/// The ShaderFlags the vertex stage declares.
	public uint32 VertexVariantMask = 0;
	/// The ShaderFlags the fragment stage declares.
	public uint32 FragmentVariantMask = 0;
	// The property table, as parallel lists (the list serialization path).
	public List<String> PropertyNames = new .() ~ DeleteContainerAndItems!(_);
	/// ShaderPropertyType.
	public List<uint8> PropertyTypes = new .() ~ delete _;
	/// Four per property.
	public List<float> PropertyDefaults = new .() ~ delete _;
	public List<uint8> PropertyHasRange = new .() ~ delete _;
	/// Min and max per property.
	public List<float> PropertyRanges = new .() ~ delete _;
	public List<uint32> PropertyOffsets = new .() ~ delete _;
	public List<uint32> PropertySizes = new .() ~ delete _;
	public List<uint32> PropertyBindings = new .() ~ delete _;
	public uint32 UniformSize = 0;

	/// Records a parsed properties block's table.
	public void SetProperties(ShaderPropertiesBlock block)
	{
		ClearAndDeleteItems!(PropertyNames);
		PropertyTypes.Clear();
		PropertyDefaults.Clear();
		PropertyHasRange.Clear();
		PropertyRanges.Clear();
		PropertyOffsets.Clear();
		PropertySizes.Clear();
		PropertyBindings.Clear();
		for (let property in block.Properties)
		{
			PropertyNames.Add(new String(property.Name));
			PropertyTypes.Add((uint8)property.Type);
			PropertyDefaults.Add(property.Value.X);
			PropertyDefaults.Add(property.Value.Y);
			PropertyDefaults.Add(property.Value.Z);
			PropertyDefaults.Add(property.Value.W);
			PropertyHasRange.Add(property.HasRange ? 1 : 0);
			PropertyRanges.Add(property.RangeMin);
			PropertyRanges.Add(property.RangeMax);
			PropertyOffsets.Add(property.Offset);
			PropertySizes.Add(property.Size);
			PropertyBindings.Add(property.Binding);
		}
		UniformSize = block.UniformSize;
	}

	/// The property table as SetProperties recorded it, appended to `outProperties` (owned by the
	/// caller). A table whose lists disagree in length, a damaged product, yields what the
	/// shortest covers.
	public void GetProperties(List<ShaderProperty> outProperties)
	{
		var count = PropertyNames.Count;
		count = Math.Min(count, PropertyTypes.Count);
		count = Math.Min(count, PropertyDefaults.Count / 4);
		count = Math.Min(count, PropertyHasRange.Count);
		count = Math.Min(count, PropertyRanges.Count / 2);
		count = Math.Min(count, Math.Min(PropertyOffsets.Count, Math.Min(PropertySizes.Count, PropertyBindings.Count)));
		for (int i < count)
		{
			let property = new ShaderProperty();
			property.Name.Set(PropertyNames[i]);
			property.Type = (ShaderPropertyType)PropertyTypes[i];
			property.Value = .(PropertyDefaults[i * 4], PropertyDefaults[i * 4 + 1], PropertyDefaults[i * 4 + 2],
				PropertyDefaults[i * 4 + 3]);
			property.HasRange = PropertyHasRange[i] != 0;
			property.RangeMin = PropertyRanges[i * 2];
			property.RangeMax = PropertyRanges[i * 2 + 1];
			property.Offset = PropertyOffsets[i];
			property.Size = PropertySizes[i];
			property.Binding = PropertyBindings[i];
			outProperties.Add(property);
		}
	}
}
