using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Core;

/// One versioned [Serializable] root as an XML file on a mount: the manifest's shape, for
/// the export presets, the templates and the export roots. A file written under another
/// data version is refused by the payload envelope rather than guessed at.
static class XmlDocumentFile
{
	/// NotFound when the file is absent.
	public static Result<void, ErrorCode> Load(IFileSystem root, ISerializable document, StringView fileName)
	{
		let stream = root.Open(fileName, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(stream, .Read);
		if ((context == null) || (context.Serializer == null))
		{
			delete context;
			return .Err(.Internal);
		}
		defer delete context;
		document.Serialize(context.Serializer);
		return context.Serializer.Status;
	}

	public static Result<void, ErrorCode> Save(IWritableFileSystem writable, ISerializable document, StringView fileName)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(buffer, .Write);
		if ((context == null) || (context.Serializer == null))
		{
			delete context;
			return .Err(.Internal);
		}
		defer delete context;
		document.Serialize(context.Serializer);
		if (context.Serializer.Status case .Err(let error))
			return .Err(error);
		context.Flush(buffer);
		return writable.Save(fileName, buffer.Bytes);
	}
}
