using Sedulous.Core.IO;

namespace Sedulous.Core.Serialization;

/// A context over the binary serializer, which is what a content database wants when its
/// records are not meant to be read by a person.
///
/// Binary writes straight to the stream, so there is nothing to flush.
///
/// Here rather than in each caller because a content database takes a FACTORY, and every
/// project that stands one up needs the same seventeen lines. Twenty five copies of them had
/// accumulated before this existed.
class BinarySerializerContext : SerializerContext
{
	private BinarySerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		mSerializer = new BinarySerializer(stream, mode);
	}

	public override Serializer Serializer => mSerializer;
}
