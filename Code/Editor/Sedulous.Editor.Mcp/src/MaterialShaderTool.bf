using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Materials.Pipeline;
using Sedulous.Shaders.Pipeline;
using Sedulous.Shaders.Resource;

namespace Sedulous.Editor.Mcp;

/// material_set_shader: puts a material on a shader, as the material page's Shader row does: on a
/// custom shader asset, laid out by its cooked property table with every value whose name, type
/// and size still fit kept; or back on a built-in (PBR or Unlit). Writing a material's shaderId
/// alone (asset_data_write) leaves it in its old layout, which the cook re-lays every time with a
/// warning for each property the shader lacks.
static class MaterialShaderTool
{
	public static void Register(McpServer server, ProjectSession session)
	{
		let schema = scope SchemaBuilder();
		schema.Str("material", "the material asset's guid", true);
		schema.Str("shader", "a shader asset's guid, or `pbr` or `unlit`", true);
		server.RegisterTool("material_set_shader",
			"""
			Put a material on a shader, as the material page's Shader row does: `shader` is a custom shader asset's guid (the material laid out by its cooked properties, every value whose name, type and size fit kept; the shader must have cooked: asset_cook first), or `pbr` / `unlit` for a built-in. Saves the material; asset_cook to see it. Returns the material's properties after. Use this, not asset_data_write of its shaderId, which leaves the material in its old layout.
			""",
			schema.Build(), .Overwrites,
			new (arguments, outResult, outError) => Set(session, arguments, outResult, outError));
	}

	private static Object Read(Sedulous.Content.Instance instance)
	{
		let object = (instance != null) ? instance.ReadObject() : null;
		return (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) : null;
	}

	private static bool Set(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
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

		if ((shaderText == "pbr") || (shaderText == "unlit"))
		{
			MaterialShaderLayout.SetBuiltInShader(material.Source, shaderText == "unlit");
		}
		else
		{
			if (!(Guid.Parse(shaderText) case .Ok(let shaderId)))
			{
				outError.AppendF("'{}' is neither a shader asset's guid nor pbr or unlit", shaderText);
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
		return true;
	}
}
