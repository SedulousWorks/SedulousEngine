using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Dialogue;

/// Dialogue.Editor: the Editor part of the engine's official dialogue package, which only the editor
/// loads. Load adds the cast's and the dialogue assets' pages to the editor's page registry, where
/// the editor offers its context and its page services; Unload removes them, closing the pages they
/// made, since those run this part's code.
[AlwaysInclude]
class DialogueEditorPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	/// The page factories' keys while loaded.
	private List<uint64> mPages = new .() ~ delete _;

	static this()
	{
		PluginRegistry.Register(new DialogueEditorPart());
	}

	public override StringView PluginId => "dialogue";
	public override PluginPartKind Kind => .Editor;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		let editor = context.Find<EditorContext>();
		let services = context.Find<AssetPageServicesSource>();
		if ((editor == null) || (services == null))
			return;
		DialoguePages.Register(editor, services, mPages);
	}

	public override void Unload(PluginContext context)
	{
		if (let editor = context.Find<EditorContext>())
		{
			for (let key in mPages)
				editor.RemovePageFactory(key);
		}
		mPages.Clear();
	}
}
