using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Shaders;

/// An effect's table: what its `effect Name : FLAG { ... }` block declares, laid out as its
/// cbuffer is. A material whose shader declares the effect's flag carries these values as a group
/// of their own; the effect is active while its gate is above zero, and an active effect turns
/// its flag on.
class ShaderEffect
{
	/// The cbuffer's name, and the `Name.Property` a material addresses.
	public String Name = new .() ~ delete _;
	/// The variant the effect's code is compiled in.
	public ShaderFlags Flag = .None;
	/// Uniforms only, in declaration order.
	public List<ShaderProperty> Properties = new .() ~ DeleteContainerAndItems!(_);
	/// The property marked (gate), or ShaderProperties.cNoEffectGate.
	public uint32 GateIndex = ShaderProperties.cNoEffectGate;
	/// The cbuffer's size.
	public uint32 UniformSize = 0;

	public ShaderProperty Gate => (GateIndex < (uint32)Properties.Count) ? Properties[(int)GateIndex] : null;

	public ShaderProperty FindProperty(StringView name)
	{
		for (let property in Properties)
		{
			if (property.Name == name)
				return property;
		}
		return null;
	}

	/// Replaces `other`'s table with a copy of this one.
	public void CopyTo(ShaderEffect other)
	{
		other.Name.Set(Name);
		other.Flag = Flag;
		ClearAndDeleteItems!(other.Properties);
		for (let property in Properties)
		{
			let copy = new ShaderProperty();
			property.CopyTo(copy);
			other.Properties.Add(copy);
		}
		other.GateIndex = GateIndex;
		other.UniformSize = UniformSize;
	}
}

/// What ShaderProperties.ParseEffect found: the block's place in its source (what ExpandEffects
/// replaces), its table and its errors. Present false: no effect block.
class ShaderEffectBlock
{
	public bool Present = false;
	/// The byte offset of the `effect` line's start.
	public int Begin = 0;
	/// The byte offset just past the closing brace's line.
	public int End = 0;
	/// The `effect` line, 1 based.
	public uint32 FirstLine = 0;
	/// The closing brace's line.
	public uint32 LastLine = 0;
	public ShaderEffect Effect = new .() ~ delete _;
	public List<ShaderPropertyError> Errors = new .() ~ DeleteContainerAndItems!(_);

	public bool IsOk => Errors.IsEmpty;
}

/// The effects a corpus declares, each once: by name, by its variant flag, or all of them. The
/// cook fills one into the pack; the shader system serves one. It holds copies of what it is
/// given.
class ShaderEffectLibrary
{
	private List<ShaderEffect> mEffects = new .() ~ DeleteContainerAndItems!(_);

	/// Adds a copy of `effect`. False, with the reason in `outError`, when its name or its flag is
	/// taken: a flag turns on one effect, and a name addresses one (`Wind.Strength`).
	public bool Add(ShaderEffect effect, String outError)
	{
		for (let existing in mEffects)
		{
			if (existing.Name == effect.Name)
			{
				outError.Set(scope $"effect '{effect.Name}' is declared twice");
				return false;
			}
			if (existing.Flag == effect.Flag)
			{
				outError.Set(scope $"effects '{existing.Name}' and '{effect.Name}' share a variant flag");
				return false;
			}
		}
		let copy = new ShaderEffect();
		effect.CopyTo(copy);
		mEffects.Add(copy);
		return true;
	}

	public ShaderEffect Find(StringView name)
	{
		for (let effect in mEffects)
		{
			if (effect.Name == name)
				return effect;
		}
		return null;
	}

	public ShaderEffect ForFlag(ShaderFlags flag)
	{
		for (let effect in mEffects)
		{
			if (effect.Flag == flag)
				return effect;
		}
		return null;
	}

	public Span<ShaderEffect> All => mEffects;
	public int Count => mEffects.Count;
	public bool IsEmpty => mEffects.IsEmpty;

	public void Clear()
	{
		ClearAndDeleteItems!(mEffects);
	}
}
