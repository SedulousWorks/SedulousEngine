using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Editor.Core;

/// A GPU thumbnail producer: populates an offscreen preview scene for one asset; the STAGE
/// in the preview module owns the camera, the render and the readback around it. Every call
/// is MAIN thread. Stage is called once per frame until it returns Ready or Failed, the
/// stage bounding the retries; Unstage removes exactly what Stage added.
///
/// NeedsPrivateScene false stages into the SHARED persistent scene, cheap, the generator
/// owning persistent entities toggled active per job. True gives each job a FRESH scene with
/// the app's full manager set, destroyed at the job's end: for a generator instantiating
/// arbitrary content, prefabs, scene documents, simulated effects, where teardown by hand or
/// leaked scene state would be the bug.
interface ISceneThumbnailGenerator
{
	void AssetTypeNames(List<StringView> outNames);
	bool NeedsPrivateScene { get; }
	ThumbnailStageStep Stage(Guid id, Scene scene, ResourceManager resources, ref ThumbnailFraming outFraming);
	void Unstage(Scene scene);

	/// A hash of what the thumbnail shows, for a type the cook keeps no record of (a scene or a
	/// prefab document, which no builder cooks): the cache file is named by it, so a change to it
	/// makes a new thumbnail. Nought, the default, leaves it to the cook's recipe hash.
	uint64 ContentHash(Instance instance)
	{
		return 0;
	}

	/// The assets the thumbnail shows (a scene's meshes and materials), for a type named by
	/// ContentHash: their cooked state goes into the cache file's name, so a cook that makes or
	/// remakes one draws the thumbnail again. None, the default.
	void Dependencies(Instance instance, List<Guid> outIds)
	{
	}
}
