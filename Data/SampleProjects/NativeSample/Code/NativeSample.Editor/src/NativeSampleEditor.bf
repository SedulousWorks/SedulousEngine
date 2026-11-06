using System;
using Sedulous.Runtime;
using Sedulous.Editor.Core;
using NativeSample.Notes;

namespace NativeSample;

/// NativeSample.Editor: the Editor part of the reference game's plugin package, loaded by the
/// editor alone. Its load adds an editor action, Project > Native Sample Notes, that says how many
/// notes (the Pipeline part's asset type) the open project has; its unload removes it, since the
/// action registry is not one the recording reverses.
[AlwaysInclude]
class NativeSampleEditorPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");
	public const String cAction = "nativesample.notes";

	static this()
	{
		PluginRegistry.Register(new NativeSampleEditorPart());
	}

	public override StringView PluginId => "nativesample";
	public override PluginPartKind Kind => .Editor;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		let editor = context.Find<EditorContext>();
		if (editor == null)
			return;
		let action = new EditorActionDeclaration(cAction, "Native Sample Notes", "Say how many notes the project has (NativeSample's own asset type)",
			"Project/Native Sample Notes", 900);
		action.ReadOnly = true;
		action.Execute = new [=editor] (page) =>
			{
				if (editor.Project == null)
					return;
				int count = 0;
				Notes.ForEach(editor.Project.SourceDb.RootGroup, scope [&](instance) => { count++; });
				let plural = (count == 1) ? "" : "s";
				editor.Notify(.Info, scope $"The project has {count} note{plural}.");
			};
		editor.Actions.Register(action);
	}

	public override void Unload(PluginContext context)
	{
		if (let editor = context.Find<EditorContext>())
			editor.Actions.Unregister(cAction);
	}
}
