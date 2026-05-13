using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Editor.Core;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .animgraph files.
/// Stub - real graph editor needs a node-graph widget that doesn't exist yet.
class AnimGraphEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".animgraph"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".animgraph", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let page = new ResourceEditorPage(path, "Animation Graph");
		page.SetContentView(TextureEditorPageFactory.BuildPlaceholder("Animation Graph", path));
		return page;
	}
}
