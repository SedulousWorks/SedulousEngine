using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// The binary format as a context, so the same database can be driven by either backend.
///
/// Binary writes straight to the stream, so there is nothing to flush at the end. The XML
/// side needs a context because it has to build a document first; this exists so the two
/// can be compared through one interface.
class BinarySerializerContext : SerializerContext
{
	private BinarySerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		mSerializer = new BinarySerializer(stream, mode);
	}

	public override Serializer Serializer => mSerializer;
}
