using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Sequence;

namespace Sedulous.Sequence.Resource;

/// The runtime product: a sequence, shared and unchanged by every play of it.
class SequenceResource
{
	public Sedulous.Sequence.Sequence Sequence = new .() ~ delete _;
}

/// The cooked form: the sequence as Sequence.Serialize writes it (each track as its kind's type
/// name and fields).
class SequenceSource : ISerializable
{
	public Sedulous.Sequence.Sequence Sequence = new .() ~ delete _;

	public void Serialize(ISerializer ar) => Sequence.Serialize(ar);
}

/// Loads a cooked SequenceSource into a SequenceResource and binds what its tracks refer to.
class SequenceFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<SequenceResource>();
	public Type CookedType => typeof(SequenceSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let source = stored as SequenceSource;
		if (source == null)
			return null;

		// The source's sequence moves into the product whole.
		let product = new SequenceResource();
		Swap!(product.Sequence, source.Sequence);
		for (let track in product.Sequence.Tracks)
		{
			if (track != null)
				track.ResolveResources(manager);
		}
		return product;
	}
}

/// Registration for the sequence resource: the cooked source, the resource and the nested track
/// kind, besides the sequence library's own kinds.
static class SequenceResources
{
	/// This library's resource module: its type registration and the factory the engine
	/// composition creates from.
	public static ResourceModule Module => sModule ?? (sModule = new .("sequence", () => RegisterAll(), new .(
		.ByDefault<SequenceResource, SequenceSource, SequenceFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The source into the global registry unless another is given. The track kinds always go
	/// into the global one, where a sequence's reader finds them.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf("Sedulous.Sequence.Resource.SequenceSource"), () => new SequenceSource());
		SequenceTracks.RegisterTypes();
		SequenceTracks.Register<NestedSequenceTrack>();
	}
}
