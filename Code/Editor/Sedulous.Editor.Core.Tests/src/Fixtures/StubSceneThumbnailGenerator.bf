using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Covers the type it is made for; never driven, the STAGE owns Stage.
class StubSceneThumbnailGenerator : ISceneThumbnailGenerator
{
	private String mType = new .() ~ delete _;
	private bool mPrivate;
	/// What it names a document's content by (nought: the cook's recipe hash does).
	private uint64 mContentHash;

	public this(StringView type, bool privateScene = false, uint64 contentHash = 0)
	{
		mType.Set(type);
		mPrivate = privateScene;
		mContentHash = contentHash;
	}

	public uint64 ContentHash(Instance instance) => mContentHash;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add(mType);
	public bool NeedsPrivateScene => mPrivate;
	public ThumbnailStageStep Stage(Guid id, Scene scene, ResourceManager resources, ref ThumbnailFraming outFraming) => .Failed;
	public void Unstage(Scene scene) {}
}
