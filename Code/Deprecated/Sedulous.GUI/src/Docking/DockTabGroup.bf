using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A container that holds one or more DockablePanels as tabs.
/// When only one panel is present, acts as a simple container.
/// When multiple panels are present, shows a tab strip.
public class DockTabGroup : Control, IDragSource, IDropTarget
{
	private List<DockablePanel> mPanels = new .() ~ delete _;  // Panels NOT owned - creator is responsible for deletion
	private int mSelectedIndex = -1;
	private int mHoveredTabIndex = -1;
	private float mTabHeight = 24;  // Default, updated from theme
	private List<RectangleF> mTabBounds = new .() ~ delete _;

	// Image support
	private ImageBrush? mTabStripImage;
	private ImageBrush? mActiveTabImage;
	private ImageBrush? mInactiveTabImage;

	// Drag state
	private int mDragTabIndex = -1;
	private bool mDragPending = false;
	private Vector2 mDragStartPos;
	private int mDropInsertIndex = -1;  // Where to insert when reordering tabs
	private DockPosition? mDropZone = null;  // Current hover zone for edge docking

	// Events
	private EventAccessor<delegate void(DockTabGroup, DockablePanel)> mPanelClosed = new .() ~ delete _;
	private EventAccessor<delegate void(DockTabGroup)> mSelectionChanged = new .() ~ delete _;
	private EventAccessor<delegate void(DockTabGroup)> mEmpty = new .() ~ delete _;

	// Parent reference (set by DockSplit or DockManager)
	public DockManager Manager;

	/// Creates a new DockTabGroup.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Gets the DockManager, finding it by walking up the parent chain if necessary.
	private DockManager GetManager()
	{
		if (Manager != null)
			return Manager;

		// Walk up parent chain to find DockManager
		var current = Parent;
		while (current != null)
		{
			if (let manager = current as DockManager)
			{
				Manager = manager;  // Cache it
				return manager;
			}
			current = current.Parent;
		}
		return null;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "DockTabGroup";

	/// Number of panels in this group.
	public int PanelCount => mPanels.Count;

	/// The currently selected panel index.
	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			let newValue = Math.Clamp(value, mPanels.Count > 0 ? 0 : -1, mPanels.Count - 1);
			if (mSelectedIndex != newValue)
			{
				mSelectedIndex = newValue;
				InvalidateLayout();
				mSelectionChanged.[Friend]Invoke(this);
			}
		}
	}

	/// The currently selected panel, or null.
	public DockablePanel SelectedPanel
	{
		get
		{
			if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
				return mPanels[mSelectedIndex];
			return null;
		}
	}

	/// Whether this group has only one panel (no tabs shown).
	public bool IsSinglePanel => mPanels.Count == 1;

	/// Height of the tab strip (when multiple panels).
	public float TabHeight
	{
		get => mTabHeight;
		set
		{
			if (mTabHeight != value)
			{
				mTabHeight = value;
				InvalidateLayout();
			}
		}
	}

	/// Image for the tab strip background.
	public ImageBrush? TabStripImage
	{
		get => mTabStripImage;
		set => mTabStripImage = value;
	}

	/// Image for the active (selected) tab.
	public ImageBrush? ActiveTabImage
	{
		get => mActiveTabImage;
		set => mActiveTabImage = value;
	}

	/// Image for inactive (unselected) tabs.
	public ImageBrush? InactiveTabImage
	{
		get => mInactiveTabImage;
		set => mInactiveTabImage = value;
	}

	/// Event fired when a panel is closed.
	public EventAccessor<delegate void(DockTabGroup, DockablePanel)> PanelClosed => mPanelClosed;

	/// Event fired when selection changes.
	public EventAccessor<delegate void(DockTabGroup)> SelectionChanged => mSelectionChanged;

	/// Event fired when the last panel is removed.
	public EventAccessor<delegate void(DockTabGroup)> Empty => mEmpty;

	// === Panel Management ===

	/// Adds a panel to this group.
	public void AddPanel(DockablePanel panel)
	{
		InsertPanel(mPanels.Count, panel);
	}

	/// Inserts a panel at the specified index.
	public void InsertPanel(int index, DockablePanel panel)
	{
		let clampedIndex = Math.Clamp(index, 0, mPanels.Count);

		panel.ParentGroup = this;
		panel.SetParent(this);
		if (Context != null)
			panel.OnAttachedToContext(Context);

		// Subscribe to close event
		panel.CloseRequested.Subscribe(new => OnPanelCloseRequested);

		mPanels.Insert(clampedIndex, panel);

		// Select first panel
		if (mPanels.Count == 1)
			mSelectedIndex = 0;
		else if (mSelectedIndex >= clampedIndex)
			mSelectedIndex++;

		InvalidateLayout();
	}

	/// Removes a panel from this group.
	public bool RemovePanel(DockablePanel panel)
	{
		let index = mPanels.IndexOf(panel);
		if (index < 0)
			return false;

		RemovePanelAt(index);
		return true;
	}

	/// Removes the panel at the specified index.
	public void RemovePanelAt(int index)
	{
		if (index < 0 || index >= mPanels.Count)
			return;

		let panel = mPanels[index];
		mPanels.RemoveAt(index);
		panel.ParentGroup = null;
		panel.SetParent(null);

		if (Context != null)
			panel.OnDetachedFromContext();

		// Adjust selection
		if (mPanels.Count == 0)
		{
			mSelectedIndex = -1;
			mEmpty.[Friend]Invoke(this);
		}
		else if (mSelectedIndex >= mPanels.Count)
		{
			mSelectedIndex = mPanels.Count - 1;
		}
		else if (mSelectedIndex == index && mSelectedIndex > 0)
		{
			mSelectedIndex--;
		}

		InvalidateLayout();
	}

	/// Gets the panel at the specified index.
	public DockablePanel GetPanel(int index)
	{
		if (index >= 0 && index < mPanels.Count)
			return mPanels[index];
		return null;
	}

	/// Clears all panels from this group. Does NOT delete panels - owner is responsible.
	public void ClearPanels()
	{
		for (let panel in mPanels)
		{
			panel.ParentGroup = null;
			if (Context != null)
				panel.OnDetachedFromContext();
		}
		mPanels.Clear();
		mSelectedIndex = -1;
		InvalidateLayout();
		mEmpty.[Friend]Invoke(this);
	}

	// === Internal ===

	/// Called when a panel requests to be closed.
	/// Removes the panel and fires PanelClosed event. Does NOT delete the panel - owner is responsible.
	private void OnPanelCloseRequested(DockablePanel panel)
	{
		let index = mPanels.IndexOf(panel);
		if (index >= 0)
		{
			RemovePanelAt(index);
			mPanelClosed.[Friend]Invoke(this, panel);

			// Clean up empty groups after panel close
			if (Manager != null)
				Manager.CleanupEmptyNodes();
		}
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		// Update tab height from theme
		if (context?.Theme != null)
			mTabHeight = context.Theme.DockTabHeight;
		for (let panel in mPanels)
			panel.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		for (let panel in mPanels)
			panel.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float maxWidth = 0;
		float maxHeight = 0;

		for (let panel in mPanels)
		{
			panel.Measure(constraints);
			let size = panel.DesiredSize;
			maxWidth = Math.Max(maxWidth, size.Width);
			maxHeight = Math.Max(maxHeight, size.Height);
		}

		// Add tab height if multiple panels
		if (mPanels.Count > 1)
			maxHeight += mTabHeight;

		return .(maxWidth, maxHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mTabBounds.Clear();

		if (mPanels.Count == 0)
			return;

		RectangleF panelBounds;

		if (mPanels.Count > 1)
		{
			// Tab strip at top
			float tabX = contentBounds.X;
			for (let panel in mPanels)
			{
				// Measure tab width based on title
				let tabWidth = Math.Max(80, panel.Title.Length * 8 + 24);  // Approximate
				let tabRect = RectangleF(tabX, contentBounds.Y, tabWidth, mTabHeight);
				mTabBounds.Add(tabRect);
				tabX += tabWidth + 2;
			}

			// Panel content below tabs
			panelBounds = .(
				contentBounds.X,
				contentBounds.Y + mTabHeight,
				contentBounds.Width,
				contentBounds.Height - mTabHeight
			);
		}
		else
		{
			// No tabs - full area for panel
			panelBounds = contentBounds;
		}

		// Arrange selected panel
		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			mPanels[mSelectedIndex].Arrange(panelBounds);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Get theme styles
		let groupStyle = GetThemeStyle();
		let accentColor = Context?.Theme?.Palette.Accent ?? Color(60, 120, 200, 255);

		if (mPanels.Count == 0)
		{
			// Empty group - show placeholder
			let bounds = ArrangedBounds;
			ctx.FillRect(bounds, groupStyle.Background);
			ctx.DrawText("Empty", 12, .(bounds.X + bounds.Width / 2 - 20, bounds.Y + bounds.Height / 2), groupStyle.Foreground);
			return;
		}

		if (mPanels.Count > 1)
		{
			// Render tab strip background
			let tabStripBounds = RectangleF(ArrangedBounds.X, ArrangedBounds.Y, ArrangedBounds.Width, mTabHeight);
			if (mTabStripImage.HasValue && mTabStripImage.Value.IsValid)
			{
				ctx.DrawImageBrush(mTabStripImage.Value, tabStripBounds);
			}
			else
			{
				ctx.FillRect(tabStripBounds, groupStyle.Background);

				// Tab strip bottom border (skip when using strip image)
				ctx.DrawLine(
					.(ArrangedBounds.X, ArrangedBounds.Y + mTabHeight),
					.(ArrangedBounds.Right, ArrangedBounds.Y + mTabHeight),
					groupStyle.BorderColor, 1
				);
			}

			// Render tabs
			for (int i = 0; i < mTabBounds.Count && i < mPanels.Count; i++)
			{
				let tabBounds = mTabBounds[i];
				let panel = mPanels[i];
				let isSelected = (i == mSelectedIndex);
				let isHovered = (i == mHoveredTabIndex);

				RenderTab(ctx, tabBounds, panel.Title, isSelected, isHovered, panel.IsCloseable);
			}

			// Draw drop insert indicator
			if (mDropInsertIndex >= 0)
			{
				float indicatorX;
				if (mDropInsertIndex < mTabBounds.Count)
					indicatorX = mTabBounds[mDropInsertIndex].X - 1;
				else if (mTabBounds.Count > 0)
					indicatorX = mTabBounds[mTabBounds.Count - 1].Right + 1;
				else
					indicatorX = ArrangedBounds.X;

				ctx.FillRect(.(indicatorX - 1, ArrangedBounds.Y + 2, 3, mTabHeight - 4), accentColor);
			}
		}

		// Render selected panel
		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			mPanels[mSelectedIndex].Render(ctx);
		}

		// Render edge highlight for drag-dock feedback
		if (mDropZone != null && mDropZone != .Center)
		{
			let edgeBounds = CalculateEdgeZoneBounds(mDropZone.Value);
			ctx.FillRect(edgeBounds, Color(accentColor.R, accentColor.G, accentColor.B, 80));
			ctx.DrawRect(edgeBounds, Color(accentColor.R, accentColor.G, accentColor.B, 180), 2);
		}
	}

	private void RenderTab(DrawContext ctx, RectangleF bounds, StringView title, bool isSelected, bool isHovered, bool isCloseable)
	{
		// Get tab style from theme
		let tabStyle = Context?.Theme?.GetControlStyle("DockTab") ?? GetThemeStyle();

		// Try image-based tab rendering
		let tabImage = isSelected ? mActiveTabImage : mInactiveTabImage;
		if (tabImage.HasValue && tabImage.Value.IsValid)
		{
			var img = tabImage.Value;
			if (!isSelected && isHovered)
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, bounds);
		}
		else
		{
			// Tab background
			Color bgColor;
			if (isSelected)
				bgColor = tabStyle.Pressed.Background ?? tabStyle.Background;
			else if (isHovered)
				bgColor = tabStyle.Hover.Background ?? tabStyle.Background;
			else
				bgColor = tabStyle.Background;

			ctx.FillRect(bounds, bgColor);

			// Tab border (selected tabs have a colored top border)
			if (isSelected)
			{
				ctx.FillRect(.(bounds.X, bounds.Y, bounds.Width, 2), tabStyle.BorderColor);
			}
		}

		// Tab text - vertically centered
		let fontSize = Context?.Theme?.DockFontSize ?? 12.0f;
		let padding = Context?.Theme?.DockTabPadding ?? 8.0f;
		let textColor = isSelected ? (tabStyle.Pressed.Foreground ?? tabStyle.Foreground) : tabStyle.Foreground;
		let textX = bounds.X + padding;
		let textY = bounds.Y + (mTabHeight - fontSize) / 2;
		ctx.DrawText(title, fontSize, .(textX, textY), textColor);

		// Close button (small X on right side of tab)
		if (isCloseable && (isSelected || isHovered))
		{
			let closeSize = 12.0f;
			let closeX = bounds.Right - closeSize - 4;
			let closeY = bounds.Y + (mTabHeight - closeSize) / 2;
			let closeColor = Color(tabStyle.Foreground.R, tabStyle.Foreground.G, tabStyle.Foreground.B, 150);
			let closePadding = 2.0f;
			ctx.DrawLine(.(closeX + closePadding, closeY + closePadding), .(closeX + closeSize - closePadding, closeY + closeSize - closePadding), closeColor, 1);
			ctx.DrawLine(.(closeX + closeSize - closePadding, closeY + closePadding), .(closeX + closePadding, closeY + closeSize - closePadding), closeColor, 1);
		}
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		let point = Vector2(e.ScreenX, e.ScreenY);
		mHoveredTabIndex = GetTabIndexAtPoint(point);
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredTabIndex = -1;
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left)
		{
			let point = Vector2(e.ScreenX, e.ScreenY);
			let tabIndex = GetTabIndexAtPoint(point);

			if (tabIndex >= 0)
			{
				let tabBounds = mTabBounds[tabIndex];
				let panel = mPanels[tabIndex];

				// Check if close button was clicked
				if (panel.IsCloseable)
				{
					let closeSize = 12.0f;
					let closeX = tabBounds.Right - closeSize - 4;
					let closeY = tabBounds.Y + (mTabHeight - closeSize) / 2;
					let closeBounds = RectangleF(closeX, closeY, closeSize, closeSize);

					if (closeBounds.Contains(point.X, point.Y))
					{
						OnPanelCloseRequested(panel);
						e.Handled = true;
						return;
					}
				}

				// Select the tab and prepare for potential drag
				SelectedIndex = tabIndex;
				mDragTabIndex = tabIndex;
				mDragPending = true;
				mDragStartPos = point;

				// Initiate potential drag
				if (Context != null && Context.DragDropManager != null)
				{
					let dragData = new DockPanelDragData(panel, this, tabIndex);
					Context.DragDropManager.BeginPotentialDrag(this, dragData, .Move, point);
				}

				e.Handled = true;
			}
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (e.Button == .Left)
		{
			mDragPending = false;
			mDragTabIndex = -1;
		}
	}

	private int GetTabIndexAtPoint(Vector2 point)
	{
		for (int i = 0; i < mTabBounds.Count; i++)
		{
			if (mTabBounds[i].Contains(point.X, point.Y))
				return i;
		}
		return -1;
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check if in tab strip
		if (mPanels.Count > 1)
		{
			let tabStripBounds = RectangleF(ArrangedBounds.X, ArrangedBounds.Y, ArrangedBounds.Width, mTabHeight);
			if (tabStripBounds.Contains(point.X, point.Y))
				return this;
		}

		// Check selected panel
		if (mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
		{
			let hit = mPanels[mSelectedIndex].HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// === IDragSource Implementation ===

	/// Returns whether a drag can be started from this tab group.
	public bool CanStartDrag()
	{
		return mDragTabIndex >= 0 && mDragTabIndex < mPanels.Count;
	}

	/// Creates drag data for the panel being dragged.
	public DragData CreateDragData()
	{
		if (mDragTabIndex >= 0 && mDragTabIndex < mPanels.Count)
		{
			return new DockPanelDragData(mPanels[mDragTabIndex], this, mDragTabIndex);
		}
		return null;
	}

	/// Gets allowed drop effects for dock panel drag.
	public DragDropEffects GetAllowedEffects()
	{
		return .Move;
	}

	/// Creates the visual representation for the drag adorner.
	public void CreateDragVisual(DragAdorner adorner)
	{
		if (mDragTabIndex >= 0 && mDragTabIndex < mPanels.Count)
		{
			let panel = mPanels[mDragTabIndex];
			adorner.SetLabel(panel.Title);
			adorner.Size = .(120, 30);
		}
	}

	/// Called when drag actually starts.
	public void OnDragStarted(DragEventArgs args)
	{
		// Visual feedback could be added here (e.g., ghost tab)
	}

	/// Called when drag completes.
	public void OnDragCompleted(DragEventArgs args)
	{
		mDragPending = false;
		mDragTabIndex = -1;
	}

	// === IDropTarget Implementation ===

	/// Returns whether this tab group can accept dock panel drops.
	public bool CanAcceptDrop(DragData data)
	{
		return data != null && data.Format == DockPanelDragDataFormat.DockPanel;
	}

	/// Called when a drag enters this tab group.
	public void OnDragEnter(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		args.Effect = .Move;
	}

	/// Called while dragging over this tab group.
	public void OnDragOver(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		args.Effect = .Move;

		// Calculate drop zone based on cursor position
		mDropZone = CalculateDropZone(args.Position);

		// Only calculate insert index for center (tab) drops
		if (mDropZone == .Center)
			mDropInsertIndex = CalculateInsertIndex(args.Position);
		else
			mDropInsertIndex = -1;
	}

	/// Calculates the tab index where a drop should insert.
	private int CalculateInsertIndex(Vector2 point)
	{
		if (mTabBounds.Count == 0)
			return 0;

		// Check each tab - insert before a tab if cursor is in left half, after if in right half
		for (int i = 0; i < mTabBounds.Count; i++)
		{
			let tabBounds = mTabBounds[i];
			if (point.X < tabBounds.X + tabBounds.Width / 2)
				return i;
		}

		// Past all tabs - insert at end
		return mTabBounds.Count;
	}

	/// Calculates the drop zone based on cursor position within the group.
	/// Returns edge positions for docking relative to this group, or Center for tab drop.
	/// Edge zones are calculated from the content area (excluding header) for better UX.
	private DockPosition CalculateDropZone(Vector2 point)
	{
		let bounds = ArrangedBounds;

		// Get the header height - either tab strip (multiple panels) or panel title bar (single panel)
		float headerHeight = 0;
		if (mPanels.Count > 1)
		{
			// Tab strip
			headerHeight = mTabHeight;
		}
		else if (mPanels.Count == 1)
		{
			// Single panel shows its own title bar
			headerHeight = mPanels[0].TitleBarHeight;
		}

		// If in header area, always treat as center for tab docking
		if (headerHeight > 0)
		{
			let headerBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, headerHeight);
			if (headerBounds.Contains(point.X, point.Y))
				return .Center;
		}

		// Calculate content area (below header)
		RectangleF contentArea;
		if (headerHeight > 0)
			contentArea = .(bounds.X, bounds.Y + headerHeight, bounds.Width, bounds.Height - headerHeight);
		else
			contentArea = bounds;

		// Edge size is 25% of the smaller content dimension
		let edgeSize = Math.Min(contentArea.Width, contentArea.Height) * 0.25f;

		// Check edges relative to content area
		if (point.Y < contentArea.Y + edgeSize) return .Top;
		if (point.Y > contentArea.Bottom - edgeSize) return .Bottom;
		if (point.X < contentArea.X + edgeSize) return .Left;
		if (point.X > contentArea.Right - edgeSize) return .Right;

		// Center zone - add as tab
		return .Center;
	}

	/// Calculates the bounds of an edge zone for visual feedback.
	/// Uses content area (excluding header) to match CalculateDropZone.
	private RectangleF CalculateEdgeZoneBounds(DockPosition zone)
	{
		let bounds = ArrangedBounds;

		// Get the header height - either tab strip (multiple panels) or panel title bar (single panel)
		float headerHeight = 0;
		if (mPanels.Count > 1)
			headerHeight = mTabHeight;
		else if (mPanels.Count == 1)
			headerHeight = mPanels[0].TitleBarHeight;

		// Calculate content area (below header)
		RectangleF contentArea;
		if (headerHeight > 0)
			contentArea = .(bounds.X, bounds.Y + headerHeight, bounds.Width, bounds.Height - headerHeight);
		else
			contentArea = bounds;

		let edgeSize = Math.Min(contentArea.Width, contentArea.Height) * 0.25f;

		switch (zone)
		{
		case .Top:
			return .(contentArea.X, contentArea.Y, contentArea.Width, edgeSize);
		case .Bottom:
			return .(contentArea.X, contentArea.Bottom - edgeSize, contentArea.Width, edgeSize);
		case .Left:
			return .(contentArea.X, contentArea.Y, edgeSize, contentArea.Height);
		case .Right:
			return .(contentArea.Right - edgeSize, contentArea.Y, edgeSize, contentArea.Height);
		default:
			return contentArea;
		}
	}

	/// Called when a drag leaves this tab group.
	public void OnDragLeave(DragEventArgs args)
	{
		mDropInsertIndex = -1;
		mDropZone = null;
	}

	/// Called when drop occurs on this tab group.
	public void OnDrop(DragEventArgs args)
	{
		if (args.Data.Format != DockPanelDragDataFormat.DockPanel)
			return;

		let panelData = args.Data as DockPanelDragData;
		if (panelData == null || panelData.Panel == null)
			return;

		let panel = panelData.Panel;
		let insertIndex = mDropInsertIndex;
		let dropZone = mDropZone ?? .Center;
		mDropInsertIndex = -1;
		mDropZone = null;

		// Get manager (find by walking up tree if necessary)
		let manager = GetManager();

		// Edge drop - dock relative to this group (creates a split)
		if (dropZone != .Center && manager != null)
		{
			// Special case: dropping the only panel from this group onto its own edge.
			// This is a meaningless operation - the result would be the same single panel
			// in a new layout position. Just ignore this drop.
			if (panelData.SourceGroup == this && mPanels.Count == 1)
			{
				args.Handled = true;
				return;
			}

			// Remove from source (either tab group or floating window)
			if (panelData.SourceGroup != null)
			{
				panelData.SourceGroup.RemovePanel(panel);
				// Only cleanup if source is different from target to avoid deleting 'this'
				// When source == this (multi-panel case), defer cleanup until after the dock
				if (panelData.SourceGroup != this)
					manager.CleanupEmptyNodes();
			}
			else
			{
				// May be from a floating window
				manager.RemovePanelFromFloatingWindow(panel);
			}

			// Dock relative to this group
			manager.DockPanelRelativeToGroup(panel, this, dropZone);

			// Deferred cleanup if source was same as target (for multi-panel case)
			if (panelData.SourceGroup == this)
				manager.CleanupEmptyNodes();

			args.Handled = true;
			return;
		}

		// Center drop - reordering within same group
		if (panelData.SourceGroup == this)
		{
			let sourceIndex = panelData.SourceTabIndex;

			// Calculate actual target index after removal
			var targetIndex = insertIndex;
			if (sourceIndex < targetIndex)
				targetIndex--;  // Adjust since source will be removed first

			// Only reorder if position actually changed
			if (sourceIndex != targetIndex && targetIndex >= 0 && targetIndex < mPanels.Count)
			{
				// Remove from old position
				mPanels.RemoveAt(sourceIndex);

				// Insert at new position
				mPanels.Insert(targetIndex, panel);

				// Update selection to follow the moved tab
				mSelectedIndex = targetIndex;
				InvalidateLayout();
			}

			args.Handled = true;
			return;
		}

		// Center drop - add panel from different group or floating window
		// Remove from source
		if (panelData.SourceGroup != null)
		{
			panelData.SourceGroup.RemovePanel(panel);

			// Clean up empty groups and collapsed splits
			if (manager != null)
				manager.CleanupEmptyNodes();
		}
		else if (manager != null)
		{
			// May be from a floating window
			manager.RemovePanelFromFloatingWindow(panel);
		}

		// Add to this group at insert position
		if (insertIndex >= 0 && insertIndex <= mPanels.Count)
			InsertPanel(insertIndex, panel);
		else
			AddPanel(panel);

		args.Handled = true;
	}

	// === Floating Window Drag Support ===

	/// Updates drop zone feedback for floating window drag (bypasses drag-drop system).
	/// Returns the calculated drop zone if point is within this group's bounds, null otherwise.
	public DockPosition? UpdateFloatingDragFeedback(Vector2 point)
	{
		if (!ArrangedBounds.Contains(point.X, point.Y))
		{
			mDropZone = null;
			return null;
		}

		mDropZone = CalculateDropZone(point);
		return mDropZone;
	}

	/// Clears floating window drag feedback.
	public void ClearFloatingDragFeedback()
	{
		mDropZone = null;
		mDropInsertIndex = -1;
	}

	// === Child Detachment ===

	/// Override to support polymorphic child detachment.
	/// Called by MutationQueue when deleting a panel.
	public override UIElement TryDetachChild(UIElement child)
	{
		if (let panel = child as DockablePanel)
		{
			let index = mPanels.IndexOf(panel);
			if (index >= 0)
			{
				mPanels.RemoveAt(index);
				panel.ParentGroup = null;
				panel.SetParent(null);
				if (Context != null)
					panel.OnDetachedFromContext();

				// Adjust selection
				if (mPanels.Count == 0)
				{
					mSelectedIndex = -1;
					mEmpty.[Friend]Invoke(this);
				}
				else if (mSelectedIndex >= mPanels.Count)
				{
					mSelectedIndex = mPanels.Count - 1;
				}
				else if (mSelectedIndex == index && mSelectedIndex > 0)
				{
					mSelectedIndex--;
				}

				InvalidateLayout();
				return panel;
			}
		}
		return null;
	}

	// === Visual Children ===

	public override int VisualChildCount => mPanels.Count > 0 ? 1 : 0;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mSelectedIndex >= 0 && mSelectedIndex < mPanels.Count)
			return mPanels[mSelectedIndex];
		return null;
	}
}
