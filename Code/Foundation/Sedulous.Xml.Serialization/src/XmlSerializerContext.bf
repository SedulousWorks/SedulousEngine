using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml;

namespace Sedulous.Xml.Serialization;

/// Holds an XML serializer and the document it works on.
///
/// A text backend cannot write straight through: it builds a document and only then knows
/// what the bytes are. This is what keeps that document alive for as long as the
/// serializer refers to it, and writes it out at the end.
class XmlSerializerContext : SerializerContext
{
	/// Only set for a read: the parsed source. A write builds its own inside the
	/// serializer.
	private XmlDocument mDocument ~ delete _;
	private XmlSerializer mSerializer ~ delete _;

	public this(IStream stream, SerializeMode mode)
	{
		if (mode == .Write)
		{
			mSerializer = new XmlSerializer();
			return;
		}

		mDocument = new XmlDocument();

		let size = stream.Size();
		if (size > 0)
		{
			let text = scope String();
			let raw = text.PrepareBuffer((int)size);
			let read = stream.Read(.((uint8*)raw, (int)size));
			// A short read leaves the string sized for what was asked rather than what
			// arrived, so the tail would be uninitialised.
			if (read < (int)size)
				text.Length = read;

			// A parse failure leaves an empty document, and every read against it then
			// fails with NotFound rather than crashing.
			mDocument.Parse(text);
		}

		mSerializer = new XmlSerializer(mDocument);
	}

	public override Serializer Serializer => mSerializer;

	public override void Flush(IStream output)
	{
		if (mSerializer.Mode != .Write)
			return;

		let text = scope String();
		mSerializer.GetOutput(text);
		if (!text.IsEmpty)
			output.Write(.((uint8*)text.Ptr, text.Length));
	}
}
