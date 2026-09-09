using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Physics.Resource.Tests;

/// Binary writes straight to the stream, so there is nothing to flush.
class BinarySerializerContext : SerializerContext
{
	private BinarySerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		mSerializer = new BinarySerializer(stream, mode);
	}

	public override Serializer Serializer => mSerializer;
}
