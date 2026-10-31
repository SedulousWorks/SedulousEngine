using System;
using System.Collections;
using Sedulous.Materials; // BuiltinShading, MaterialPresets
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Shaders;
using Sedulous.Shaders.Pipeline;
using Sedulous.Shaders.Resource;

namespace Sedulous.Editor.Mcp;

/// material_set_shader: puts a material on a shader, as the material page's Shader row does: on a
/// custom shader asset, laid out by its cooked property table with every value whose name, type
/// and size still fit kept; or back on a built-in (PBR or Unlit). Writing a material's shaderId
/// alone (asset_data_write) leaves it in its old layout, which the cook re-lays every time with a
/// warning for each property the shader lacks.
///
/// A material's effect groups follow the shader's vertex variants: laid on the effects' tables,
/// read from the engine's shader library (the `effect` blocks of its .hlsli files, as the cook
/// reads them), so a material moved onto a shader that declares WIND gains its Wind group
/// (keeping the values it had), and one moved onto a shader that does not loses it. The result
/// lists the groups with their values, addressed as `Effect.Property`.
static class MaterialShaderTool
{
	/// `shaderLibrary`: the engine's Shaders folder, where the effects' tables are declared; empty,
	/// none read, so a material keeps the groups it carries.
	public static void Register(McpServer server, ProjectSession session, StringView shaderLibrary)
	{
		let schema = scope SchemaBuilder();
		schema.Str("material", "the material asset's guid", true);
		schema.Str("shader", "a shader asset's guid, or `pbr`, `unlit` or `phong`", true);
		let library = new String(shaderLibrary);
		server.RegisterTool("material_set_shader",
			"""
			Put a material on a shader, as the material page's Shader row does: `shader` is a custom shader asset's guid (the material laid out by its cooked properties, every value whose name, type and size fit kept; the shader must have cooked: asset_cook first), or `pbr`, `unlit` or `phong` for a built-in. Saves the material; asset_cook to see it. Returns the material's properties after, and its effect groups (`effects`: each effect's name, its variant flag and its parameters with their values; Wind, with Strength, Speed and Height, on any shader whose vertex stage declares WIND, its values kept across the switch; Strength above zero sways). Use this, not asset_data_write of its shaderId, which leaves the material in its old layout.
			""",
			schema.Build(), .Overwrites,
			new (arguments, outResult, outError) => Set(session, library, arguments, outResult, outError), library);
	}

	private static Object Read(Sedulous.Content.Instance instance)
	{
		let object = (instance != null) ? instance.ReadObject() : null;
		return (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) : null;
	}

	private static bool Set(ProjectSession session, StringView library, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let materialText = McpTools.ArgString(arguments, "material", .. scope .());
		let shaderText = McpTools.ArgString(arguments, "shader", .. scope .());
		if (!McpTools.ParseGuid(materialText, outError, let materialId))
			return false;
		let project = session.Project;
		let instance = project.SourceDb.GetInstance(materialId);
		let object = Read(instance);
		defer delete object;
		let material = object as MaterialAsset;
		if (material == null)
		{
			outError.AppendF("no material asset with guid {} in the open project", materialText);
			return false;
		}

		// The shader's vertex variants: which effects' groups the material carries on it.
		var vertexVariants = ShaderFlags.None;
		let builtin = MaterialPresets.FindBuiltinShadingByShortName(shaderText);
		if (builtin.HasValue)
		{
			MaterialShaderLayout.SetBuiltInShader(material.Source, builtin.Value.Shading);
			vertexVariants = builtin.Value.VertexVariants;
		}
		else
		{
			if (!(Guid.Parse(shaderText) case .Ok(let shaderId)))
			{
				outError.AppendF("'{}' is neither a shader asset's guid nor pbr, unlit or phong", shaderText);
				return false;
			}
			let shaderAsset = project.SourceDb.GetInstance(shaderId);
			let shaderObject = Read(shaderAsset);
			defer delete shaderObject;
			if (!(shaderObject is ShaderAsset))
			{
				outError.AppendF("no shader asset with guid {} in the open project", shaderText);
				return false;
			}
			let cooked = Read(project.CookedDb.GetInstance(shaderId));
			defer delete cooked;
			let shader = cooked as ShaderSource;
			if (shader == null)
			{
				outError.AppendF("the shader '{}' has not cooked (or failed to): asset_cook, then try again", shaderAsset.Name);
				return false;
			}
			MaterialShaderLayout.SetShader(material.Source, shaderId, shader);
			vertexVariants = (ShaderFlags)shader.VertexVariantMask;
		}
		// A group the shader declares and the material lacks (every new material: the builders
		// know no effect's table) at the effect's defaults. A library that does not read leaves
		// the groups the switch kept.
		if (!library.IsEmpty)
		{
			let effects = scope ShaderEffectLibrary();
			let effectErrors = scope List<String>(); // the shader cook reports a malformed block
			defer { ClearAndDeleteItems!(effectErrors); }
			ShaderPackCooker.CollectShaderLibraryEffects(library, effects, effectErrors);
			material.Source.AdoptDeclaredEffects(effects.All, vertexVariants);
		}
		if (instance.WriteObject(material) case .Err)
		{
			outError.AppendF("could not write '{}'", instance.Name);
			return false;
		}

		let properties = JsonValue.MakeArray();
		for (let name in material.Source.PropertyNames)
			properties.Add(JsonValue.MakeString(name));
		outResult.Set("material", JsonValue.MakeString(instance.Name));
		outResult.Set("shaderName", JsonValue.MakeString(material.Source.ShaderName));
		outResult.Set("properties", properties);
		outResult.Set("effects", EffectsJson(material.Source));
		return true;
	}

	/// A material's effect groups as a result lists them: each `{name, flag, properties: [{name,
	/// type, value}]}`, the flag by its define's name (WIND), a float's value a number, a wider
	/// value's an array; in a script or an override a parameter is `Name.Property`.
	private static JsonValue EffectsJson(MaterialSource source)
	{
		let effects = JsonValue.MakeArray();
		for (let group in source.Effects)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(group.Name));
			var flag = StringView();
			for (let named in ShaderFlagNames.Table)
			{
				if ((uint32)named.Flag == group.Flag)
					flag = named.Define;
			}
			entry.Set("flag", JsonValue.MakeString(flag));
			let properties = JsonValue.MakeArray();
			for (int i < group.PropertyNames.Count)
			{
				let type = (i < group.PropertyTypes.Count) ? (MaterialPropertyType)group.PropertyTypes[i] : MaterialPropertyType.Float;
				let offset = (i < group.PropertyOffsets.Count) ? (int)group.PropertyOffsets[i] : 0;
				let size = (i < group.PropertySizes.Count) ? (int)group.PropertySizes[i] : 0;
				let property = JsonValue.MakeObject();
				property.Set("name", JsonValue.MakeString(group.PropertyNames[i]));
				let count = Math.Min(size / 4, 4);
				if ((count > 0) && (offset + count * 4 <= group.Values.Count))
				{
					if (type == .Int)
					{
						property.Set("type", JsonValue.MakeString("int"));
						property.Set("value", JsonValue.MakeNumber(*(int32*)(group.Values.Ptr + offset)));
					}
					else
					{
						property.Set("type", JsonValue.MakeString((count == 1) ? "float" : "floats"));
						let at = (float*)(group.Values.Ptr + offset);
						if (count == 1)
							property.Set("value", JsonValue.MakeNumber(at[0]));
						else
						{
							let parts = JsonValue.MakeArray();
							for (int c < count)
								parts.Add(JsonValue.MakeNumber(at[c]));
							property.Set("value", parts);
						}
					}
				}
				properties.Add(property);
			}
			entry.Set("properties", properties);
			effects.Add(entry);
		}
		return effects;
	}
}
