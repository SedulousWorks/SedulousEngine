using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Shaders;
using Sedulous.Shaders.Pipeline;

namespace Sedulous.Editor.Mcp;

/// shader_validate: checks a custom shader's source WITHOUT saving it, through ShaderCheck, the
/// check the shader cook runs (the properties block expanded, every flag tested declared, every
/// variant of both stages compiled with DXC against the engine's shader library). Returns the
/// errors with file, line and column, and the parsed properties and each stage's variant flags, so
/// the agent sees what a material on it will show. Project independent.
static class ShaderValidateTool
{
	/// `shaderLibrary`: the engine's Shaders/ folder, the include path; empty, includes resolve
	/// nowhere. Copied into the tool's context, which the tool owns.
	public static void Register(McpServer server, StringView shaderLibrary)
	{
		let schema = scope SchemaBuilder();
		schema.Str("source", "the full .hlsl source text", true);
		schema.Str("name", "the file name errors carry (default 'shader.hlsl')");
		schema.Str("vertexEntryPoint", "the vertex stage's function (default VSMain)");
		schema.Str("fragmentEntryPoint", "the pixel stage's function (default PSMain)");
		let library = new String(shaderLibrary);
		server.RegisterTool("shader_validate",
			"""
			CHECK a custom shader's .hlsl source without saving: the exact check the shader cook runs (its properties block expanded, every #ifdef flag declared on a // variants(vertex): or // variants(fragment): line, every variant of both stages compiled against the engine's shader library). Returns errors with file, line and column (an error under one flag says so), and on success the parsed properties (name, type, default, range) and each stage's variant flags. Use as the loop while writing a shader, BEFORE cooking it.
			""",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Validate(arguments, library, outResult, outError), library);
	}

	private static bool Validate(JsonValue arguments, StringView library, JsonValue outResult, String outError)
	{
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		if (name.IsEmpty)
			name.Set("shader.hlsl");
		let vertexEntry = McpTools.ArgString(arguments, "vertexEntryPoint", .. scope .());
		if (vertexEntry.IsEmpty)
			vertexEntry.Set("VSMain");
		let fragmentEntry = McpTools.ArgString(arguments, "fragmentEntryPoint", .. scope .());
		if (fragmentEntry.IsEmpty)
			fragmentEntry.Set("PSMain");
		let source = McpTools.ArgString(arguments, "source", .. scope .());

		var options = ShaderCheckOptions();
		options.VertexEntryPoint = vertexEntry;
		options.FragmentEntryPoint = fragmentEntry;
		options.ShaderLibrary = library;
		options.Depth = .EveryVariant;
		let check = scope ShaderCheck();
		check.Run(source, name, options);

		let errors = JsonValue.MakeArray();
		for (let diagnostic in check.Errors)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("file", JsonValue.MakeString(diagnostic.File));
			entry.Set("line", JsonValue.MakeNumber(diagnostic.Line));
			entry.Set("column", JsonValue.MakeNumber(diagnostic.Column));
			entry.Set("message", JsonValue.MakeString(diagnostic.Message));
			errors.Add(entry);
		}
		outResult.Set("valid", JsonValue.MakeBool(check.IsOk));
		outResult.Set("errors", errors);

		let properties = JsonValue.MakeArray();
		for (let property in check.Block.Properties)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(property.Name));
			entry.Set("type", JsonValue.MakeString(Keyword(property.Type)));
			let value = JsonValue.MakeArray();
			value.Add(JsonValue.MakeNumber(property.Value.X));
			value.Add(JsonValue.MakeNumber(property.Value.Y));
			value.Add(JsonValue.MakeNumber(property.Value.Z));
			value.Add(JsonValue.MakeNumber(property.Value.W));
			entry.Set("default", value);
			if (property.HasRange)
			{
				let range = JsonValue.MakeArray();
				range.Add(JsonValue.MakeNumber(property.RangeMin));
				range.Add(JsonValue.MakeNumber(property.RangeMax));
				entry.Set("range", range);
			}
			properties.Add(entry);
		}
		outResult.Set("properties", properties);
		outResult.Set("vertexVariants", FlagNames(check.VertexMask));
		outResult.Set("fragmentVariants", FlagNames(check.FragmentMask));
		return true;
	}

	/// The keyword a properties block writes for a type (`Color`, `float2`).
	public static StringView Keyword(ShaderPropertyType type)
	{
		switch (type)
		{
		case .Float: return "float";
		case .Float2: return "float2";
		case .Float3: return "float3";
		case .Float4: return "float4";
		case .Int: return "int";
		case .Color: return "Color";
		case .ColorHdr: return "ColorHdr";
		case .Texture: return "Texture";
		case .TextureCube: return "TextureCube";
		case .Sampler: return "Sampler";
		}
	}

	/// The flags a lattice declares, by their #define names.
	private static JsonValue FlagNames(ShaderFlags mask)
	{
		let names = JsonValue.MakeArray();
		for (let entry in ShaderFlagNames.Table)
		{
			if (mask.HasFlag(entry.Flag))
				names.Add(JsonValue.MakeString(entry.Define));
		}
		return names;
	}
}
