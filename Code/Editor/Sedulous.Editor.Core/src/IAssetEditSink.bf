using System;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// A sink for live asset edit persistence closures, terrain sculpt and the brushes to come.
/// EditorContext implements it; the viewport tool framework holds a BORROWED sink so a domain
/// tool registers a write back to source closure WITHOUT the framework depending on the
/// context. The sink outlives every page and tool.
interface IAssetEditSink
{
	/// TAKES OWNERSHIP of `persist`, which is handed the source database at drain time so it
	/// captures no database handle. The edit belongs to the page whose history is `owner` (its
	/// undo is a step there): that page's save writes it, and its Discard, or its close without
	/// saving, drops it. The last edit registered per page and asset wins.
	void RegisterAssetEdit(EditorCommandStack owner, Guid assetId, AssetEditPersist persist);
}
