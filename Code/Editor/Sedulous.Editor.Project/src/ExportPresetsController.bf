using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.VFS;

namespace Sedulous.Editor.Project;

/// The presets dialog's headless half: the set loaded or defaulted, edited with unique
/// names, saved.
class ExportPresetsController
{
	private ExportPresetSet mSet = new .() ~ delete _;
	/// Why the last Load did not read the file; empty when it did, or there was none.
	private String mProblem = new .() ~ delete _;
	/// The unread file is still there: Save never writes over it.
	private bool mSaveRefused;

	/// Loads the project's export_presets.xml. When it is absent (the first export), seeds the
	/// built in default so the panel always has something to show and export. When it is there
	/// but does not read, it is set aside first ("export_presets.xml.unreadable", LoadProblem
	/// says where) so saving the defaults never writes over the presets it held; when it
	/// cannot be moved, Save refuses instead.
	public void Load(IFileSystem projectFs)
	{
		ClearAndDeleteItems(mSet.Presets);
		mProblem.Clear();
		mSaveRefused = false;
		let loaded = ExportPresetsFile.Load(projectFs, mSet);
		if (loaded case .Ok)
			return;
		ExportPresetsFile.Defaults(mSet);
		if (loaded case .Err(.NotFound))
			return;

		let aside = scope String();
		if (UnreadableFiles.SetAside(projectFs, ExportPresetsFile.cFileName, aside) case .Ok)
		{
			mProblem.AppendF("{} could not be read; it was moved to {} and the presets start again", ExportPresetsFile.cFileName, aside);
		}
		else
		{
			mProblem.AppendF("{} could not be read, nor moved aside; the presets are not saved over it", ExportPresetsFile.cFileName);
			mSaveRefused = true;
		}
		GlobalLog(.Error, "Export: {}", mProblem);
	}

	/// Why the last Load did not read the project's presets; empty when it did, or there were
	/// none.
	public StringView LoadProblem => mProblem;

	/// Refused over a file Load could not read or set aside.
	public Result<void, ErrorCode> Save(IWritableFileSystem projectFs)
	{
		if (mSaveRefused)
			return .Err(.InvalidArgument);
		return ExportPresetsFile.Save(projectFs, mSet);
	}

	public int Count => mSet.Presets.Count;
	public ExportPreset At(int index) => mSet.Presets[index];
	public ExportPresetSet Set => mSet;

	/// A COPY of `preset` appended under a unique name; the index it landed at.
	public int Add(ExportPreset preset)
	{
		let copy = new ExportPreset();
		preset.CopyTo(copy);
		UniqueName(copy.Name, -1, copy.Name);
		mSet.Presets.Add(copy);
		return mSet.Presets.Count - 1;
	}

	/// Replaces the preset at `index` with a copy of `preset`, its name unique among the others.
	public void Update(int index, ExportPreset preset)
	{
		if ((index < 0) || (index >= mSet.Presets.Count))
			return;
		let copy = new ExportPreset();
		preset.CopyTo(copy);
		UniqueName(copy.Name, index, copy.Name);
		delete mSet.Presets[index];
		mSet.Presets[index] = copy;
	}

	/// The original still present, the copy gets " Copy".
	public int Duplicate(int index)
	{
		if ((index < 0) || (index >= mSet.Presets.Count))
			return index;
		return Add(mSet.Presets[index]);
	}

	public void Remove(int index)
	{
		if ((index >= 0) && (index < mSet.Presets.Count))
		{
			delete mSet.Presets[index];
			mSet.Presets.RemoveAt(index);
		}
	}

	/// The stem, or "<stem> Copy", or "<stem> Copy N", whichever is free among the presets
	/// other than `skip`. `outName` may alias `stem`.
	public void UniqueName(StringView stem, int skip, String outName)
	{
		let root = scope String(stem.IsEmpty ? "Preset" : stem);
		if (!Taken(root, skip))
		{
			outName.Set(root);
			return;
		}
		let first = scope $"{root} Copy";
		if (!Taken(first, skip))
		{
			outName.Set(first);
			return;
		}
		for (int n = 2;; n++)
		{
			let candidate = scope $"{root} Copy {n}";
			if (!Taken(candidate, skip))
			{
				outName.Set(candidate);
				return;
			}
		}
	}

	private bool Taken(StringView candidate, int skip)
	{
		for (int i < mSet.Presets.Count)
			if ((i != skip) && (mSet.Presets[i].Name == candidate))
				return true;
		return false;
	}
}
