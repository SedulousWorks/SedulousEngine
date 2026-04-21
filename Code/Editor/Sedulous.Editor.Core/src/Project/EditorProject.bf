namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;

/// Loads and saves .sedproj project settings.
/// Stores editor layout, recent scenes, plugin settings.
class EditorProject
{
	private String mProjectDirectory = new .() ~ delete _;
	private String mProjectFilePath = new .() ~ delete _;
	private Dictionary<String, String> mSettings = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	/// The project root directory.
	public StringView ProjectDirectory => mProjectDirectory;

	/// The .sedproj file path.
	public StringView ProjectFilePath => mProjectFilePath;

	/// Whether a project is currently loaded.
	public bool IsLoaded => mProjectDirectory.Length > 0;

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
		ClearSettings();
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

	/// Save settings to .sedproj.
	public Result<void> Save()
	{
		if (mProjectFilePath.Length == 0) return .Err;

		let content = scope String();
		for (let kv in mSettings)
			content.AppendF("{}={}\n", kv.key, kv.value);

		if (File.WriteAllText(mProjectFilePath, content) case .Err)
			return .Err;
		return .Ok;
	}

	private Result<void> Load()
	{
		ClearSettings();

		let content = scope String();
		if (File.ReadAllText(mProjectFilePath, content) case .Err)
			return .Err;

		for (let line in content.Split('\n'))
		{
			let trimmed = scope String(line);
			trimmed.Trim();
			if (trimmed.Length == 0) continue;

			let eqIdx = trimmed.IndexOf('=');
			if (eqIdx < 0) continue;

			let key = scope String(trimmed, 0, eqIdx);
			let value = scope String(trimmed, eqIdx + 1);
			key.Trim();
			value.Trim();
			mSettings[new String(key)] = new String(value);
		}

		return .Ok;
	}

	private void ClearSettings()
	{
		for (let kv in mSettings)
		{
			delete kv.key;
			delete kv.value;
		}
		mSettings.Clear();
	}
}
