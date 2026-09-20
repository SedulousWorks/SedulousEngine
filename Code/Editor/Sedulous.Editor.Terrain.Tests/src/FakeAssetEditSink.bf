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
	public AssetEditPersist LastPersist = null ~ delete _;

	public bool HasPersist => LastPersist != null;

	public void RegisterAssetEdit(Guid assetId, AssetEditPersist persist)
	{
		Count++;
		LastId = assetId;
		delete LastPersist;
		LastPersist = persist;
	}
}
