using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Core;

/// The editor's USER LEVEL settings store, <user-data>/editor.settings.xml: the cross
/// project preference sections and the file plumbing. Hand editable XML, like the project
/// files. EditorSerializables.RegisterAll runs first so Load can instantiate the sections.
static class EditorSettingsStore
{
	public const String cFileName = "editor.settings.xml";

	/// NotFound when the file is absent: a first run, the store staying empty and every
	/// section reading as its defaults.
	public static Result<void, ErrorCode> Load(IFileSystem root, Settings outStore, StringView fileName = cFileName)
	{
		let stream = root.Open(fileName, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		return outStore.Load(stream, factory);
	}

	public static Result<void, ErrorCode> Save(IWritableFileSystem root, Settings store, StringView fileName = cFileName)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let error))
			return .Err(error);
		return root.Save(fileName, buffer.Bytes);
	}

	/// The canonical location, <user-data>/editor.settings.xml; the editor uses these, the
	/// tests the explicit forms above.
	public static Result<void, ErrorCode> LoadFromUserData(Settings outStore)
	{
		let fs = scope NativeFileSystem(GetUserDataDirectory(.. scope .()));
		return Load(fs, outStore);
	}

	public static Result<void, ErrorCode> SaveToUserData(Settings store)
	{
		let dir = GetUserDataDirectory(.. scope .());
		CreateDirectory(dir);
		let fs = scope NativeFileSystem(dir);
		return Save(fs, store);
	}
}
