using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Editor.Mcp;
using NativeSample.Notes;

namespace NativeSample;

/// NativeSample.Tooling: the Tooling part of the reference game's plugin package, loaded by the
/// editor, the exporter and the MCP host. Its load adds an MCP tool, nativesample_notes, that
/// every MCP host serves while the plugin is loaded: the open project's notes (the Pipeline part's
/// asset type), each with its text. It leaves every host with the plugin.
[AlwaysInclude]
class NativeSampleToolingPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");
	public const String cTool = "nativesample_notes";

	static this()
	{
		PluginRegistry.Register(new NativeSampleToolingPart());
	}

	public override StringView PluginId => "nativesample";
	public override PluginPartKind Kind => .Tooling;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		let tools = context.Find<McpPluginServices>();
		if (tools == null)
			return;
		tools.AddTools(new (target) =>
			{
				let session = target.Session;
				target.RegisterTool(cTool, "The open project's notes (NativeSample's own asset type), each its name, guid and text.",
					scope SchemaBuilder().Build(), .ReadOnly,
					new (arguments, outResult, outError) =>
					{
						if (!session.IsOpen)
						{
							outError.Append("no project is open (call project_open first)");
							return false;
						}
						let notes = JsonValue.MakeArray();
						Notes.ForEach(session.Project.SourceDb.RootGroup, scope [&](instance) =>
							{
								let note = JsonValue.MakeObject();
								note.Set("name", JsonValue.MakeString(instance.Name));
								note.Set("guid", JsonValue.MakeString(instance.Id.ToString(.. scope .())));
								let read = instance.ReadObject();
								defer delete read;
								if (let asset = read as NoteAsset)
									note.Set("text", JsonValue.MakeString(asset.Text));
								notes.Add(note);
							});
						outResult.Set("count", JsonValue.MakeNumber(notes.Count));
						outResult.Set("notes", notes);
						return true;
					});
			});
	}
}
