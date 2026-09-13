using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Particles;

/// Binary writes straight to the stream, so there is nothing to flush.
///
/// The manager needs one because CLONING an effect is a serialization round trip rather than a
/// copy: the modules are polymorphic, and the round trip is the one piece of code that already
/// knows how to rebuild every one of them.
class BinarySerializerContext : SerializerContext
{
	private BinarySerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		mSerializer = new BinarySerializer(stream, mode);
	}

	public override Serializer Serializer => mSerializer;
}
