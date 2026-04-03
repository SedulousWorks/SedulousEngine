namespace Sedulous.Serialization.OpenDDL;

using System;
using Sedulous.Serialization;
using Sedulous.OpenDDL;

/// ISerializerProvider implementation using the OpenDDL format.
/// Register this at app startup for human-readable scene/resource files.
class OpenDDLSerializerProvider : ISerializerProvider
{
	public Serializer CreateWriter()
	{
		return OpenDDLSerializer.CreateWriter();
	}

	public Serializer CreateReader(StringView text)
	{
		let desc = new SerializerDataDescription();
		if (desc.ProcessText(text) != .Ok)
		{
			delete desc;
			return null;
		}

		return new OwningOpenDDLReader(desc);
	}

	public void GetOutput(Serializer writer, String output)
	{
		if (let oddlWriter = writer as OpenDDLSerializer)
			oddlWriter.GetOutput(output);
	}
}

/// OpenDDL reader that owns its DataDescription.
/// Deleting the reader also deletes the parsed document.
class OwningOpenDDLReader : OpenDDLSerializer
{
	private DataDescription mOwnedDocument;

	public this(DataDescription document)
	{
		mMode = .Read;
		mOwnedDocument = document;
		mDocument = document;
		mCurrentStructure = document.RootStructure;
		mChildIndex = 0;
	}

	public ~this()
	{
		delete mOwnedDocument;
	}
}
