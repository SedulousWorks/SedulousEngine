namespace Sedulous.Shaders;

using System;
using Sedulous.RHI;

/// Uniquely identifies a shader variant for caching.
/// Combines shader name, stage, and variant flags.
struct ShaderVariantKey : IHashable, IEquatable<ShaderVariantKey>
{
	/// Shader source name (without extension).
	public StringView Name;

	/// Alias for Name (compatibility with Sedulous.Shaders).
	public StringView ShaderName => Name;

	/// Shader stage (vertex, fragment, compute).
	public ShaderStage Stage;

	/// Variant flags that determine #defines.
	public ShaderFlags Flags;

	public this(StringView name, ShaderStage stage, ShaderFlags flags = .None)
	{
		Name = name;
		Stage = stage;
		Flags = flags;
	}

	/// Computes a hash code for cache lookup.
	public int GetHashCode()
	{
		int hash = Name.GetHashCode();
		hash = hash * 31 + (int)Stage;
		hash = hash * 31 + (int)Flags;
		return hash;
	}

	/// Compares two keys for equality.
	public bool Equals(ShaderVariantKey other)
	{
		return Name == other.Name && Stage == other.Stage && Flags == other.Flags;
	}

	/// Generates a filename-safe cache key string.
	/// Format: {name}_{stage}_{flags}.spv or .dxil
	public void GenerateCacheFilename(String outFilename, bool spirv = true)
	{
		outFilename.Append(Name);
		outFilename.Append("_");

		switch (Stage)
		{
		case .Vertex:       outFilename.Append("vs");
		case .Fragment:     outFilename.Append("fs");
		case .Compute:      outFilename.Append("cs");
		case .Mesh:         outFilename.Append("ms");
		case .Task:         outFilename.Append("as");
		case .RayGen:       outFilename.Append("rgen");
		case .ClosestHit:   outFilename.Append("rchit");
		case .Miss:         outFilename.Append("rmiss");
		case .AnyHit:       outFilename.Append("rahit");
		case .Intersection: outFilename.Append("rint");
		case .None:         outFilename.Append("none");
		case .AllGraphics, .All: outFilename.Append("all");
		}

		if (Flags != .None)
		{
			outFilename.Append("_");
			Flags.AppendKeyString(outFilename);
		}

		outFilename.Append(spirv ? ".spv" : ".dxil");
	}

	/// Gets the DXC target profile string for this stage.
	public void GetTargetProfile(String outProfile, StringView shaderModel = "6_0")
	{
		switch (Stage)
		{
		case .Vertex:       outProfile.AppendF("vs_{}", shaderModel);
		case .Fragment:     outProfile.AppendF("ps_{}", shaderModel);
		case .Compute:      outProfile.AppendF("cs_{}", shaderModel);
		case .Mesh:         outProfile.AppendF("ms_{}", shaderModel);
		case .Task:         outProfile.AppendF("as_{}", shaderModel);
		case .RayGen, .ClosestHit, .Miss, .AnyHit, .Intersection:
			outProfile.AppendF("lib_{}", shaderModel);
		case .None, .AllGraphics, .All:
			outProfile.AppendF("lib_{}", shaderModel);
		}
	}

	/// Generate a unique string key for caching purposes.
	public void GenerateCacheKey(String outKey)
	{
		outKey.Clear();
		outKey.Append(ShaderName);
		outKey.Append("_");

		switch (Stage)
		{
		case .Vertex:   outKey.Append("vert");
		case .Fragment: outKey.Append("frag");
		case .Compute:  outKey.Append("comp");
		default:        outKey.Append("unknown");
		}

		if (Flags != .None)
		{
			outKey.AppendF("_{:X}", (uint32)Flags);
		}
	}

	/// Gets the entry point name for this stage (default convention).
	public void GetDefaultEntryPoint(String outEntryPoint)
	{
		// All shaders use "main" as entry point for Vulkan/SPIRV compatibility
		outEntryPoint.Append("main");
	}

	/// Creates a debug string representation.
	public override void ToString(String outStr)
	{
		outStr.AppendF("{}:{}:{}", Name, Stage, (uint32)Flags);
	}
}
