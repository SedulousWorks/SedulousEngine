using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain.Tests;

/// Records what a brush registers, keeping the last closure so a test can run it against
/// a real database.
class FakeAssetEditSink : IAssetEditSink
{
	public int32 Count = 0;
	public Guid LastId = .();
	/// The history the last edit was registered with: its page's save writes it.
	public EditorCommandStack LastOwner = null;
	public AssetEditPersist LastPersist = null ~ delete _;

	public bool HasPersist => LastPersist != null;

	public void RegisterAssetEdit(EditorCommandStack owner, Guid assetId, AssetEditPersist persist)
	{
		Count++;
		LastOwner = owner;
		LastId = assetId;
		delete LastPersist;
		LastPersist = persist;
	}
}
