using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Player;

/// Binary writes straight to the stream, so there is nothing to flush.
///
/// Every consumer of the binary format carries one of these, there being no shared home for
/// it yet. It wants lifting into the serialization layer once more than a handful want it.
class BinarySerializerContext : SerializerContext
{
	private BinarySerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		mSerializer = new BinarySerializer(stream, mode);
	}

	public override Serializer Serializer => mSerializer;
}
