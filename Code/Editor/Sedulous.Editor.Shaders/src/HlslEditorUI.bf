using System;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Shaders;

/// The editor side of custom shaders: the HLSL syntax tables a code editor highlights a shader
/// with, registered under "hlsl" and "hlsli". HLSL's quirks: '#' preprocessor lines and char
/// literals; block comments do not nest. The types include the properties block's own (Color,
/// ColorHdr, Texture, Sampler), and `properties` is a keyword, so the block reads as the language
/// it is part of.
static class HlslEditorUI
{
	private static readonly StringView[42] cKeywords = .(
		"break", "case", "cbuffer", "centroid", "column_major", "const", "continue", "default",
		"discard", "do", "else", "false", "for", "groupshared", "if", "in", "inline", "inout",
		"linear", "nointerpolation", "noperspective", "out", "packoffset", "precise", "properties",
		"register", "return", "row_major", "sample", "static", "struct", "switch", "tbuffer", "true",
		"typedef", "uniform", "unroll", "loop", "branch", "flatten", "volatile", "while");
	private static readonly StringView[63] cTypes = .(
		// Scalars, vectors and matrices.
		"void", "bool", "bool2", "bool3", "bool4", "int", "int2", "int3", "int4",
		"uint", "uint2", "uint3", "uint4", "half", "half2", "half3", "half4",
		"float", "float2", "float3", "float4", "double", "double2", "double3", "double4",
		"min16float", "min16float2", "min16float3", "min16float4",
		"float2x2", "float2x3", "float2x4", "float3x2", "float3x3", "float3x4",
		"float4x2", "float4x3", "float4x4", "matrix", "vector",
		// Resources.
		"Texture1D", "Texture2D", "Texture2DArray", "Texture2DMS", "Texture3D", "TextureCube",
		"TextureCubeArray", "RWTexture2D", "RWTexture2DArray", "RWTexture3D", "SamplerState",
		"SamplerComparisonState", "Buffer", "RWBuffer", "StructuredBuffer", "RWStructuredBuffer",
		"ByteAddressBuffer", "RWByteAddressBuffer", "ConstantBuffer",
		// The properties block's types.
		"Color", "ColorHdr", "Texture", "Sampler");

	/// The caller owns the result.
	public static ICodeLexer MakeLexer()
	{
		var spec = CLikeLexerSpec();
		spec.Keywords = cKeywords;
		spec.Types = cTypes;
		spec.HashPreprocessorLines = true;
		spec.CharLiterals = true;
		return new CLikeLexer(spec);
	}

	public static void Register()
	{
		CodeLexerRegistry.Register("hlsl", new () => MakeLexer());
		CodeLexerRegistry.Register("hlsli", new () => MakeLexer());
	}
}
