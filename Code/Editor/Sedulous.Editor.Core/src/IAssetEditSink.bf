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
	/// captures no database handle.
	void RegisterAssetEdit(Guid assetId, AssetEditPersist persist);
}
