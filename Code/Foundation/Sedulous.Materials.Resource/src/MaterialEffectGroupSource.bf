using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Materials;

namespace Sedulous.Materials.Resource;

/// One effect group of a material as stored: the effect's name and variant flag, its gate's
/// index, its buffer's size, its parameters' names, types, offsets and sizes, and the material's
/// values. Everything the group needs is here, so a material from an asset draws its effect with
/// nothing at runtime but its source. Parallel arrays, as MaterialSource's properties are.
[Serializable]
class MaterialEffectGroupSource
{
	public String Name = new .() ~ delete _;
	/// ShaderFlags: the effect's variant.
	public uint32 Flag = 0;
	public uint32 GateIndex = MaterialEffectGroup.cNoGate;
	public uint32 UniformSize = 0;
	public List<String> PropertyNames = new .() ~ DeleteContainerAndItems!(_);
	/// MaterialPropertyType values.
	public List<uint8> PropertyTypes = new .() ~ delete _;
	public List<uint32> PropertyOffsets = new .() ~ delete _;
	public List<uint32> PropertySizes = new .() ~ delete _;
	public List<uint8> Values = new .() ~ delete _;

	/// A material's effect group as stored.
	public static void FromGroup(MaterialEffectGroup group, MaterialEffectGroupSource outSource)
	{
		outSource.Name.Set(group.Name);
		outSource.Flag = (uint32)group.Flag;
		outSource.GateIndex = group.GateIndex;
		outSource.UniformSize = group.UniformSize;
		ClearAndDeleteItems!(outSource.PropertyNames);
		outSource.PropertyTypes.Clear();
		outSource.PropertyOffsets.Clear();
		outSource.PropertySizes.Clear();
		for (let def in group.Properties)
		{
			outSource.PropertyNames.Add(new String(def.Name));
			outSource.PropertyTypes.Add((uint8)def.Type);
			outSource.PropertyOffsets.Add(def.Offset);
			outSource.PropertySizes.Add(def.Size);
		}
		outSource.Values.Clear();
		outSource.Values.AddRange(group.Defaults);
	}

	/// The group on `material` (replacing one of its name).
	public void ApplyTo(Material material)
	{
		let defs = scope List<MaterialPropertyDef>();
		for (int i < PropertyNames.Count)
		{
			var def = MaterialPropertyDef();
			def.Name = PropertyNames[i];
			def.Type = (i < PropertyTypes.Count) ? (MaterialPropertyType)PropertyTypes[i] : .Float;
			def.Binding = (uint32)i;
			def.Offset = (i < PropertyOffsets.Count) ? PropertyOffsets[i] : 0;
			def.Size = (i < PropertySizes.Count) ? PropertySizes[i] : 0;
			defs.Add(def);
		}
		material.SetEffectGroup(Name, (Sedulous.Shaders.ShaderFlags)Flag, GateIndex, UniformSize, defs, Values);
	}
}
