using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource;

/// Opens a scene stream in whichever encoding it turns out to be in.
///
/// The reader OWNS the serializer and, for text, the parsed document behind it, because an
/// XML serializer reads through the document and a caller that let it go would be reading
/// freed nodes. Scope one of these around the read.
class SceneStreamReader
{
	private SceneStreamEncoding mEncoding = .Binary;
	private XmlDocument mDocument = null ~ delete _;
	private Serializer mSerializer = null ~ delete _;

	public SceneStreamEncoding Encoding => mEncoding;

	/// The serializer to read `stream` with, or null when it is text that will not parse.
	public Result<Serializer> Open(IStream stream)
	{
		mEncoding = SceneStreamFormat.DetectEncoding(stream);

		if (mEncoding == .Binary)
		{
			mSerializer = new BinarySerializer(stream, .Read);
			return .Ok(mSerializer);
		}

		let remaining = (int)(stream.Size() - stream.Tell());
		let bytes = scope List<uint8>();
		bytes.Resize(remaining);
		if ((remaining > 0) && (stream.Read(bytes) != remaining))
			return .Err;

		mDocument = new XmlDocument();
		if (mDocument.Parse(.((char8*)bytes.Ptr, remaining)) != .Ok)
			return .Err;

		mSerializer = new XmlSerializer(mDocument);
		return .Ok(mSerializer);
	}
}
