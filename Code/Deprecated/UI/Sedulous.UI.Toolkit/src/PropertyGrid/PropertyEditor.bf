using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The base for one row of a [[PropertyGrid]]: a label and a control that edits one value.
///
/// Editing is TRANSACTIONAL, which is what an undo stack needs. A gesture opens with OnEditBegin,
/// reports every intermediate value through OnValueChanged, which may fire many times while a
/// slider is dragged, and then closes with either OnEditEnd or OnEditCancelled. An undo entry is
/// made from the pair, so dragging a slider across a hundred frames is ONE undo step rather than
/// a hundred.
///
/// It is NOT a view. It builds one lazily and holds a reference of its own, so the borrowed
/// pointers its subclasses keep into that view survive a grid rebuild.
abstract class PropertyEditor
{
	/// Fired on every value change, which during a drag is every frame.
	public Event<delegate void(PropertyEditor)> OnValueChanged ~ _.Dispose();
	/// Fired ONCE when a gesture begins: a drag start, a field taking focus.
	public Event<delegate void(PropertyEditor)> OnEditBegin ~ _.Dispose();
	/// Fired once when a gesture completes.
	public Event<delegate void(PropertyEditor)> OnEditEnd ~ _.Dispose();
	/// Fired instead of OnEditEnd when a gesture is abandoned, by Escape or otherwise.
	public Event<delegate void(PropertyEditor)> OnEditCancelled ~ _.Dispose();

	/// OWNED. Set it to make the row's label renameable: the grid then builds an editable
	/// label instead of a plain one, and this receives the new name.
	public delegate void(StringView) OnLabelRenamed ~ delete _;

	private String mName = new .() ~ delete _;
	private String mDisplayName = new .() ~ delete _;
	private String mCategory = new .() ~ delete _;
	private String mTooltip = new .() ~ delete _;

	/// OWNED: the grid rebinds this every time it rebuilds the row.
	private delegate void(StringView) mDisplayNameSink ~ delete _;
	/// OWNED reference. The view tree takes its own once the view is added.
	private View mEditorView = null;
	/// BORROWED: the grid's content tree owns the row.
	private View mRowView = null;

	private bool mIsEditing = false;
	private bool mRowVisible = true;

	public this(StringView name, StringView category = default)
	{
		mName.Set(name);
		mCategory.Set(category);
	}

	public ~this()
	{
		if (mEditorView != null)
			mEditorView.ReleaseRef();
	}

	/// The stable, machine readable identity, such as "CastsShadows". What the grid looks a
	/// property up by.
	public StringView Name => mName;

	/// What the row shows, falling back to the identity when nothing prettier was given.
	public StringView DisplayName => mDisplayName.IsEmpty ? StringView(mName) : StringView(mDisplayName);

	/// LIVE: a row that has already been built follows, through the sink the grid binds, so a
	/// display name that changes after the fact does not need a rebuild.
	public void SetDisplayName(StringView displayName)
	{
		mDisplayName.Set(displayName);
		if (mDisplayNameSink != null)
			mDisplayNameSink(DisplayName);
	}

	/// Called by the grid each time it builds this editor's row. CONSUMES the delegate.
	public void BindDisplayNameSink(delegate void(StringView) sink)
	{
		delete mDisplayNameSink;
		mDisplayNameSink = sink;
	}

	/// Plain text for the whole row. Empty means none.
	public StringView Tooltip => mTooltip;

	public void SetTooltip(StringView tooltip) => mTooltip.Set(tooltip);

	public StringView Category => mCategory;

	/// Conditional visibility, for a property that only applies in some states, such as a
	/// spotlight's cone angle. Toggling flips the LIVE row with no structural rebuild.
	public bool RowVisible => mRowVisible;

	public void SetRowVisible(bool visible)
	{
		if (mRowVisible == visible)
			return;

		mRowVisible = visible;
		ApplyRowVisibility();
	}

	/// Called by the grid each time it builds this editor's row, BORROWED. Applies the current
	/// visibility to the new row, so a property hidden before the grid was built stays hidden.
	public void SetRowView(View row)
	{
		mRowView = row;
		ApplyRowVisibility();
	}

	/// Whether a gesture is in progress.
	public bool IsEditing => mIsEditing;

	/// The editing control, built on first ask. BORROWED: the editor keeps its own reference.
	public View EditorView
	{
		get
		{
			if (mEditorView == null)
				mEditorView = CreateEditorView();
			return mEditorView;
		}
	}

	/// Pushes the current value back into the control, for a value that changed elsewhere.
	public abstract void RefreshView();

	/// Builds the editing control. Called ONCE, lazily. OWNERSHIP transfers to the editor.
	protected abstract View CreateEditorView();

	protected void NotifyValueChanged() => OnValueChanged(this);

	/// Opening a gesture that is already open does nothing, so a field taking focus twice, or a
	/// drag that starts inside another, still produces one transaction.
	protected void BeginEdit()
	{
		if (mIsEditing)
			return;

		mIsEditing = true;
		OnEditBegin(this);
	}

	protected void EndEdit()
	{
		if (!mIsEditing)
			return;

		mIsEditing = false;
		OnEditEnd(this);
	}

	protected void CancelEdit()
	{
		if (!mIsEditing)
			return;

		mIsEditing = false;
		OnEditCancelled(this);
	}

	private void ApplyRowVisibility()
	{
		if (mRowView == null)
			return;

		mRowView.Visibility = mRowVisible ? .Visible : .Gone;
		mRowView.Invalidate();
	}
}
