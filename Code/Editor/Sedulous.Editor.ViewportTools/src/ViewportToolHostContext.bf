using System;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.ViewportTools;

/// Everything a scene-viewport tool may need at creation, in framework-known types only;
/// a tool that needs page-specific context is created by the page directly. All borrowed;
/// null in headless hosts and tests.
struct ViewportToolHostContext
{
	public Scene Scene = null;
	public EditorCommandStack Commands = null;
	public Selection<Guid> EntitySelection = null;
	/// A tool that edits a cooked product live registers a closure that writes the edit back
	/// to its source asset; the editor save flow drains it.
	public IAssetEditSink AssetEdits = null;
	/// Thumbnails and the source content database, so a tool panel can present asset-backed
	/// choices richly.
	public EditorContext EditorContext = null;
}
