using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// A property source made of others, one section each, for an editor's grid to show what no one
/// source stands for (a scene inspector: an entity's name, its transform and each of its
/// components, each a source of its own). The grid shows the sections in their order, each
/// section's top-level properties under its title as their category (a header the grid folds). A
/// section's paths are its source's under a key of its own ("s2/position.x"), so every call is the
/// section's source's for its own path; what a section's source tells its client reaches this
/// one's. The sources stay their owners' and outlive being sections. The editor's for now; it moves
/// to GUI.Toolkit if something outside the editor needs it.
class PropertySections : IPropertySource
{
	private class Section
	{
		public String Key = new .() ~ delete _;
		public String Title = new .() ~ delete _;
		// Not owned.
		public IPropertySource Source;
	}

	// What a section's source tells reaches this one's client.
	private class Forwarder : IPropertySourceClient
	{
		private PropertySections mOwner;

		public this(PropertySections owner)
		{
			mOwner = owner;
		}

		public void OnPropertiesChanged() => mOwner.NotifyPropertiesChanged();
		public void OnValuesChanged() => mOwner.NotifyValuesChanged();
	}

	private List<Section> mSections = new .() ~ DeleteContainerAndItems!(_);
	private Forwarder mForwarder ~ delete _;
	private bool mReadOnly = false;

	public this()
	{
		mForwarder = new .(this);
	}

	// Its sources let go, its client told nothing: whoever it told may be gone already.
	public ~this()
	{
		Release();
	}

	/// A section after the others: `source`'s properties under `title` (`key`: what its paths
	/// start with and a caller finds it by again; unique among the sections, no '.' or '/').
	public void Add(StringView key, StringView title, IPropertySource source)
	{
		let section = new Section();
		section.Key.Set(key);
		section.Title.Set(title);
		section.Source = source;
		mSections.Add(section);
		source.Client = mForwarder;
		NotifyPropertiesChanged();
	}

	/// No sections; their sources let go.
	public void Clear()
	{
		Release();
		NotifyPropertiesChanged();
	}

	public int SectionCount => mSections.Count;

	/// Every row read only, every edit through it refused (a scene page while it simulates).
	public bool ReadOnly
	{
		get => mReadOnly;
		set
		{
			if (mReadOnly == value)
				return;
			mReadOnly = value;
			NotifyPropertiesChanged();
		}
	}

	/// The section a path is in (a header's `#title`, a property's own path); empty when none.
	public StringView SectionOf(StringView path)
	{
		if ((path.Length != 0) && (path[0] == '#'))
		{
			let title = path.Substring(1);
			for (let section in mSections)
			{
				if (section.Title == title)
					return section.Key;
			}
			return default;
		}
		let section = Find(path);
		return (section != null) ? (StringView)section.Key : default;
	}

	/// A section's path for its source's `inner` path (`inner` empty: the section itself), appended.
	public void PathIn(StringView key, StringView inner, String outPath)
	{
		outPath.Append(key);
		outPath.Append('/');
		outPath.Append(inner);
	}

	// === IPropertySource ===

	public override int ObjectCount
	{
		get
		{
			var count = 0;
			for (let section in mSections)
				count = Math.Max(count, section.Source.ObjectCount);
			return count;
		}
	}

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (parent.Length == 0)
		{
			for (let section in mSections)
			{
				let first = outInfos.Count;
				section.Source.GetProperties(default, outInfos);
				for (int i = first; i < outInfos.Count; ++i)
				{
					let info = outInfos[i];
					info.ReadOnly = info.ReadOnly || mReadOnly;
					if (info.DisplayName.Length == 0)
						info.DisplayName.Set(info.Name);
					let name = PathIn(section.Key, info.Name, .. scope String());
					info.Name.Set(name);
					info.Category.Set(section.Title);
				}
			}
			return;
		}
		let section = Find(parent);
		if (section == null)
			return;
		let first = outInfos.Count;
		section.Source.GetProperties(Inner(parent), outInfos);
		for (int i = first; i < outInfos.Count; ++i)
			outInfos[i].ReadOnly = outInfos[i].ReadOnly || mReadOnly;
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let section = Find(path);
		return ((section != null) && (object < section.Source.ObjectCount)) ? section.Source.GetValue(Inner(path), object) : .();
	}

	public override void BeginEdit(StringView path)
	{
		if (let section = mReadOnly ? null : Find(path))
			section.Source.BeginEdit(Inner(path));
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		if (let section = mReadOnly ? null : Find(path))
			section.Source.PreviewEdit(Inner(path), write);
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		if (let section = mReadOnly ? null : Find(path))
			section.Source.CommitEdit(Inner(path), write);
	}

	public override void CancelEdit(StringView path)
	{
		if (let section = Find(path))
			section.Source.CancelEdit(Inner(path));
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let section = mReadOnly ? null : Find(path);
		return (section != null) && section.Source.EditList(Inner(path), edit);
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		let section = Find(path);
		return (section != null) ? section.Source.GetDefault(Inner(path), object) : .();
	}

	public override bool Revert(StringView path)
	{
		let section = mReadOnly ? null : Find(path);
		return (section != null) && section.Source.Revert(Inner(path));
	}

	public override void GetRevertText(StringView path, String outText)
	{
		if (let section = Find(path))
			section.Source.GetRevertText(Inner(path), outText);
	}

	public override void CopyValue(StringView path, String outText)
	{
		if (let section = Find(path))
			section.Source.CopyValue(Inner(path), outText);
	}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		if (mReadOnly)
		{
			reason.Set("Read only");
			return false;
		}
		let section = Find(path);
		return (section != null) && section.Source.PasteValue(Inner(path), text, reason);
	}

	private void Release()
	{
		for (let section in mSections)
		{
			if (section.Source.Client == mForwarder)
				section.Source.Client = null;
		}
		ClearAndDeleteItems!(mSections);
	}

	// A path's key: what comes before its first '/'.
	private static StringView KeyOf(StringView path)
	{
		let slash = path.IndexOf('/');
		return (slash >= 0) ? path.Substring(0, slash) : default;
	}

	// A path as its section's source knows it: what comes after its first '/'.
	private static StringView Inner(StringView path)
	{
		let slash = path.IndexOf('/');
		return (slash >= 0) ? path.Substring(slash + 1) : path;
	}

	private Section Find(StringView path)
	{
		let key = KeyOf(path);
		for (let section in mSections)
		{
			if (section.Key == key)
				return section;
		}
		return null;
	}
}
