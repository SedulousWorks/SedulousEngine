using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Engine.Project;

/// Reading and writing a project manifest over a file system root.
///
/// Project.xml and player.xml are the same payload, so one pair of calls serves both and
/// the file name is the only thing that differs.
static class ProjectManifest
{
	/// Reads a manifest from `root`. NotFound when there is none.
	public static Result<void, ErrorCode> Load(IFileSystem root, ProjectSettings settings,
		StringView fileName = ProjectLayout.ManifestFile)
	{
		let stream = root.Open(fileName, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		// The factory and every context it makes are the CALLER'S to free.
		let factory = XmlSerializerFactory();
		defer delete factory;

		let context = factory(stream, .Read);
		if (context == null)
			return .Err(.Internal);
		defer delete context;

		if (context.Serializer == null)
			return .Err(.Internal);

		// The version envelope belongs to the generated body, so the archive goes straight
		// over: a manifest written under another version is refused there rather than here.
		((ISerializable)settings).Serialize(context.Serializer);
		return context.Serializer.Status;
	}

	/// Writes a manifest to `writable`, re-stamping the engine version as it goes.
	public static Result<void, ErrorCode> Save(IWritableFileSystem writable,
		ProjectSettings settings, StringView fileName = ProjectLayout.ManifestFile)
	{
		settings.EngineVersion.Set(EngineVersion.String);

		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;

		let context = factory(buffer, .Write);
		if (context == null)
			return .Err(.Internal);
		defer delete context;

		if (context.Serializer == null)
			return .Err(.Internal);

		((ISerializable)settings).Serialize(context.Serializer);
		if (context.Serializer.Status case .Err(let error))
			return .Err(error);

		context.Flush(buffer);
		return writable.Save(fileName, buffer.Bytes);
	}
}
