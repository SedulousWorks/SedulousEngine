using System;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// Cooks the filled slots into the cue's variant table.
class SoundCueAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(SoundCueAsset);
	public Type ProductType => typeof(SoundCueSource);

	/// Two: an empty cue cooks to a valid product with no variants rather than failing, so a
	/// draft re-cooks like anything else.
	public int32 Version => 2;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let cue = (SoundCueAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let cooked = scope SoundCueSource();
		for (int i < cue.Slots.Count)
		{
			let slot = cue.Slots[i];
			if (slot.ClipId == Guid.Empty)
				continue;
			if (slot.Weight <= 0.0f)
			{
				GlobalLog(.Warning,
					"Audio: sound cue slot {} names a clip but weighs nothing, so it is disabled", i);
				continue;
			}
			cooked.ClipId.Add(slot.ClipId);
			cooked.Weight.Add(slot.Weight);
		}

		// A cue with NO playable variant cooks to a valid empty product rather than failing.
		// A freshly created draft must never poison a whole cook or an export, and the runtime
		// is built for it: resolving one answers with no variant and every consumer guards
		// that, so it is a silent no-op. The draft state belongs in the editor's own status,
		// not in a failed build.
		cooked.Mode = cue.Mode;
		cooked.PitchMin = Math.Min(cue.PitchMin, cue.PitchMax);
		cooked.PitchMax = Math.Max(cue.PitchMin, cue.PitchMax);
		cooked.VolumeMin = Math.Min(cue.VolumeMin, cue.VolumeMax);
		cooked.VolumeMax = Math.Max(cue.VolumeMin, cue.VolumeMax);
		return context.Output.WriteObject(cooked);
	}
}
