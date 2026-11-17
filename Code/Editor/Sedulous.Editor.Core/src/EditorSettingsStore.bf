using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
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
	/// section reading as its defaults. A file there that does not read is set aside first
	/// ("<file>.unreadable", UnreadableFiles.SetAside), so the defaults this run saves never
	/// write over the sections it held (the recent projects most painfully); the log says
	/// where it went.
	public static Result<void, ErrorCode> Load(IFileSystem root, Settings outStore, StringView fileName = cFileName)
	{
		Result<void, ErrorCode> loaded;
		{
			// Closed at the end of this block, before the file may be moved aside below.
			let stream = root.Open(fileName, .Read);
			if (stream == null)
				return .Err(.NotFound);
			defer delete stream;
			let factory = XmlSerializerFactory();
			defer delete factory;
			loaded = outStore.Load(stream, factory);
		}
		if (loaded case .Ok)
			return .Ok;

		let aside = scope String();
		if (UnreadableFiles.SetAside(root, fileName, aside) case .Ok)
			GlobalLog(.Error, "Editor: {} could not be read; it was moved to {} and the settings start again", fileName, aside);
		else
			GlobalLog(.Error, "Editor: {} could not be read, nor moved aside; the settings are not saved over it", fileName);
		return loaded;
	}

	/// True when a settings file is there and does not read: a save refuses to replace it (a load
	/// that could not set it aside leaves it in place, and the sections it held are only there).
	public static bool IsSettingsFileUnreadable(IFileSystem root, StringView fileName)
	{
		let stream = root.Open(fileName, .Read);
		if (stream == null)
			return false;
		defer delete stream;
		let probe = scope Settings();
		let factory = XmlSerializerFactory();
		defer delete factory;
		return probe.Load(stream, factory) case .Err;
	}

	/// Persists the store to `root` (XML). Refused (AlreadyExists) over a file there that does not
	/// read, and NotSupported for a file system that cannot be written.
	public static Result<void, ErrorCode> Save(IFileSystem root, Settings store, StringView fileName = cFileName)
	{
		let writable = root as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);
		if (IsSettingsFileUnreadable(root, fileName))
		{
			GlobalLog(.Error, "Editor: {} is there and does not read; not saved over it", fileName);
			return .Err(.AlreadyExists);
		}
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let error))
			return .Err(error);
		return writable.Save(fileName, buffer.Bytes);
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
