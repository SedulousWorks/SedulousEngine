using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// What a project's manifest says of itself before its settings are read: its name and the engine
/// version that last saved it. Read by key from Project.xml's object element, where the manifest
/// writes them, without the settings' schema or their data version: a manifest an engine with
/// newer settings wrote, which ProjectManifest.Load refuses, still gives both, so a project
/// manager built at one version can list any project and route it to the engine it needs.
class ProjectHeader
{
	public String Name = new .() ~ delete _;
	/// Empty for a manifest from before the stamp.
	public String EngineVersion = new .() ~ delete _;

	public void Clear()
	{
		Name.Clear();
		EngineVersion.Clear();
	}

	/// Reads the header of the project in `directory` into `outHeader`. NotFound when the folder
	/// holds no manifest; InvalidArgument when the manifest is not one (it does not parse, or has
	/// no object to read). A key the manifest lacks reads as empty.
	public static Result<void, ErrorCode> Read(StringView directory, ProjectHeader outHeader)
	{
		outHeader.Clear();
		if (!DirectoryExists(directory))
			return .Err(.NotFound);
		let fs = scope NativeFileSystem(directory);
		let stream = fs.Open(ProjectLayout.ManifestFile, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(stream, .Read);
		if (context == null)
			return .Err(.Internal);
		defer delete context;
		let archive = context.Serializer;
		if (archive == null)
			return .Err(.Internal);

		// The data versions come first; they are passed by, not checked: whatever the settings'
		// layout, the two keys keep theirs.
		if (archive.HasKey("dataVersions"))
		{
			uint32 count = 0;
			archive.Key("dataVersions");
			archive.BeginArray(ref count);
			archive.EndArray();
		}
		archive.BeginObject();
		if (!archive.IsOk)
			return .Err(.InvalidArgument);
		ReadKey(archive, "name", outHeader.Name);
		ReadKey(archive, "engineVersion", outHeader.EngineVersion);
		archive.EndObject();
		return .Ok;
	}

	/// The string under `key` in the current object into `outValue`, left empty when there is none.
	private static void ReadKey(Sedulous.Core.Serialization.Serializer archive, StringView key, String outValue)
	{
		if (!archive.HasKey(key))
			return;
		archive.Key(key);
		archive.Text(outValue);
	}
}
