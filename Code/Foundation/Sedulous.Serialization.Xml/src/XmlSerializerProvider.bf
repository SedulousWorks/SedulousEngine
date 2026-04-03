namespace Sedulous.Serialization.Xml;

using System;
using Sedulous.Serialization;
using Sedulous.Xml;

/// ISerializerProvider implementation using the XML format.
class XmlSerializerProvider : ISerializerProvider
{
	public Serializer CreateWriter()
	{
		return XmlSerializer.CreateWriter();
	}

	public Serializer CreateReader(StringView text)
	{
		let doc = new XmlDocument();
		if (doc.Parse(text) != .Ok)
		{
			delete doc;
			return null;
		}

		return new OwningXmlReader(doc);
	}

	public void GetOutput(Serializer writer, String output)
	{
		if (let xmlWriter = writer as XmlSerializer)
			xmlWriter.GetOutput(output);
	}
}

/// XML reader that owns its XmlDocument.
/// Deleting the reader also deletes the parsed document.
class OwningXmlReader : XmlSerializer
{
	private XmlDocument mOwnedDocument;

	public this(XmlDocument document)
	{
		mMode = .Read;
		mOwnedDocument = document;
		mReadDocument = document;
		mCurrentElement = document.RootElement;
		mUnnamedCursorStack.Add(0);
	}

	public ~this()
	{
		delete mOwnedDocument;
	}
}
