using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Engine.Particles;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A particle effect on an emitter entity, prewarmed so the shot shows it mid burst.
class ParticleThumbnailGenerator : ISceneThumbnailGenerator
{
	private EntityHandle mEmitter = .Invalid;
	private bool mStaged = false;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("ParticleEffectAsset");

	public bool NeedsPrivateScene => true;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		let manager = stage.GetSystem<ParticleEffectComponentManager>();
		if (manager == null)
			return .Failed;
		if (!mStaged)
		{
			let emitter = stage.CreateEntity("ThumbEmitter");
			let component = manager.Add(emitter);
			component.EffectAsset.SetId(id);
			component.EffectAsset.Bind(resources);
			mEmitter = emitter;
			mStaged = true;
		}
		let component = manager.Get(mEmitter);
		if (component == null)
			return .Failed;
		if (component.EffectAsset.Get == null)
		{
			if (!component.EffectAsset.IsBound || (component.EffectAsset.State == .Failed))
				return .Failed;
			return .Pending;
		}
		outFraming.Radius = 2.5f;
		outFraming.PrewarmSteps = 45; // 0.75s at the fixed step
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage)
	{
		mStaged = false;
		mEmitter = .Invalid;
	}
}
