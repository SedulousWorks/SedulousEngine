using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Script;
using Sedulous.Xml.Serialization;

namespace Sedulous.Engine.GameInstance;

/// A run's save: the values a game keeps between runs (a best time, an unlocked level, its own
/// options), the file they live in, and whether they changed since the last write.
///
/// The host names the file (the player in the user data directory, a Game tab in the project's
/// Editor/ folder); the run's scripts reach it through the `Save` service. The file is an
/// ordinary settings file holding one SaveValues section, written whole and atomically.
class RunSave
{
	private String mPath = new .() ~ delete _;
	/// The file's whole settings store: the values' section, and any section a newer build
	/// wrote, kept so this build's write does not drop it.
	private Settings mStore = new .() ~ delete _;
	private bool mChanged = false;

	/// Names the save's file and reads it. Absent is an empty save; unreadable is an empty save
	/// and a warning, and the file is left as it is until the game writes. An empty path closes
	/// the save: values stay readable but are written nowhere.
	public void Open(StringView path)
	{
		mPath.Set(path);
		delete mStore;
		mStore = new .();
		mChanged = false;
		if (mPath.IsEmpty || !FileExists(mPath))
			return;

		// The load instantiates the section by its name.
		SaveValues.Register();
		let file = scope FileStream(mPath, .Read);
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (!file.IsValid || (mStore.Load(file, factory) case .Err))
		{
			GlobalLog(.Warning, "Save: could not read the save '{}'; starting from an empty save", mPath);
			delete mStore;
			mStore = new .();
		}
	}

	public bool IsOpen => !mPath.IsEmpty;
	public StringView Path => mPath;
	public SaveValues Values => mStore.Section<SaveValues>();

	/// A change the next Flush writes. The facade calls it when a setter reports a change.
	public void MarkChanged() => mChanged = true;
	public bool HasChanges => mChanged;

	/// Writes the values if they changed since the last write. True when the file holds them
	/// afterwards (nothing to write counts); false when the write failed or there is no file.
	public bool Flush()
	{
		if (!IsOpen)
			return false;
		if (!mChanged)
			return true;

		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (mStore.Save(buffer, factory) case .Err)
		{
			GlobalLog(.Warning, "Save: could not encode the save '{}'", mPath);
			return false;
		}
		let directory = scope String();
		PathParent(mPath, directory);
		if (!directory.IsEmpty)
			CreateDirectory(directory);
		if (WriteFileAtomic(mPath, buffer.Bytes) case .Err)
		{
			GlobalLog(.Warning, "Save: could not write the save '{}'", mPath);
			return false;
		}
		mChanged = false;
		// A browser keeps it only once pushed to the page's storage.
		PersistUserData();
		return true;
	}
}

/// `Save`: the calling run's save, as `Save.SetInt("best.level2", 4210)`,
/// `Save.GetInt("best.level2", 0)`. The run writes what changed as it ends; `Flush` writes now.
/// A script outside a run (an editor tool, Simulate) reads every fallback and writes nowhere.
[Scriptable, ServiceFacade("Save")]
class SaveFacade
{
	/// BORROWED: the run's save; null outside a run.
	private RunSave mSave;

	public this(RunSave save)
	{
		mSave = save;
	}

	[Scriptable]
	public bool Has(StringView key) => (mSave != null) && mSave.Values.Has(key);

	[Scriptable]
	public void Remove(StringView key)
	{
		if ((mSave != null) && mSave.Values.Remove(key))
			mSave.MarkChanged();
	}

	/// Forgets every saved value.
	[Scriptable]
	public void Clear()
	{
		if ((mSave != null) && mSave.Values.Clear())
			mSave.MarkChanged();
	}

	[Scriptable]
	public int32 GetInt(StringView key, int32 fallback) => (mSave != null) ? mSave.Values.GetInt(key, fallback) : fallback;

	[Scriptable]
	public void SetInt(StringView key, int32 value)
	{
		if ((mSave != null) && mSave.Values.SetInt(key, value))
			mSave.MarkChanged();
	}

	/// A value saved as an int reads as a float too.
	[Scriptable]
	public float GetFloat(StringView key, float fallback) => (mSave != null) ? mSave.Values.GetFloat(key, fallback) : fallback;

	[Scriptable]
	public void SetFloat(StringView key, float value)
	{
		if ((mSave != null) && mSave.Values.SetFloat(key, value))
			mSave.MarkChanged();
	}

	[Scriptable]
	public bool GetBool(StringView key, bool fallback) => (mSave != null) ? mSave.Values.GetBool(key, fallback) : fallback;

	[Scriptable]
	public void SetBool(StringView key, bool value)
	{
		if ((mSave != null) && mSave.Values.SetBool(key, value))
			mSave.MarkChanged();
	}

	[Scriptable]
	public StringView GetString(StringView key, StringView fallback) => (mSave != null) ? mSave.Values.GetText(key, fallback) : fallback;

	[Scriptable]
	public void SetString(StringView key, StringView value)
	{
		if ((mSave != null) && mSave.Values.SetText(key, value))
			mSave.MarkChanged();
	}

	/// A list of numbers, saved whole (a recorded run): `Save.SetFloats("ghost", samples)`.
	[Scriptable]
	public void SetFloats(StringView key, List<float> values)
	{
		if ((mSave != null) && (values != null) && mSave.Values.SetFloats(key, values))
			mSave.MarkChanged();
	}

	/// Fills `outValues` with the saved list, answering whether there was one: false, the array
	/// left empty, when the key is absent or holds another kind.
	[Scriptable]
	public bool GetFloats(StringView key, List<float> outValues)
	{
		if (outValues == null)
			return false;
		if (mSave == null)
		{
			outValues.Clear();
			return false;
		}
		return mSave.Values.GetFloats(key, outValues);
	}

	/// Writes now if anything changed; false if the write failed or the run has no save file.
	[Scriptable]
	public bool Flush() => (mSave != null) && mSave.Flush();
}
