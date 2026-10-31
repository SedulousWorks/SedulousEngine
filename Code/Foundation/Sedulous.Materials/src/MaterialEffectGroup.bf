using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Materials;

/// One effect's parameters on a material: a group of its own, apart from the shader's properties
/// and never in the shader's buffer. A material whose shader declares an effect's variant flag
/// carries the effect's group: its parameters' names, types and offsets in the effect's own
/// buffer (the effect block's table), and their values. The effect is active while its gate is
/// above zero, and an active effect turns its flag on; what the effect does is its shader code's,
/// so nothing here knows wind. Scripts and overrides address a value as `Effect.Property`
/// (`Wind.Strength`).
class MaterialEffectGroup
{
	public const uint32 cNoGate = uint32.MaxValue;

	/// The effect's (`Wind`).
	public String Name = new .() ~ delete _;
	public ShaderFlags Flag = .None;
	/// Index into Properties.
	public uint32 GateIndex = cNoGate;
	/// The effect buffer's size, a whole row.
	public uint32 UniformSize = 0;
	/// Offsets in the effect's buffer; each name a view into the group's own backing.
	public List<MaterialPropertyDef> Properties = new .() ~ delete _;
	/// UniformSize bytes: the material's values.
	public List<uint8> Defaults = new .() ~ delete _;
	/// STABLE backing for the property name views.
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);

	/// Declares a parameter, its name CLONED into the group's backing.
	public void AddProperty(MaterialPropertyDef property)
	{
		let owned = new String(property.Name);
		mNames.Add(owned);
		var def = property;
		def.Name = owned;
		Properties.Add(def);
	}

	/// The index of the named parameter, or -1.
	public int GetPropertyIndex(StringView name)
	{
		for (int i = 0; i < Properties.Count; i++)
		{
			if (Properties[i].Name == name)
				return i;
		}
		return -1;
	}

	public bool FindProperty(StringView name, out MaterialPropertyDef property)
	{
		let index = GetPropertyIndex(name);
		property = (index >= 0) ? Properties[index] : .();
		return index >= 0;
	}

	/// Whether the effect is on for these values (the material's defaults or an instance's):
	/// its float gate above zero.
	public bool IsActive(Span<uint8> values)
	{
		if (GateIndex >= (uint32)Properties.Count)
			return false;
		let gate = Properties[(int)GateIndex];
		if ((gate.Type != .Float) || ((int)gate.Offset + sizeof(float) > values.Length))
			return false;
		return *(float*)(values.Ptr + gate.Offset) > 0.0f;
	}

	public bool IsActive => IsActive(Defaults);

	/// Replaces `other` with a copy of this group.
	public void CopyTo(MaterialEffectGroup other)
	{
		other.Name.Set(Name);
		other.Flag = Flag;
		other.GateIndex = GateIndex;
		other.UniformSize = UniformSize;
		other.Properties.Clear();
		ClearAndDeleteItems!(other.mNames);
		for (let def in Properties)
			other.AddProperty(def);
		other.Defaults.Clear();
		other.Defaults.AddRange(Defaults);
	}
}

/// The material kind of an effect's or a custom shader's property type: the one mapping from the
/// shader tables (Sedulous.Shaders) to a material's declared types.
static class MaterialPropertyTypes
{
	public static MaterialPropertyType Of(ShaderPropertyType type)
	{
		switch (type)
		{
		case .Float: return .Float;
		case .Float2: return .Float2;
		case .Float3: return .Float3;
		case .Float4: return .Float4;
		case .Int: return .Int;
		case .Color: return .Color;
		case .ColorHdr: return .ColorHdr;
		case .Texture: return .Texture2D;
		case .TextureCube: return .TextureCube;
		case .Sampler: return .Sampler;
		}
	}
}
