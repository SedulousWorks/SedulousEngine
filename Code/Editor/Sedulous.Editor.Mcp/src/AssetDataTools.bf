using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Editor.Mcp;

/// asset_data_read / asset_data_write: any asset's stored object as the text its envelope
/// holds, for the data assets no other tool edits (an input map's actions and bindings, a
/// material's parameters, a physics material, a sound cue, a bus layout). The write reads the
/// agent's text the way a load reads the stored envelope, so what it accepts is exactly what
/// the engine can load; then it stores the object and announces the write, as scene_write does.
static class AssetDataTools
{
	public static void Register(McpServer server, ProjectSession session)
	{
		let readSchema = scope SchemaBuilder();
		readSchema.Str("guid", "the asset's guid (asset_list)", true);
		server.RegisterTool("asset_data_read",
			"An asset's stored object as its envelope's XML: its guid, its typeName, the dataVersions and the `payload` holding every field. Edit the payload and hand the whole text to asset_data_write. Enum fields are stored as numbers: type_info on the field's type names the cases. A scene's or prefab's content is not here (scene_read and prefab_read have it), nor is an imported asset's bulk data.",
			readSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let instance = Resolve(session, arguments, outError);
				if (instance == null)
					return false;
				let stream = instance.OpenEnvelope();
				if (stream == null)
				{
					outError.AppendF("'{}' has no stored envelope", instance.Name);
					return false;
				}
				defer delete stream;
				let text = scope String();
				if (!McpTools.ReadAllText(stream, text))
				{
					outError.AppendF("could not read '{}''s envelope", instance.Name);
					return false;
				}
				Identity(instance, outResult);
				outResult.Set("xml", JsonValue.MakeString(text));
				return true;
			});

		let writeSchema = scope SchemaBuilder();
		writeSchema.Str("guid", "the asset's guid", true);
		writeSchema.Str("xml", "the whole envelope, as asset_data_read gave it, with the payload edited", true);
		server.RegisterTool("asset_data_write",
			"Replace an asset's stored object with an edited envelope from asset_data_read. The text must name the same guid and typeName and carry this build's dataVersions, and its payload must read as that type the way a load reads it; anything else is refused and nothing changes. The object is stored normalized (every field, in its order), the editor told of the change (an open page reloads when clean), and a cook picks it up. asset_cook before a runtime needs it.",
			writeSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let instance = Resolve(session, arguments, outError);
				if (instance == null)
					return false;
				let xml = McpTools.ArgString(arguments, "xml", .. scope .());
				let stream = scope MemoryStream();
				stream.Write(.((uint8*)xml.Ptr, xml.Length));
				stream.Seek(0, .Begin);
				let reason = scope String();
				let object = instance.ReadObjectFrom(stream, reason);
				if (object == null)
				{
					outError.AppendF("refused - the text does not load as '{}': {}. Nothing was written.", instance.Name, reason);
					return false;
				}
				defer delete object;
				if (instance.WriteObject(object) case .Err)
				{
					outError.AppendF("could not write '{}'", instance.Name);
					return false;
				}
				if (session.OnAssetWritten != null)
					session.OnAssetWritten(instance.Id);
				Identity(instance, outResult);
				outResult.Set("written", JsonValue.MakeBool(true));
				return true;
			});
	}

	private static Instance Resolve(ProjectSession session, JsonValue arguments, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return null;
		}
		if (!McpTools.ParseGuid(McpTools.ArgString(arguments, "guid", .. scope .()), outError, let id))
			return null;
		let instance = session.Project.SourceDb.GetInstance(id);
		if (instance == null)
			outError.AppendF("no asset with guid {} in the open project", id);
		return instance;
	}

	private static void Identity(Instance instance, JsonValue outResult)
	{
		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("type", JsonValue.MakeString(instance.TypeName));
	}
}
