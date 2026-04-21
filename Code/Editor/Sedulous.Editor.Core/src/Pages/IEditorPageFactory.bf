namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Creates editor pages for specific file types.
/// Plugins register these with EditorContext.RegisterPageFactory().
interface IEditorPageFactory
{
	/// File extensions this factory handles (e.g. ".scene", ".mat", ".anim").
	void GetSupportedExtensions(List<String> outExtensions);

	/// Whether this factory can open the given file.
	bool CanOpen(StringView path);

	/// Create an editor page for the given file.
	IEditorPage CreatePage(StringView path, EditorContext context);
}
