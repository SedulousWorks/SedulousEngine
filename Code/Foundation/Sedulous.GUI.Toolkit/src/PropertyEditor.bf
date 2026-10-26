using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// A property grid's editors: the value part of a row, bound to one property at a time (rows are
// pooled, so an editor shows one property, then another), editing through its host as gestures
// (begun, previewed, committed or cancelled). The registry chooses an editor in layers, as
// ezEngine's and Zero's do: by the property's hint, then by its kind, then a row that says nothing
// fits; an application registers its own.

/// What an editor edits through: its grid, which tracks the gesture and asks the source.
interface IPropertyEditHost
{
	void BeginPropertyEdit(StringView path);
	void PreviewPropertyEdit(StringView path, PropertyWrite write);
	void CommitPropertyEdit(StringView path, PropertyWrite write);
	void CancelPropertyEdit(StringView path);
	/// Changes a list (an insert, a removal, a move): one call, one undo entry.
	bool EditPropertyList(StringView path, ListEdit edit);
	/// What is under `path`, appended to `outInfos` (the caller deletes them): what an editor
	/// covering its children shows.
	void GetChildProperties(StringView path, List<PropertyInfo> outInfos);
	/// Each one's value over the objects; the caller disposes it.
	PropertyValue ReadPropertyValue(StringView path, PropertyKind kind);
}

/// The value part of a property's row.
[GuiReflect]
abstract class PropertyEditor : UIWidget
{
	// Not owned: the grid that holds the editor.
	private IPropertyEditHost mHost = null;
	private String mPath = new .() ~ delete _;
	private bool mReadOnly = false;

	public this()
	{
		Tag = "propertyeditor";
	}

	/// Shows `info`'s property at `path`, whose value over the objects is `value` (the caller keeps
	/// it: an editor that keeps the value copies it).
	public void Bind(IPropertyEditHost host, StringView path, PropertyInfo info, PropertyValue value)
	{
		mHost = host;
		mPath.Set(path);
		mReadOnly = info.ReadOnly;
		OnBind(info, value);
	}

	public StringView Path => mPath;
	public bool IsReadOnly => mReadOnly;
	/// Being typed into: the grid then leaves what it shows alone as the values refresh (a
	/// value typed is the edit's until Return or the focus leaving commits it).
	public virtual bool IsTyping => false;

	protected IPropertyEditHost Host => mHost;

	/// Shows a property and its value; read only, it shows and does not edit.
	protected abstract void OnBind(PropertyInfo info, PropertyValue value);

	// The gesture, through the host. Apply is one begun and committed at once (a click).
	protected void BeginEdit()
	{
		if ((mHost != null) && !mReadOnly)
			mHost.BeginPropertyEdit(mPath);
	}

	protected void PreviewEdit(PropertyWrite write)
	{
		if ((mHost != null) && !mReadOnly)
			mHost.PreviewPropertyEdit(mPath, write);
	}

	protected void CommitEdit(PropertyWrite write)
	{
		if ((mHost != null) && !mReadOnly)
			mHost.CommitPropertyEdit(mPath, write);
	}

	protected void CancelEdit()
	{
		if ((mHost != null) && !mReadOnly)
			mHost.CancelPropertyEdit(mPath);
	}

	protected void ApplyEdit(PropertyWrite write)
	{
		BeginEdit();
		CommitEdit(write);
	}

	protected bool EditList(ListEdit edit) => (mHost != null) && !mReadOnly && mHost.EditPropertyList(mPath, edit);
}

static
{
	/// What a kind is called (the fallback row's words).
	public static StringView PropertyKindName(PropertyKind kind)
	{
		switch (kind)
		{
		case .Group: return "group";
		case .Bool: return "bool";
		case .Integer: return "integer";
		case .Float: return "float";
		case .String: return "string";
		case .Enum: return "enum";
		case .Flags: return "flags";
		case .List: return "list";
		case .Color: return "colour";
		case .Curve: return "curve";
		case .Gradient: return "gradient";
		}
	}
}

/// The row of a property no editor takes: it says so, the hint or the kind it could not fit.
[GuiReflect]
class UnknownPropertyEditor : PropertyEditor
{
	private Label mLabel ~ _.ReleaseRef();

	public this()
	{
		AddClass("unknown");
		mLabel = new Label();
		mLabel.SetTextAlignment(.Start, .Middle);
		mLabel.HitTestVisible = false;
		AddChild(mLabel);
	}

	public StringView Message => mLabel.Text;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mLabel.Text = scope String()..AppendF("No editor for {}", (info.Hint.Length != 0) ? (StringView)info.Hint : PropertyKindName(info.Kind));
	}

	public override void OnLayout()
	{
		mLabel.Arrange(ContentBounds);
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mLabel);
	}
}

/// Makes a new editor, which the caller releases.
typealias PropertyEditorFactory = delegate PropertyEditor();

/// The editors a grid chooses from. Each registered editor has a type of row of its own (its pool),
/// numbered from 1; 0 is the row no editor takes.
class PropertyEditorRegistry
{
	public const uint32 cNoEditor = 0;

	private class Entry
	{
		public String Hint = new .() ~ delete _;
		public bool ByKind = false;
		public PropertyKind Kind = .Group;
		public PropertyEditorFactory Factory ~ delete _;
		public bool CoversChildren = false;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mGeneration = 0;

	/// The editor for properties hinted `hint`, before their kind's (replaces one of the hint). One
	/// that `coversChildren` shows what is under the property itself: its row has no chevron and no
	/// rows under it (a Float3's three fields on one row). OWNERSHIP of `factory` transfers.
	public void RegisterHint(StringView hint, PropertyEditorFactory factory, bool coversChildren = false)
	{
		Register(hint, false, .Group, factory, coversChildren);
	}

	/// The editor for properties of `kind` that no hint takes (replaces the kind's). OWNERSHIP of
	/// `factory` transfers.
	public void RegisterKind(PropertyKind kind, PropertyEditorFactory factory)
	{
		Register(default, true, kind, factory, false);
	}

	/// The editor `info` takes: by its hint, then its kind; cNoEditor when none.
	public uint32 Choose(PropertyInfo info)
	{
		if (info.Hint.Length != 0)
		{
			for (int i = 0; i < mEntries.Count; ++i)
			{
				if (!mEntries[i].ByKind && (mEntries[i].Hint == info.Hint))
					return (uint32)(i + 1);
			}
		}
		for (int i = 0; i < mEntries.Count; ++i)
		{
			if (mEntries[i].ByKind && (mEntries[i].Kind == info.Kind))
				return (uint32)(i + 1);
		}
		return cNoEditor;
	}

	/// Whether the editor of `type` shows what is under its property.
	public bool CoversChildren(uint32 type) => (type != cNoEditor) && (type <= (uint32)mEntries.Count) && mEntries[(int)type - 1].CoversChildren;

	/// A new editor of `type` (Choose's answer), which the caller releases.
	public PropertyEditor Create(uint32 type)
	{
		if ((type != cNoEditor) && (type <= (uint32)mEntries.Count) && (mEntries[(int)type - 1].Factory != null))
		{
			let made = mEntries[(int)type - 1].Factory();
			if (made != null)
				return made;
		}
		return new UnknownPropertyEditor();
	}

	/// Counts the changes: a grid whose pools were made before one starts them again.
	public uint32 Generation => mGeneration;

	private void Register(StringView hint, bool byKind, PropertyKind kind, PropertyEditorFactory factory, bool coversChildren)
	{
		++mGeneration;
		for (let entry in mEntries)
		{
			if ((entry.ByKind == byKind) && (byKind ? (entry.Kind == kind) : (entry.Hint == hint)))
			{
				delete entry.Factory;
				entry.Factory = factory;
				entry.CoversChildren = coversChildren;
				return;
			}
		}
		let entry = new Entry();
		entry.Hint.Set(hint);
		entry.ByKind = byKind;
		entry.Kind = kind;
		entry.Factory = factory;
		entry.CoversChildren = coversChildren;
		mEntries.Add(entry);
	}
}
