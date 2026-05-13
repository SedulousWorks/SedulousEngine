using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Editor.Core;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .propanim files.
/// Stub - real editor needs a curve-editor widget that doesn't exist yet.
class PropAnimEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".propanim"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".propanim", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let page = new ResourceEditorPage(path, "Property Animation");
		page.SetContentView(TextureEditorPageFactory.BuildPlaceholder("Property Animation", path));
		return page;
	}
}
