using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The docking system: a tree of splits and tab groups filling one region, plus however many
/// panels have been floated out of it.
///
/// OWNERSHIP runs two ways at once and the distinction matters. The manager keeps an owning
/// registry of every panel that survives undocking, floating and re-docking, so a panel is not
/// destroyed merely by being taken out of the tree. The TREE holds its own reference on top of
/// that, which is what makes every structural move a matched AddRef and release rather than a
/// question of who is last.
///
/// Tree surgery defers its deletions through the mutation queue. Rearranging the tree happens
/// during a drop, which is mid dispatch, and freeing a node whose event is still unwinding is
/// the failure this exists to prevent.
class DockManager : ViewGroup, IDropTarget, IPopupOwner, IDockHost
{
	/// BORROWED: the application owns the host. Null means floating panels become overlays
	/// inside the main window rather than windows of their own.
	public IDockableWindowHost DockableWindowHost = null;

	/// Fired when a panel becomes the active one, by a tab click, a press anywhere inside it, or
	/// a dock.
	public Event<delegate void(DockablePanel)> OnPanelActivated ~ _.Dispose();

	/// BORROWED: the tree owns its nodes.
	private View mRootNode = null;
	/// OWNED. The registry that outlives any particular position in the tree.
	private List<DockablePanel> mPanels = new .() ~ ReleasePanels!(_);
	/// BORROWED: a floating window is owned by the popup layer or by the application.
	private List<DockableWindow> mDockableWindows = new .() ~ delete _;
	/// OWNED, drawn MANUALLY and never added to the tree, so it can overlay everything without
	/// taking part in layout or hit testing.
	private DockZoneIndicator mZoneIndicator = new .() ~ _.ReleaseRef();
	private bool mIsCleaningUp = false;

	public this()
	{
		mZoneIndicator.Visibility = .Gone;
	}

	private static mixin ReleasePanels(var panels)
	{
		for (let panel in panels)
			panel.ReleaseRef();
		delete panels;
	}

	/// BORROWED.
	public View RootNode => mRootNode;

	public int PanelCount => mPanels.Count;

	/// BORROWED.
	public DockablePanel GetPanelAt(int index) => mPanels[index];

	public UIContext HostContext => Context;

	public View OwnerView => this;

	// ---- Panels ---------------------------------------------------------------------------------

	/// Registers a new panel. CONSUMES the content's reference; the panel itself stays OWNED by
	/// the manager and is returned BORROWED.
	///
	/// Registering does NOT dock it. A panel exists in the registry first and is placed second,
	/// which is what lets a layout be applied to panels that were all created up front.
	public DockablePanel AddPanel(StringView title, View content)
	{
		let panel = new DockablePanel(title, content);
		panel.DockHost = this;
		panel.OnCloseRequested.Add(new (p) => { ClosePanel(p); });
		mPanels.Add(panel);
		return panel;
	}

	/// Docks a panel relative to the tree's root.
	public void DockPanel(DockablePanel panel, DockPosition position) =>
		DockPanelRelativeTo(panel, position, mRootNode);

	/// Docks a panel beside, above, below or into another node.
	public void DockPanelRelativeTo(DockablePanel panel, DockPosition position, View relativeTo)
	{
		RemoveFromTree(panel);
		panel.SaveDockPosition(position, relativeTo);

		if (position == .Float)
		{
			FloatPanel(panel, 100, 100);
			return;
		}

		// The target is re-resolved AFTER cleanup, by ID rather than by pointer, because
		// collapsing the empty node the panel just left can destroy the very node it was being
		// docked relative to.
		let relativeToId = (relativeTo != null) ? relativeTo.Id : ViewId.Invalid;
		CleanupEmptyNodes();
		let target = ResolveTarget(relativeTo, relativeToId);

		if (position == .Center)
		{
			DockAsTab(panel, target);
			// A freshly docked tab becomes the ACTIVE one. A DELIBERATE DEVIATION from the
			// original, which kept the existing selection and left its editor to activate by
			// hand; activating on dock is what every mainstream tool of this shape does.
			// Programmatic docking, drag and drop, and re-docking a window all come through
			// here. Restoring a layout is unaffected, since that builds groups directly.
			ActivatePanel(panel);
			Invalidate();
			return;
		}

		InsertSplit(target, panel, position);
	}

	private View ResolveTarget(View relativeTo, ViewId relativeToId)
	{
		if (relativeToId.IsValid && (Context != null))
		{
			let resolved = Context.GetViewById(relativeToId);
			return ((resolved != null) && !resolved.IsPendingDeletion) ? resolved : mRootNode;
		}

		return ((relativeTo != null) && relativeTo.IsPendingDeletion) ? mRootNode : relativeTo;
	}

	/// Joins the target's tabs, making a group where there is not one yet.
	private void DockAsTab(DockablePanel panel, View target)
	{
		if (let tabGroup = target as DockTabGroup)
		{
			AdoptIntoGroup(tabGroup, panel);
			return;
		}

		if (let existingPanel = target as DockablePanel)
		{
			if (let parentGroup = existingPanel.Parent as DockTabGroup)
			{
				AdoptIntoGroup(parentGroup, panel);
				return;
			}

			// A standalone panel becomes a two tab group, which is how the first tab pair in a
			// region comes about.
			let group = new DockTabGroup();
			existingPanel.AddRef();
			ReplaceNode(existingPanel, group);
			group.AddPanel(existingPanel);
			AdoptIntoGroup(group, panel);
			return;
		}

		// A split, or nothing at all: the first group in the subtree takes it, else the first
		// anywhere, else the tree gets its first node.
		var targetGroup = (target != null) ? FindFirstTabGroup(target) : null;
		if ((targetGroup == null) && (mRootNode != null))
			targetGroup = FindFirstTabGroup(mRootNode);

		if (targetGroup != null)
		{
			AdoptIntoGroup(targetGroup, panel);
			return;
		}

		let group = new DockTabGroup();
		AdoptIntoGroup(group, panel);
		mRootNode = group;
		AddView(group);
	}

	/// The registry keeps its own reference, so the tree is handed a separate one.
	private void AdoptIntoGroup(DockTabGroup group, DockablePanel panel)
	{
		panel.AddRef();
		group.AddPanel(panel);
	}

	/// Takes a panel out of the tree, leaving it registered and alive.
	public void UndockPanel(DockablePanel panel)
	{
		RemoveFromTree(panel);
		CleanupEmptyNodes();
		Invalidate();
	}

	/// Pulls a panel out into a window of its own: a real one where the host can make them, and
	/// an overlay inside the main window otherwise.
	public void FloatPanel(DockablePanel panel, float x, float y)
	{
		// Measured BEFORE the removal, while the panel still has the size it was docked at, so
		// a floated panel opens the size it was rather than at a default.
		let width = (panel.Width > 0.0f) ? panel.Width : 300.0f;
		let height = (panel.Height > 0.0f) ? panel.Height : 250.0f;

		RemoveFromTree(panel);

		panel.AddRef();
		let window = new DockableWindow(panel);
		mDockableWindows.Add(window);
		window.WindowHost = DockableWindowHost;
		window.OnDockRequested.Add(new (w) => { RedockDockableWindow(w); });
		window.OnCloseRequested.Add(new (w) => { CloseDockableWindow(w); });

		if ((DockableWindowHost != null) && DockableWindowHost.SupportsOSWindows())
			CreateRealWindow(window, width, height, x, y);
		else
			ShowOverlayWindow(window, x, y);

		CleanupEmptyNodes();
		Invalidate();
	}

	private void CreateRealWindow(DockableWindow window, float width, float height, float x,
		float y)
	{
		window.IsOSWindow = true;
		window.HasOSChrome = DockableWindowHost.UsesOSChrome();

		// The system's own close button routes through the PANEL's RequestClose, so the veto a
		// dirty page installs applies there too. A window with no panel closes outright.
		DockableWindowHost.CreateDockableWindow(window, width, height, x, y, new (view) =>
			{
				let closing = view as DockableWindow;
				if (closing == null)
					return;

				if (let panel = closing.Panel)
					panel.RequestClose();
				else
					CloseDockableWindow(closing);
			});
	}

	private void ShowOverlayWindow(DockableWindow window, float x, float y)
	{
		if (Context == null)
			return;

		if (let root = Root())
			root.GetPopupLayer().ShowPopup(window, this, x, y, false, false, true);
	}

	/// Undocks a panel, and destroys it only if it is a PAGE panel.
	///
	/// A TOOL panel, which is one carrying a persistence id, HIDES: the registry keeps it, so
	/// a layout reset or a restore re-docks the same object and whoever borrowed its pointer,
	/// the editor shell among them, never dangles. Destroying it left a closed panel's address
	/// live in those borrowers until the next reset read it.
	///
	/// A page panel has no persistence id, its content dying with the page that made it, so it
	/// is destroyed as before.
	public void ClosePanel(DockablePanel panel)
	{
		UndockPanel(panel);
		if (!panel.PersistenceId.IsEmpty)
			return;

		// Queued FIRST, which keeps the panel alive across the deferred boundary, and only then
		// dropped from the registry.
		QueueDeleteNode(panel);
		ErasePanel(panel);
	}


	/// Selects a panel's tab within its group.
	public void ActivatePanel(DockablePanel panel)
	{
		let tabGroup = panel.Parent as DockTabGroup;
		if (tabGroup == null)
			return;

		for (int32 i = 0; i < tabGroup.PanelCount; i++)
		{
			if (tabGroup.GetPanel(i) == panel)
			{
				tabGroup.SetSelectedIndex(i);
				return;
			}
		}
	}

	/// BORROWED, or null.
	public DockablePanel FindPanelById(StringView persistenceId)
	{
		for (let panel in mPanels)
		{
			if (panel.PersistenceId == persistenceId)
				return panel;
		}

		return null;
	}

	// ---- Floating windows -----------------------------------------------------------------------

	/// Puts a floating window's panel back where it came from, or into the tree's tabs when
	/// where it came from is gone.
	public void RedockDockableWindow(DockableWindow window)
	{
		let panel = window.DetachPanel();
		if (panel == null)
			return;

		DestroyDockableWindow(window);

		// DetachPanel handed over a reference; the registry already holds one, so this one goes
		// back before the panel is re-docked.
		panel.ReleaseRef();

		View relativeTo = null;
		if (panel.LastRelativeToId.IsValid && (Context != null))
			relativeTo = Context.GetViewById(panel.LastRelativeToId);

		if (relativeTo != null)
			DockPanelRelativeTo(panel, panel.LastDockPosition, relativeTo);
		else
			DockPanel(panel, .Center);
	}

	public void CloseDockableWindow(DockableWindow window)
	{
		let panel = window.DetachPanel();
		DestroyDockableWindow(window);

		if (panel == null)
			return;

		panel.ReleaseRef();
		QueueDeleteNode(panel);
		ErasePanel(panel);
	}

	public void DestroyDockableWindow(DockableWindow window)
	{
		EraseDockableWindow(window);

		if (window.IsOSWindow && (DockableWindowHost != null))
		{
			DockableWindowHost.DestroyDockableWindow(window);
			QueueDeleteNode(window);
			return;
		}

		// An overlay window is a popup, and closing it releases the layer's reference.
		if (let root = Root())
			root.GetPopupLayer().ClosePopup(window);
	}

	public void OnPopupClosed(View popup)
	{
		for (int i = mDockableWindows.Count - 1; i >= 0; i--)
		{
			if (mDockableWindows[i] != popup)
				continue;

			mDockableWindows.RemoveAt(i);
			return;
		}
	}

	private void ErasePanel(DockablePanel panel)
	{
		for (int i = 0; i < mPanels.Count; i++)
		{
			if (mPanels[i] != panel)
				continue;

			mPanels.RemoveAt(i);
			panel.ReleaseRef();
			return;
		}
	}

	private void EraseDockableWindow(DockableWindow window)
	{
		for (int i = 0; i < mDockableWindows.Count; i++)
		{
			if (mDockableWindows[i] != window)
				continue;

			mDockableWindows.RemoveAt(i);
			return;
		}
	}

	// ---- Layout and drawing ---------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(30, 30, 35));

		DrawChildren(ctx);

		// The indicator is drawn LAST and by hand, because it must cover the whole tree and is
		// deliberately not part of it.
		if (mZoneIndicator.Visibility != .Gone)
		{
			ctx.VG.PushState();
			mZoneIndicator.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let width = constraints.ConstrainWidth(0);
		let height = constraints.ConstrainHeight(0);

		if (mRootNode != null)
			mRootNode.Measure(BoxConstraints.Tight(width, height));

		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mRootNode != null)
			mRootNode.Layout(0, 0, width, height);
	}
}
