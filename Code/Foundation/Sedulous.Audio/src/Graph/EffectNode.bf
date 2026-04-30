namespace Sedulous.Audio.Graph;

using System;
using Sedulous.Audio;

/// Audio graph node that wraps an IAudioEffect for in-place processing.
/// Used by AudioBus to build effect chains in the graph.
public class EffectNode : AudioNode
{
	private IAudioEffect mEffect;
	private bool mOwnsEffect;

	/// The wrapped effect.
	public IAudioEffect Effect => mEffect;

	/// Releases ownership of the effect without disposing it.
	/// After this call, the EffectNode will not delete the effect on Dispose.
	/// Returns the effect for the caller to take ownership.
	public IAudioEffect ReleaseEffect()
	{
		let effect = mEffect;
		mEffect = null;
		mOwnsEffect = false;
		return effect;
	}

	/// Creates an EffectNode wrapping the given effect.
	/// If ownsEffect is true, the node will dispose and delete the effect on cleanup.
	public this(IAudioEffect effect, bool ownsEffect = true)
	{
		mEffect = effect;
		mOwnsEffect = ownsEffect;
	}

	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);

		if (mEffect != null && mEffect.Enabled)
			mEffect.Process(buffer, frameCount, sampleRate);
	}

	public override void Dispose()
	{
		if (mOwnsEffect && mEffect != null)
		{
			mEffect.Dispose();
			delete mEffect;
			mEffect = null;
		}
		base.Dispose();
	}
}
