using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Shaders;

/// THE flag to define-name table, and everything derived from it.
///
/// One table, so adding a flag reaches every consumer at once: the define emission, the
/// variant directive parser, the drift lint, and the power set enumeration all read this
/// and nothing else. Order is the emission order, which the preprocessor does not care
/// about.
static class ShaderFlagNames
{
	public static ShaderFlagName[8] Table = .(
		.(.Skinned, "SKINNED"),
		.(.Instanced, "INSTANCED"),
		.(.AlphaTest, "ALPHA_TEST"),
		.(.GBuffer, "GBUFFER"),
		.(.NormalMap, "NORMAL_MAP"),
		.(.Emissive, "EMISSIVE"),
		.(.VertexColors, "VERTEX_COLORS"),
		.(.ReceiveShadows, "RECEIVE_SHADOWS"));

	/// A `#define NAME 1` for every set flag.
	///
	/// The names are static literals, so the views stay valid for the compile that consumes
	/// them.
	public static void AppendDefines(ShaderFlags flags, List<ShaderDefine> outDefines)
	{
		for (let entry in Table)
		{
			if (flags.HasFlag(entry.Flag))
				outDefines.Add(.(entry.Define, "1"));
		}
	}

	/// The flag a `#define` name stands for, or None when the name is not one of ours.
	///
	/// Case SENSITIVE, matching the preprocessor.
	public static ShaderFlags FlagFromName(StringView name)
	{
		for (let entry in Table)
		{
			if (entry.Define == name)
				return entry.Flag;
		}
		return .None;
	}

	/// A stable hash of a shader's name, which is what keys sources and variants without
	/// storing the name in every key.
	public static uint64 ShaderNameHash(StringView name)
		=> HashBytes(name.Ptr, name.Length);
}
