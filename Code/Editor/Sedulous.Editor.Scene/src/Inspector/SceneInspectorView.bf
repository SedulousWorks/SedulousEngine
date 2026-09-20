using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The property grid for the selection: an Entity tab with the entity, its transform and
/// every component it has, and a Scene tab with each system's settings block.
///
/// The grid is rebuilt when its SIGNATURE moves: the selected entity, the scene revision, or
/// the set of components on it. Between rebuilds every row has a refresher that re-reads its
/// live value, so an edit from anywhere shows without tearing the grid down. The rows for a
/// component or a settings type are generated at compile time and found in the
/// InspectorRegistry; a type not registered there shows a notice.
///
/// The editor context and the edit context are borrowed; the page owns both.
class SceneInspectorView : ViewGroup
{
	private const int32 cEntityTab = 0;
	private const int32 cSceneTab = 1;

	private EditorContext mEditor;
	private SceneEditContext mEdit;
	private TabView mTabView;
	/// The ACTIVE tab's grid; Rebuild re-points it.
	private PropertyGrid mGrid;
	private PropertyGrid mEntityGrid;
	private PropertyGrid mSceneGrid;
	private Label mEmptyLabel;
	private Button mAddButton;
	private Button mPasteButton;
	private List<delegate void()> mRefreshers = new .() ~ DeleteContainerAndItems!(_);
	/// Delegates, names and lists the rows hold; freed with the grid's contents.
	private List<Object> mOwned = new .() ~ DeleteContainerAndItems!(_);
	/// The selection last seen, to switch to the Entity tab on a new pick.
	private Guid mLastSelectedForTab = .();
	private uint64 mSignature = uint64.MaxValue;
	/// Set when a data only mutation changed a section's SHAPE.
	private bool mForceRebuild = false;

	public this(EditorContext editor, SceneEditContext edit)
	{
		mEditor = editor;
		mEdit = edit;

		mTabView = new TabView();
		mTabView.TabsClosable.Value = false;
		mTabView.OnTabChanged.Add(new [=this](tabs, index) => { mForceRebuild = true; });

		let entityColumn = new FlexLayout();
		entityColumn.Direction = .Vertical;
		entityColumn.Padding = .(8, 6); // inset off the panel edge, like the hierarchy

		mEmptyLabel = new Label("Select an entity to inspect.");
		mEmptyLabel.FontSize.Value = 12.0f;
		mEmptyLabel.Visibility = .Gone; // shown only when nothing is selected
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		entityColumn.AddView(mEmptyLabel, match);

		mEntityGrid = new PropertyGrid();
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		entityColumn.AddView(mEntityGrid, grow);

		mAddButton = new Button("Add Component");
		mAddButton.OnClick.Add(new [=this](b) => { ShowAddComponentMenu(); });
		entityColumn.AddView(mAddButton, match);

		mPasteButton = new Button("Paste Component");
		mPasteButton.OnClick.Add(new [=this](b) => { PasteSelectedComponent(); });
		mPasteButton.Visibility = .Gone;
		var pasteStyle = LayoutStyle();
		pasteStyle.Width = SizeSpec.Match();
		pasteStyle.Margin = Thickness(0.0f, 6.0f, 0.0f, 0.0f); // a gap below Add Component
		entityColumn.AddView(mPasteButton, pasteStyle);

		let sceneColumn = new FlexLayout();
		sceneColumn.Direction = .Vertical;
		sceneColumn.Padding = .(8, 6);
		mSceneGrid = new PropertyGrid();
		sceneColumn.AddView(mSceneGrid, grow);

		mTabView.AddTab("Entity", entityColumn);
		mTabView.AddTab("Scene", sceneColumn);
		mGrid = mEntityGrid;

		AddView(mTabView);
	}

	public EditorContext Editor => mEditor;
	public SceneEditContext Edit => mEdit;
	public PropertyGrid Grid => mGrid;

	/// Switches to the Entity tab on a new pick, keeps the Paste button in step with the
	/// clipboard, and either rebuilds the grid or refreshes its rows.
	public void Refresh()
	{
		let selected = SelectedEntity;
		if (selected != mLastSelectedForTab)
		{
			mLastSelectedForTab = selected;
			if (mEdit.Resolve(selected).IsAssigned && (mTabView.SelectedIndex != cEntityTab))
				mTabView.SetSelectedIndex(cEntityTab); // fires OnTabChanged, which forces a rebuild
		}

		UpdatePasteButton();
		let signature = Signature();
		if (mForceRebuild || (signature != mSignature))
		{
			mForceRebuild = false;
			mSignature = signature;
			Rebuild();
			return;
		}
		// A refresher may find a shape change and ask for a rebuild; it happens next frame.
		for (let refresher in mRefreshers)
			refresher();
	}

	/// Asks for a rebuild on the next Refresh: a list grew, a behavior was added.
	public void RequestRebuild() => mForceRebuild = true;

	/// Fills the available space: the default ViewGroup measure wraps to children.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		for (int i < ChildCount)
			GetChildAt(i).Measure(constraints);
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
			GetChildAt(i).Layout(0, 0, width, height);
	}

	// ---- the row plumbing the sections use ----

	/// Adds an editor to the active grid, which OWNS it, with the refresher that re-reads its
	/// value while it is not being edited. CONSUMES the refresher.
	public void AddEditor(PropertyEditor editor, delegate void() refresher)
	{
		mGrid.AddProperty(editor);
		Keep(refresher);
		mRefreshers.Add(new [=editor, =refresher]() =>
		{
			if (!editor.IsEditing)
				refresher();
		});
	}

	/// A refresher with no editor of its own; CONSUMED.
	public void AddRefresher(delegate void() refresher) => mRefreshers.Add(refresher);

	/// Takes ownership of something a row's closures hold, for the life of the grid contents.
	public void Keep(Object owned) => mOwned.Add(owned);

	/// The asset's name, "(none)" for nil and "(missing)" for an id the project lacks.
	public void AssetNameFor(Guid target, String outName)
	{
		if (target.IsNil)
		{
			outName.Set("(none)");
			return;
		}
		if (mEditor.Project != null)
		{
			if (let instance = mEditor.Project.SourceDb.GetInstance(target))
			{
				outName.Set(instance.Name);
				return;
			}
		}
		outName.Set("(missing)");
	}

	// ---- rebuilding ----

	private Guid SelectedEntity => mEdit.EntitySelection.IsEmpty ? Guid() : mEdit.EntitySelection.Primary;

	/// The selection, the scene revision and which managers hold a component for it.
	private uint64 Signature()
	{
		let id = SelectedEntity;
		var signature = (uint64)id.GetHashCode() ^ mEdit.Scene.Revision;
		let e = mEdit.Resolve(id);
		if (e.IsAssigned)
		{
			uint64 bit = 1;
			mEdit.Scene.ForEachManager(scope [&](mgr) =>
			{
				if (mgr.HasComponent(e))
					signature ^= bit &* 0xBF58476D1CE4E5B9UL;
				bit <<= 1;
			});
		}
		return signature;
	}

	private void Rebuild()
	{
		let sceneTab = mTabView.SelectedIndex == cSceneTab;
		mGrid = sceneTab ? mSceneGrid : mEntityGrid;
		mGrid.Clear();
		ClearAndDeleteItems(mRefreshers);
		ClearAndDeleteItems(mOwned);

		if (sceneTab)
		{
			BuildSceneSettingsSections();
			Invalidate();
			return;
		}

		let id = SelectedEntity;
		let e = mEdit.Resolve(id);
		let has = e.IsAssigned;
		mAddButton.Visibility = has ? .Visible : .Gone;
		mEmptyLabel.Visibility = has ? .Gone : .Visible;
		if (!has)
		{
			Invalidate();
			return;
		}

		BuildEntitySection(id);
		BuildTransformSection(id);
		mEdit.Scene.ForEachManager(scope [&](mgr) =>
		{
			let live = mEdit.Resolve(id);
			if (live.IsAssigned && mgr.HasComponent(live))
				BuildComponentSection(id, mgr);
		});
		Invalidate();
	}
}
