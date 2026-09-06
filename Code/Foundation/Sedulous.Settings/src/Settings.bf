using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;

namespace Sedulous.Settings;

/// A typed, versioned, backend agnostic settings store.
///
/// A SECTION is a serializable type, and the store holds one instance per type, created on
/// first access so an absent section simply reads as its declared defaults. One store is
/// one file's worth; layering user settings over project settings means composing two
/// stores, not teaching one store about precedence.
///
/// Load and Save go through the serializer factory, so the CALLER picks the backend: a
/// text one for a file someone edits by hand, binary for a test. Streams only, with no
/// VFS: the caller opens the file and hands over the stream, which keeps this just above
/// Core where both the runtime and an editor can reach it.
class Settings
{
	/// Written into POSITIONAL streams only. A self describing backend carries its own
	/// structure and needs no version stamp, so text files on disk are unaffected by this.
	public const uint32 FormatVersion = 1;

	private Dictionary<uint64, SettingsSection> mSections = new .() ~ DeleteDictionaryAndValues!(_);
	private List<UnknownSection> mUnknown = new .() ~ DeleteContainerAndItems!(_);

	/// Fires with a section's type name when something announces a change to it.
	public Event<delegate void(StringView)> OnChanged ~ _.Dispose();

	public int SectionCount => mSections.Count;

	/// Sections whose type this build could not create on the last load, kept verbatim so
	/// the next save re-emits them. Zero for a store whose sections are all known.
	public int UnknownSectionCount => mUnknown.Count;

	/// The section of type T, created with its declared defaults on first access. The
	/// reference stays valid for the store's lifetime, and the STORE owns it.
	public T Section<T>() where T : ISerializable, class, new, delete
	{
		let name = scope String();
		typeof(T).GetFullName(name);
		let id = TypeIdOf(name);

		if (mSections.TryGetValue(id, let existing))
			return (T)existing.Object;

		let entry = new SettingsSection();
		entry.TypeName.Set(name);
		entry.Object = new T();
		mSections[id] = entry;
		return (T)entry.Object;
	}

	/// The section of type T if it is already there, and null otherwise. A read only peek
	/// that does NOT create it, for code that wants to know whether something was
	/// configured rather than what its default is.
	public T Find<T>() where T : ISerializable, class
	{
		let name = scope String();
		typeof(T).GetFullName(name);

		if (mSections.TryGetValue(TypeIdOf(name), let existing))
			return (T)existing.Object;
		return null;
	}

	/// Announces that section T was changed.
	///
	/// Explicit because the store hands out a reference and cannot see writes through it.
	/// A caller that mutates a section and stays quiet gets no notification, which is the
	/// honest consequence of handing out the object itself.
	public void MarkChanged<T>() where T : ISerializable, class
	{
		let name = scope String();
		typeof(T).GetFullName(name);
		OnChanged(name);
	}

	/// Writes every live section, and re-emits anything preserved from a load.
	public Result<void, ErrorCode> Save(IStream stream, SerializerFactory factory)
	{
		let context = factory(stream, .Write);
		if (context == null)
			return .Err(.Internal);
		defer delete context;

		let archive = context.Serializer;
		if (archive == null)
			return .Err(.Internal);

		if (!archive.IsSelfDescribing)
		{
			var version = FormatVersion;
			archive.Key("formatVersion");
			archive.Scalar(&version, .UInt32);
		}

		var count = (uint32)(mSections.Count + mUnknown.Count);
		archive.Key("sections");
		archive.BeginArray(ref count);

		for (let entry in mSections)
		{
			let section = entry.value;
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(section.TypeName);
			// Framed, so a reader that cannot create this type can capture or skip it
			// rather than losing its place in the stream.
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			section.Object.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
		}

		// Appended after the known ones, so the order within each kind stays stable.
		for (let section in mUnknown)
		{
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(section.TypeName);
			archive.BeginFramedRegion();
			archive.RawRemainder(section.Payload);
			archive.EndFramedRegion();
			archive.EndObject();
		}

		archive.EndArray();
		if (!archive.IsOk)
			return archive.Status;

		context.Flush(stream);
		return .Ok;
	}

	/// Reads sections, replacing any live instance of the same type.
	///
	/// A section whose type is not registered is captured verbatim rather than abandoned,
	/// which is what stops an older build from quietly deleting a newer one's settings.
	public Result<void, ErrorCode> Load(IStream stream, SerializerFactory factory)
	{
		let context = factory(stream, .Read);
		if (context == null)
			return .Err(.Internal);
		defer delete context;

		let archive = context.Serializer;
		if (archive == null)
			return .Err(.Internal);

		// Rebuilt from what this load could not resolve, so a store that loads a file it
		// fully understands stops carrying an older file's leftovers.
		ClearUnknown();

		if (!archive.IsSelfDescribing)
		{
			uint32 version = 0;
			archive.Key("formatVersion");
			archive.Scalar(&version, .UInt32);
			// Refused rather than guessed at: a positional stream of another version
			// misparses into plausible nonsense.
			if (!archive.IsOk || (version != FormatVersion))
				return .Err(.NotSupported);
		}

		uint32 count = 0;
		archive.Key("sections");
		archive.BeginArray(ref count);

		for (uint32 i < count)
		{
			archive.BeginObject();

			let typeName = scope String();
			archive.Key("typeName");
			archive.Text(typeName);
			if (!archive.IsOk)
				return archive.Status;

			let id = TypeIdOf(typeName);
			let object = SerializableRegistry.Create(id);

			archive.BeginFramedRegion();
			if (object != null)
			{
				archive.Key("payload");
				archive.BeginObject();
				object.Serialize(archive);
				archive.EndObject();

				if (mSections.TryGetValue(id, let previous))
				{
					delete previous;
					mSections.Remove(id);
				}

				let entry = new SettingsSection();
				entry.TypeName.Set(typeName);
				entry.Object = object;
				mSections[id] = entry;
			}
			else
			{
				let preserved = new UnknownSection();
				preserved.TypeName.Set(typeName);
				if (archive.RawRemainder(preserved.Payload))
				{
					mUnknown.Add(preserved);
					GlobalLog(.Warning, "Settings: preserving unknown section '{}'", typeName);
				}
				else
				{
					// A backend with no frame to capture cannot preserve it. Named,
					// because the setting is about to disappear on the next save.
					delete preserved;
					GlobalLog(.Warning,
						"Settings: dropping unknown section '{}', the backend cannot preserve it", typeName);
				}
			}
			archive.EndFramedRegion();
			archive.EndObject();

			if (!archive.IsOk)
				return archive.Status;
		}

		archive.EndArray();
		return archive.IsOk ? .Ok : archive.Status;
	}

	private void ClearUnknown()
	{
		for (let section in mUnknown)
			delete section;
		mUnknown.Clear();
	}
}
