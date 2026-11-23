using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Sequence.Resource;

namespace Sedulous.Sequence.Pipeline;

/// The authored sequence.
///
/// The source IS the cooked form, edited in place by the editor, so the builder writes it through
/// unchanged: the asset carries nothing only the editor needs yet.
[DisplayName("Sequence")]
[Serializable]
class SequenceAsset : Asset
{
	public SequenceSource Source = new .() ~ delete _;
}

/// Cooks the authored sequence into its product, written verbatim: the runtime factory reads it
/// back into the sequence every play shares.
class SequenceAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(SequenceAsset);
	public Type ProductType => typeof(SequenceSource);
	public int32 Version => 1;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let authored = (SequenceAsset)asset;
		return context.Output.WriteObject(authored.Source);
	}
}

/// The sequence domain's New Asset creator: an empty sequence, in the picked group or the root.
static class SequenceCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Sequence", "Animation", typeof(SequenceAsset), new (context) =>
			CreateSequence(context.Target, context.Name)));
	}

	/// An empty sequence in `target`, named `requestedName` made unique ("Sequence" when empty).
	public static Instance CreateSequence(Group target, StringView requestedName)
	{
		if (target == null)
			return null;
		return AssetCreator.CreateWritten(target, requestedName.IsEmpty ? "Sequence" : requestedName,
			typeof(SequenceAsset), scope SequenceAsset());
	}
}

/// Registration for the sequence authoring types.
///
/// Without it an instance writes its asset fine and reads it back as null, which looks like a
/// missing file rather than a missing call.
[SerializableRegistry]
static class SequencePipeline
{
}
