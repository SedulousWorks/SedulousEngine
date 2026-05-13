namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;
using Sedulous.Serialization;

/// Loads and saves .sedproj project settings using OpenDDL serialization.
/// Stores editor state: settings, open pages, active page, window geometry.
class EditorProject
{
	private String mProjectDirectory = new .() ~ delete _;
	private String mProjectFilePath = new .() ~ delete _;
	private ISerializerProvider mSerializerProvider;

	// Settings (general key-value pairs for extensibility)
	private Dictionary<String, String> mSettings = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	// Open pages state
	private List<String> mOpenPageUris = new .() ~ DeleteContainerAndItems!(_);
	private int32 mActivePageIndex = -1;

	/// The project root directory.
	public StringView ProjectDirectory => mProjectDirectory;

	/// The .sedproj file path.
	public StringView ProjectFilePath => mProjectFilePath;

	/// Whether a project is currently loaded.
	public bool IsLoaded => mProjectDirectory.Length > 0;

	/// Paths of pages that were open when the project was last saved.
	public List<String> OpenPageUris => mOpenPageUris;

	/// Index of the active page tab when last saved.
	public int32 ActivePageIndex
	{
		get => mActivePageIndex;
		set => mActivePageIndex = value;
	}

	/// Sets the serializer provider. Must be called before Open().
	public void SetSerializerProvider(ISerializerProvider provider)
	{
		mSerializerProvider = provider;
	}

	/// Open a project directory. Loads or creates .sedproj.
	public Result<void> Open(StringView directoryPath)
	{
		mProjectDirectory.Set(directoryPath);
		mProjectFilePath.Clear();
		Path.InternalCombine(mProjectFilePath, directoryPath, ".sedproj");

		if (File.Exists(mProjectFilePath))
			return Load();
		else
			return Save(); // Create default
	}

	/// Close the current project.
	public void Close()
	{
		if (IsLoaded)
			Save();
		mProjectDirectory.Clear();
		mProjectFilePath.Clear();
		ClearAll();
	}

	/// Get a setting value. Returns empty string if not found.
	public StringView GetSetting(StringView key)
	{
		for (let kv in mSettings)
		{
			if (StringView(kv.key) == key)
				return kv.value;
		}
		return "";
	}

	/// Set a setting value.
	public void SetSetting(StringView key, StringView value)
	{
		for (let kv in mSettings)
		{
			if (StringView(kv.key) == key)
			{
				kv.value.Set(value);
				return;
			}
		}
		mSettings[new String(key)] = new String(value);
	}

	/// Sets the list of open page URIs (for save). Caller is responsible for
	/// resolving each page's absolute FilePath to a `scheme://locator` URI via
	/// `MountResolver.TryResolveAbsoluteToUri` so the saved list is portable
	/// across machines.
	public void SetOpenPageUris(Span<StringView> uris, int32 activeIndex)
	{
		ClearAndDeleteItems!(mOpenPageUris);
		mActivePageIndex = activeIndex;

		for (let uri in uris)
		{
			if (uri.Length > 0)
				mOpenPageUris.Add(new String(uri));
		}
	}

	/// Save project to .sedproj.
	public Result<void> Save()
	{
		if (mProjectFilePath.Length == 0 || mSerializerProvider == null) return .Err;

		let writer = mSerializerProvider.CreateWriter();
		if (writer == null) return .Err;
		defer delete writer;

		Serialize(writer);

		let output = scope String();
		mSerializerProvider.GetOutput(writer, output);
		return File.WriteAllText(mProjectFilePath, output);
	}

	private Result<void> Load()
	{
		ClearAll();

		if (mSerializerProvider == null) return .Err;

		let content = scope String();
		if (File.ReadAllText(mProjectFilePath, content) case .Err)
			return .Err;

		let reader = mSerializerProvider.CreateReader(content);
		if (reader == null)
		{
			// File exists but can't parse (old format) - recreate
			return Save();
		}
		defer delete reader;

		Serialize(reader);
		return .Ok;
	}

	private void Serialize(Serializer s)
	{
		// Settings
		var settingCount = (int32)mSettings.Count;
		s.BeginArray("Settings", ref settingCount);

		if (s.IsWriting)
		{
			for (let kv in mSettings)
			{
				s.BeginObject("");
				s.String("key", kv.key);
				s.String("value", kv.value);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < settingCount; i++)
			{
				s.BeginObject("");
				let key = new String();
				let value = new String();
				s.String("key", key);
				s.String("value", value);
				mSettings[key] = value;
				s.EndObject();
			}
		}

		s.EndArray();

		// Open pages (stored as scheme://locator URIs, not absolute paths, so
		// .sedproj works across machines and operating systems).
		var pageCount = (int32)mOpenPageUris.Count;
		s.BeginArray("OpenPages", ref pageCount);

		if (s.IsWriting)
		{
			for (let uri in mOpenPageUris)
			{
				s.BeginObject("");
				s.String("uri", uri);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < pageCount; i++)
			{
				s.BeginObject("");
				let uri = new String();
				s.String("uri", uri);
				mOpenPageUris.Add(uri);
				s.EndObject();
			}
		}

		s.EndArray();

		s.Int32("ActivePageIndex", ref mActivePageIndex);
	}

	private void ClearAll()
	{
		for (let kv in mSettings) { delete kv.key; delete kv.value; }
		mSettings.Clear();
		ClearAndDeleteItems!(mOpenPageUris);
		mActivePageIndex = -1;
	}
}
