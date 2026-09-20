using System;
using System.Collections;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Covers the type it is made for; never driven, the STAGE owns Stage.
class StubSceneThumbnailGenerator : ISceneThumbnailGenerator
{
	private String mType = new .() ~ delete _;
	private bool mPrivate;

	public this(StringView type, bool privateScene = false)
	{
		mType.Set(type);
		mPrivate = privateScene;
	}

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add(mType);
	public bool NeedsPrivateScene => mPrivate;
	public ThumbnailStageStep Stage(Guid id, Scene scene, ResourceManager resources, ref ThumbnailFraming outFraming) => .Failed;
	public void Unstage(Scene scene) {}
}
