using System;
using Sedulous.Content;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Script;

/// Opens a ScriptClassAsset in the script page, against the script surface the host bound.
class ScriptClassPageFactory : IEditorPageFactory
{
	/// Borrowed; null leaves the pages' API views empty.
	private ScriptSurface mSurface;

	public this(ScriptSurface surface)
	{
		mSurface = surface;
	}

	public Type PrimaryType => typeof(ScriptClassAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new ScriptEditorPage(context, instance, mSurface);
}
