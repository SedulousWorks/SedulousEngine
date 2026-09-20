using System;
using Sedulous.Core;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// The presets dialog's headless half: the set loaded or defaulted, edited with unique
/// names, saved.
class ExportPresetsController
{
	private ExportPresetSet mSet = new .() ~ delete _;

	public void Load(IFileSystem projectFs)
	{
		ClearAndDeleteItems(mSet.Presets);
		if (ExportPresetsFile.Load(projectFs, mSet) case .Err)
			ExportPresetsFile.Defaults(mSet);
	}

	public Result<void, ErrorCode> Save(IWritableFileSystem projectFs) => ExportPresetsFile.Save(projectFs, mSet);

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
