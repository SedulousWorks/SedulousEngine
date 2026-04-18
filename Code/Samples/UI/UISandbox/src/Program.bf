namespace UISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.Fonts;
using Sedulous.Shell.Input;
using Sedulous.ImageData;
using Sedulous.Imaging;
using Sedulous.Imaging.STB;
using Sedulous.UI.Resources;
using Sedulous.UI.Toolkit;
using Sedulous.Shell;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Shaders;

// === ImageView with rich tooltip (image + text) ===
// Demonstrates ITooltipProvider for custom tooltip content.

class RichTooltipImageView : ImageView, ITooltipProvider
{
	public String TooltipLabel ~ delete _;
	public IImageData TooltipImage;

	public View CreateTooltipContent()
	{
		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Spacing = 4;

		if (TooltipImage != null)
		{
			let img = new ImageView();
			img.Image = TooltipImage;
			layout.AddView(img, new LinearLayout.LayoutParams() { Width = 64, Height = 64 });
		}

		if (TooltipLabel != null)
		{
			let label = new Label();
			label.SetText(TooltipLabel);
			label.FontSize = 12;
			layout.AddView(label, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.WrapContent, Height = 16 });
		}

		return layout;
	}
}

// === Custom control: StatusBadge ===
// Demonstrates a user-defined control themed via IThemeExtension.

class StatusBadge : View
{
	public String Text ~ delete _;
	private Color? mBadgeColor;
	private Color? mTextColor;

	public Color BadgeColor
	{
		get => mBadgeColor ?? Context?.Theme?.GetColor("StatusBadge.Background") ?? .(100, 100, 100, 255);
		set => mBadgeColor = value;
	}

	public Color TextColor
	{
		get => mTextColor ?? Context?.Theme?.GetColor("StatusBadge.Foreground") ?? .White;
		set => mTextColor = value;
	}

	public void SetText(StringView text)
	{
		if (Text == null) Text = new String(text);
		else Text.Set(text);
		InvalidateLayout();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float textW = 40;
		if (Text != null && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(12);
			if (font != null) textW = font.Font.MeasureString(Text);
		}
		MeasuredSize = .(wSpec.Resolve(textW + 16), hSpec.Resolve(22));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let radius = ctx.Theme?.GetDimension("StatusBadge.Radius", 11) ?? 11;
		ctx.VG.FillRoundedRect(.(0, 0, Width, Height), radius, BadgeColor);
		if (Text != null && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(12);
			if (font != null)
				ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), .Center, .Middle, TextColor);
		}
	}
}

// === Theme extension for StatusBadge ===
// Registers once; applies to every theme (Dark and Light get different values).

class StatusBadgeThemeExtension : IThemeExtension
{
	public void Apply(Theme theme)
	{
		if (theme.Name.Contains("Dark"))
		{
			theme.SetColor("StatusBadge.Background", .(50, 140, 90, 255));  // green on dark
			theme.SetColor("StatusBadge.Foreground", .White);
		}
		else
		{
			theme.SetColor("StatusBadge.Background", .(40, 100, 180, 255)); // blue on light
			theme.SetColor("StatusBadge.Foreground", .White);
		}
		theme.SetDimension("StatusBadge.Radius", 11);
	}
}

// === Sandbox list adapter for ListView demo ===

class SandboxListAdapter : IListAdapter
{
	private int32 mCount;

	public this(int32 count) { mCount = count; }

	public int32 ItemCount => mCount;
	public void SetObserver(IListAdapterObserver observer) { }

	public View CreateView(int32 viewType)
	{
		return new Label();
	}

	public void BindView(View view, int32 position)
	{
		if (let label = view as Label)
		{
			let text = scope String();
			text.AppendF("List item {} of {}", position + 1, mCount);
			label.SetText(text);
		}
	}
}

// === Tree item view with VG-drawn expand arrow ===

class TreeItemView : View
{
	public String Text ~ delete _;
	public int32 Depth;
	public bool HasChildren;
	public bool IsExpanded;
	private float mIndent = 20;

	public void Set(StringView text, int32 depth, bool hasChildren, bool isExpanded)
	{
		if (Text == null) Text = new String(text);
		else Text.Set(text);
		Depth = depth;
		HasChildren = hasChildren;
		IsExpanded = isExpanded;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let indent = Depth * mIndent;
		let arrowSize = 8.0f;
		let arrowX = indent + 4;
		let arrowCY = Height * 0.5f;

		// Draw expand/collapse triangle for nodes with children.
		if (HasChildren)
		{
			let arrowColor = ctx.Theme?.Palette.Text ?? Color(200, 200, 200, 255);
			ctx.VG.BeginPath();
			if (IsExpanded)
			{
				// Down-pointing triangle (v).
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.3f);
				ctx.VG.LineTo(arrowX + arrowSize, arrowCY - arrowSize * 0.3f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.5f, arrowCY + arrowSize * 0.4f);
			}
			else
			{
				// Right-pointing triangle (>).
				ctx.VG.MoveTo(arrowX, arrowCY - arrowSize * 0.4f);
				ctx.VG.LineTo(arrowX + arrowSize * 0.6f, arrowCY);
				ctx.VG.LineTo(arrowX, arrowCY + arrowSize * 0.4f);
			}
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}

		// Draw text label.
		if (Text != null && Text.Length > 0 && ctx.FontService != null)
		{
			let textX = indent + mIndent;
			let textColor = ctx.Theme?.GetColor("Label.Foreground") ?? Color(220, 220, 230, 255);
			let font = ctx.FontService.GetFont(14);
			if (font != null)
				ctx.VG.DrawText(Text, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
		}
	}
}

// === Sandbox tree adapter for TreeView demo ===
// Simulates a filesystem: 5 folders, each with 3 files.

class SandboxTreeAdapter : ITreeAdapter
{
	public int32 RootCount => 5;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1) return 5;
		if (nodeId < 5) return 3;
		return 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1) return childIndex;
		return parentId * 10 + 10 + childIndex;
	}

	public int32 GetDepth(int32 nodeId) => (nodeId >= 10) ? 1 : 0;
	public bool HasChildren(int32 nodeId) => nodeId < 5;

	public View CreateView(int32 viewType) => new TreeItemView();

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let item = view as TreeItemView)
		{
			let name = scope String();
			if (HasChildren(nodeId))
				name.AppendF("Folder {}", nodeId);
			else
				name.AppendF("file_{}.txt", nodeId);
			item.Set(name, depth, HasChildren(nodeId), isExpanded);
		}
	}
}

/// DragData carrying a reference to the source DragChip.
class ChipDragData : DragData
{
	public DragChip SourceChip;

	public this(DragChip source) : base("demo/chip")
	{
		SourceChip = source;
	}
}

/// Draggable color chip. Implements IDragSource.
class DragChip : ColorView, IDragSource
{
	public DragData CreateDragData()
	{
		return new ChipDragData(this);
	}

	public View CreateDragVisual(DragData data)
	{
		// Custom drag preview — a small color swatch with a border.
		let panel = new Panel();
		panel.Background = new RoundedRectDrawable(Color, 4, .(200, 200, 210, 255), 1);
		let label = new Label();
		let hex = scope String();
		hex.AppendF("#{0:X2}{1:X2}{2:X2}", Color.R, Color.G, Color.B);
		label.SetText(hex);
		label.FontSize = 11;
		panel.AddView(label, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
		panel.Padding = .(6, 2);
		return panel;
	}

	public void OnDragStarted(DragData data) { Alpha = 0.4f; }
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled) { Alpha = 1.0f; }
}

/// Reorder container — drag chips to swap their positions.
class ChipReorderContainer : LinearLayout, IDropTarget
{
	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		return (data.Format == "demo/chip") ? .Move : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY) { }
	public void OnDragOver(DragData data, float localX, float localY) { }
	public void OnDragLeave(DragData data) { }

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (let chipData = data as ChipDragData)
		{
			let sourceChip = chipData.SourceChip;

			// Find which child position was dropped on.
			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (localX >= child.Bounds.X && localX < child.Bounds.X + child.Width)
				{
					if (let targetChip = child as DragChip)
					{
						if (targetChip !== sourceChip)
						{
							// Swap colors.
							let tempColor = sourceChip.Color;
							sourceChip.Color = targetChip.Color;
							targetChip.Color = tempColor;
						}
						return .Move;
					}
				}
			}
		}
		return .None;
	}
}

/// Drop target box that changes color when a chip is dropped on it.
class ColorDropBox : Panel, IDropTarget
{
	private Label mLabel;

	public this()
	{
		Padding = .(8, 4);
		mLabel = new Label();
		mLabel.SetText("Drop here");
		mLabel.HAlign = .Center;
		mLabel.VAlign = .Middle;
		mLabel.FontSize = 12;
		AddView(mLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
	}

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		return (data.Format == "demo/chip") ? .Copy : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		mLabel.SetText("Release!");
	}

	public void OnDragOver(DragData data, float localX, float localY) { }

	public void OnDragLeave(DragData data)
	{
		mLabel.SetText("Drop here");
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (let chipData = data as ChipDragData)
		{
			// Change background to the dragged chip's color.
			delete Background;
			Background = new RoundedRectDrawable(chipData.SourceChip.Color, 6);
			mLabel.SetText("Dropped!");
		}
		return .Copy;
	}
}

/// Label with a right-click context menu to copy its text.
class CopyableLabel : Label
{
	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Right && Context != null)
		{
			let menu = new ContextMenu();
			menu.AddItem("Copy", new [&]() =>
			{
				Context?.Clipboard?.SetText(Text);
			});

			// Convert to screen coords.
			float sx = e.X + Bounds.X, sy = e.Y + Bounds.Y;
			var v = Parent;
			while (v != null) { sx += v.Bounds.X; sy += v.Bounds.Y; v = v.Parent; }
			menu.Show(Context, sx, sy);
			e.Handled = true;
		}
	}
}

/// UISandbox — gallery/showcase for Sedulous.UI, growing with each phase.
/// Per-window render data for secondary (floating) windows.
class FloatingWindowRenderData
{
	public RootView RootView ~ delete _;
	public Sedulous.VG.VGContext VGContext ~ delete _;
	public Sedulous.VG.Renderer.VGRenderer VGRenderer ~ { _.Dispose(); delete _; };
	public View FloatingView; // non-owning ref to the floating window in the root
	public delegate void(View) OnCloseDelegate ~ delete _; // owns the callback from DockManager
}

class UISandboxApp : Application, Sedulous.UI.Toolkit.IFloatingWindowHost
{
	private UISubsystem mUI;
	private OwnedImageData mCheckerboard ~ delete _;
	private OwnedImageData mButtonNormal ~ delete _;
	private OwnedImageData mButtonPressed ~ delete _;
	private DemoContext mDemoCtx ~ delete _;
	private ControlsPage mControlsPage; // for progress bar tick

	// Map floating window view → secondary window context for OS floating windows.
	private System.Collections.Dictionary<View, SecondaryWindowContext> mFloatingWindowMap = new .() ~ delete _;

	// Cross-window drag state.
	private bool mDragPrevLeftDown;
	private IWindow mDragSourceWindow; // OS window being dragged
	private float mDragWindowOffsetX;  // Mouse offset within window at drag start
	private float mDragWindowOffsetY;

	public this() : base()
	{
	}



	/// Load a PNG/JPG file and convert to OwnedImageData (RGBA8).
	private OwnedImageData LoadImageAsRGBA8(StringView path)
	{
		if (ImageLoaderFactory.LoadImage(path) case .Ok(let loaded))
		{
			OwnedImageData result;
			if (loaded.Format == .RGBA8)
			{
				result = new OwnedImageData(loaded.Width, loaded.Height, .RGBA8, loaded.Data);
			}
			else
			{
				// Convert to RGBA8.
				if (loaded.ConvertFormat(.RGBA8) case .Ok(let converted))
				{
					result = new OwnedImageData(converted.Width, converted.Height, .RGBA8, converted.Data);
					delete converted;
				}
				else
				{
					delete loaded;
					return null;
				}
			}
			delete loaded;
			return result;
		}
		return null;
	}

	protected override void OnInitialize(Sedulous.Runtime.Context context)
	{
		// Register built-in view types for XML loading.
		UIRegistry.RegisterBuiltins();

		// Register theme extensions BEFORE subsystem creates the default theme.
		Theme.RegisterExtension(new StatusBadgeThemeExtension());
		Theme.RegisterExtension(new Sedulous.UI.Toolkit.ToolkitThemeExtension());

		// Create the UI subsystem.
		mUI = new UISubsystem();
		context.RegisterSubsystem(mUI);

		// Initialize rendering.
		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);

		if (mUI.InitializeRendering(Device, SwapChain.Format, (int32)SwapChain.BufferCount,
			scope StringView[](shaderPath), Shell, Window) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Load font.
		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		mUI.LoadFont("Roboto", fontPath, .() { PixelHeight = 16 });
		mUI.LoadFont("Roboto", fontPath, .() { PixelHeight = 24 });

		// Register STB image loader for PNG loading.
		STBImageLoader.Initialize();

		// Generate a checkerboard image for ImageView / ImageDrawable demos.
		let img = Image.CreateCheckerboard(64, .(200, 200, 210, 255), .(60, 60, 70, 255), 8);
		mCheckerboard = new OwnedImageData(img.Width, img.Height, .RGBA8, img.Data);
		delete img;

		// Load Kenney pixel-UI 9-slice button images.
		String nineslicePath = scope .();
		GetAssetPath("samples/kenney_pixel-ui-pack/9-Slice/Colored/blue.png", nineslicePath);
		mButtonNormal = LoadImageAsRGBA8(nineslicePath);

		String nineslicePressedPath = scope .();
		GetAssetPath("samples/kenney_pixel-ui-pack/9-Slice/Colored/blue_pressed.png", nineslicePressedPath);
		mButtonPressed = LoadImageAsRGBA8(nineslicePressedPath);

		// Build the demo tree.
		mDemoCtx = new DemoContext();
		mDemoCtx.UI = mUI;
		mDemoCtx.Checkerboard = mCheckerboard;
		mDemoCtx.ButtonNormal = mButtonNormal;
		mDemoCtx.ButtonPressed = mButtonPressed;
		mDemoCtx.FloatingWindowHost = this;
		BuildDemoUI(mUI.UIContext);
	}

	private void BuildDemoUI(UIContext ctx)
	{
		let root = mUI.Root;

		// Tabbed layout with left-side tabs for focused demos.
		let tabs = new TabView();
		tabs.Placement = .Left;
		tabs.TabHeight = 28;
		tabs.TabFontSize = 12;
		root.AddView(tabs);

		// Create pages.
		let widgetsPage = new WidgetsPage(mDemoCtx);
		tabs.AddTab("Widgets", widgetsPage);

		mControlsPage = new ControlsPage(mDemoCtx);
		tabs.AddTab("Controls", mControlsPage);

		tabs.AddTab("Text", new TextEditingPage(mDemoCtx));
		tabs.AddTab("Data", new DataPage(mDemoCtx));
		tabs.AddTab("Overlays", new OverlaysPage(mDemoCtx));
		tabs.AddTab("Animation", new AnimationPage(mDemoCtx));
		tabs.AddTab("Drag & Drop", new DragDropPage(mDemoCtx));
		tabs.AddTab("Toolkit", new ToolkitPage(mDemoCtx));
		tabs.AddTab("Docking", new DockingPage(mDemoCtx));
	}

	/*
	// Keep the old BuildDemoUI content commented out — remove after verification.
	private void BuildDemoUI_Old(UIContext ctx)
	{
		let root = mUI.Root;

		// Scrollable root — content stacks vertically with fixed-height
		// list/tree views. Scrolls when window is smaller than content.
		let scroll = new ScrollView();
		scroll.VScrollPolicy = .Auto;
		scroll.HScrollPolicy = .Never;
		root.AddView(scroll);

		let main = new LinearLayout();
		main.Orientation = .Vertical;
		main.Padding = .(12);
		main.Spacing = 8;
		scroll.AddView(main, new LayoutParams() { Width = LayoutParams.MatchParent });

		// === Top bar: weighted colors (Phase 1) ===
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 4;
			main.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
			AddWeightedColor(row, Color(200, 70, 70, 255), 2);
			AddWeightedColor(row, Color(70, 180, 70, 255), 1);
			AddWeightedColor(row, Color(70, 100, 220, 255), 1);
		}

		// === Two-column body ===
		let columns = new LinearLayout();
		columns.Orientation = .Horizontal;
		columns.Spacing = 12;
		main.AddView(columns, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });

		// --- LEFT COLUMN ---
		let left = new LinearLayout();
		left.Orientation = .Vertical;
		left.Spacing = 6;
		columns.AddView(left, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Weight = 1 });

		AddSectionLabel(left, "Widgets");

		// Label
		{
			let label = new Label();
			label.SetText("Label — 16px Roboto (theme color)");
			label.TooltipText = new String("Tooltip: Right placement");
			label.TooltipPlacement = .Right;
				left.AddView(label, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });
		}

		// Buttons (clickable in Phase 3!)
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });
			AddButton(row, "Primary", Color(50, 100, 200, 255), "Tooltip: Bottom (default)", .Bottom);
			AddButton(row, "Success", Color(50, 160, 70, 255), "Tooltip: Top placement", .Top);
			AddButton(row, "Danger", Color(200, 60, 60, 255), "Tooltip: Left placement", .Left);
		}

		// Theme-styled buttons (no explicit Background — uses theme).
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });

			for (let label in StringView[]("Theme Btn 1", "Theme Btn 2"))
			{
				let btn = new Button();
				btn.SetText(label);
				// No Background set — uses DrawDefaultBackground from theme.
				btn.OnClick.Add(new [&](b) => {
					if (mClickLabel != null)
					{
						let msg = scope String();
						msg.AppendF("Clicked: {}", b.Text);
						mClickLabel.SetText(msg);
						mClickLabel.TextColor = mUI.UIContext.Theme?.Palette.Success ?? .(60, 180, 80, 255);
					}
				});
				row.AddView(btn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
			}
		}

		// Click feedback label.
		{
			mClickLabel = new Label();
			mClickLabel.SetText("Click / Tab / F5=toggle theme");
			left.AddView(mClickLabel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 20 });
		}

		// Panel — draws theme-aware background.
		{
			let panel = new Panel();
			panel.Padding = .(10, 6);
			panel.TooltipText = new String("Panel with theme-driven background and border");
			left.AddView(panel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });
			let panelLabel = new Label();
			panelLabel.SetText("Panel (theme background)");
			panel.AddView(panelLabel, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
		}

		AddSeparator(left);
		AddSectionLabel(left, "FlowLayout");

		// Flow chips
		{
			let flow = new FlowLayout();
			flow.Orientation = .Horizontal;
			flow.HSpacing = 4;
			flow.VSpacing = 4;
			left.AddView(flow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 70 });
			for (int i = 0; i < 16; i++)
			{
				let chip = new ColorView();
				chip.Color = HSLToColor((float)i / 16.0f, 0.6f, 0.45f);
				chip.PreferredWidth = 36;
				chip.PreferredHeight = 26;
				flow.AddView(chip);
			}
		}

		AddSeparator(left);
		AddSectionLabel(left, "AbsoluteLayout");

		{
			let abs = new AbsoluteLayout();
			left.AddView(abs, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 60 });
			AddAbsBox(abs, .(200, 80, 80, 200), 10, 5, 50, 35);
			AddAbsBox(abs, .(80, 200, 80, 200), 45, 18, 50, 35);
			AddAbsBox(abs, .(80, 80, 200, 200), 80, 5, 50, 35);
		}

		AddSeparator(left);
		AddSectionLabel(left, "ImageView ScaleType");

		// Four images showing each ScaleType, all rendering a 64x64
		// checkerboard into a non-square box.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 50 });

			ScaleType[?] scaleTypes = .(.None, .FitCenter, .FillBounds, .CenterCrop);
			StringView[?] scaleNames = .("None", "FitCenter", "FillBounds", "CenterCrop");

			for (int si = 0; si < scaleTypes.Count; si++)
			{
				let panel = new Panel();
				panel.Padding = .(1);
				row.AddView(panel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

				let iv = new ImageView();
				iv.Image = mCheckerboard;
				iv.ScaleType = scaleTypes[si];
				iv.TooltipText = new String(scaleNames[si]);
				iv.TooltipPlacement = .Top;
				panel.AddView(iv, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
			}
		}

		left.AddView(new Spacer(0, 16));

		// Interactive rich tooltip on a standalone image.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 48 });
			let iv = new RichTooltipImageView();
			iv.Image = mCheckerboard;
			iv.ScaleType = .FitCenter;
			iv.TooltipImage = mCheckerboard;
			iv.TooltipLabel = new String("Interactive tooltip (hover me!)");
			iv.IsTooltipInteractive = true;
			iv.TooltipPlacement = .Right;
			row.AddView(iv, new LinearLayout.LayoutParams() { Width = 48, Height = 48 });
			row.AddView(new Spacer(8, 0));
			let desc = new Label();
			desc.SetText("Hover image for rich tooltip");
			desc.FontSize = 16;
			desc.VAlign = .Middle;
			row.AddView(desc, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });
		}

		AddSeparator(left);
		AddSectionLabel(left, "ScrollView (mouse wheel)");

		// ScrollView with tall content — scroll via mouse wheel.
		{
			let sv = new ScrollView();
			sv.VScrollPolicy = .Auto;
			left.AddView(sv, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 150 });

			let content = new LinearLayout();
			content.Orientation = .Vertical;
			content.Spacing = 4;
			sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent });

			for (int i = 0; i < 20; i++)
			{
				let label = new Label();
				let text = scope String();
				text.AppendF("Scrollable item {}", i + 1);
				label.SetText(text);
				content.AddView(label, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });
			}
		}

		AddSeparator(left);
		AddSectionLabel(left, "TreeView (dbl-click to expand)");

		{
			mTreeAdapter = new SandboxTreeAdapter();
			let tree = new TreeView();
			tree.ItemHeight = 22;
			tree.SetAdapter(mTreeAdapter);
			left.AddView(tree, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 180 });
		}

		AddSeparator(left);
		AddSectionLabel(left, "Text Editing");

		// EditText with placeholder.
		{
			let edit = new EditText();
			edit.SetPlaceholder("Type here...");
			left.AddView(edit, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });
		}

		// PasswordBox.
		{
			let pw = new PasswordBox();
			pw.SetPlaceholder("Password...");
			left.AddView(pw, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });
		}

		// Digits-only + max length.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });

			let digits = new EditText();
			digits.SetPlaceholder("Digits only");
			digits.Filter = InputFilter.Digits();
			row.AddView(digits, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

			let maxLen = new EditText();
			maxLen.SetPlaceholder("Max 8 chars");
			maxLen.MaxLength = 8;
			row.AddView(maxLen, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });
		}

		// Read-only.
		{
			let ro = new EditText();
			ro.SetText("Read-only text (try to edit)");
			ro.IsReadOnly = true;
			left.AddView(ro, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });
		}

		// Multiline.
		{
			let multi = new EditText();
			multi.Multiline = true;
			multi.SetPlaceholder("Multi-line text...");
			left.AddView(multi, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 80 });
		}

		// --- RIGHT COLUMN ---
		let right = new LinearLayout();
		right.Orientation = .Vertical;
		right.Spacing = 6;
		columns.AddView(right, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Weight = 1 });

		AddSectionLabel(right, "Drawable Showcase");

		// Drawable types — 2x2 grid
		{
			let grid = new GridLayout();
			grid.ColumnDefs.Add(.Star(1));
			grid.ColumnDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.HSpacing = 6;
			grid.VSpacing = 6;
			right.AddView(grid, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 110 });

			// Gradient
			let gradPanel = new Panel();
			gradPanel.Background = new GradientDrawable(.(80, 40, 180, 255), .(40, 160, 200, 255), .TopToBottom);
			grid.AddView(gradPanel, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

			// Image
			let imgPanel = new Panel();
			imgPanel.Background = new ImageDrawable(mCheckerboard);
			grid.AddView(imgPanel, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

			// Layer (gradient + border)
			let layered = new LayerDrawable();
			layered.AddLayer(new GradientDrawable(.(40, 80, 60, 255), .(20, 40, 80, 255), .LeftToRight));
			layered.AddLayer(new RoundedRectDrawable(.Transparent, 4, .(120, 200, 140, 255), 2));
			let layerPanel = new Panel();
			layerPanel.Background = layered;
			grid.AddView(layerPanel, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

			// Shape (custom X)
			let shapePanel = new Panel();
			shapePanel.Background = new ShapeDrawable(new (ctx, bounds) => {
				ctx.VG.FillRect(bounds, .(40, 40, 50, 255));
				ctx.VG.DrawLine(.(bounds.X, bounds.Y), .(bounds.X + bounds.Width, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
				ctx.VG.DrawLine(.(bounds.X + bounds.Width, bounds.Y), .(bounds.X, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
			});
			grid.AddView(shapePanel, new GridLayout.LayoutParams() { Row = 1, Column = 1 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "GridLayout (Auto / Star)");

		{
			let grid = new GridLayout();
			grid.ColumnDefs.Add(.Auto());
			grid.ColumnDefs.Add(.Star(2));
			grid.ColumnDefs.Add(.Star(1));
			grid.RowDefs.Add(.Pixel(22));
			grid.RowDefs.Add(.Pixel(22));
			grid.HSpacing = 6;
			grid.VSpacing = 2;
			right.AddView(grid, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 46 });

			AddGridCell(grid, "Name:", 0, 0);
			AddGridCell(grid, "Sedulous Engine", 0, 1);
			AddGridCell(grid, "v1.0", 0, 2);
			AddGridCell(grid, "Status:", 1, 0);
			AddGridCell(grid, "Phase 4", 1, 1);
			AddGridCell(grid, "OK", 1, 2);
		}

		AddSeparator(right);
		AddSectionLabel(right, "Custom Control + IThemeExtension");

		// StatusBadge — custom control themed via registered extension.
		// Colors change when F5 toggles theme.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 26 });

			for (let text in StringView[]("Online", "Active", "Ready"))
			{
				let badge = new StatusBadge();
				badge.SetText(text);
				row.AddView(badge);
			}

			// One with explicit override (ignores theme).
			let custom = new StatusBadge();
			custom.SetText("Custom");
			custom.BadgeColor = .(180, 60, 60, 255);
			custom.TooltipText = new String("Explicit color override — ignores theme");
			row.AddView(custom);
		}

		AddSeparator(right);
		AddSectionLabel(right, "NineSliceDrawable (Kenney)");

		// 9-slice buttons stretched to different widths.
		if (mButtonNormal != null)
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 42 });

			for (let w in float[](80, 140, 200))
			{
				let panel = new Panel();
				panel.Background = new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8));
				panel.Padding = .(8, 4);
				row.AddView(panel, new LinearLayout.LayoutParams() { Width = w, Height = LayoutParams.MatchParent });
				let label = new Label();
				label.SetText((w == 80) ? "Small" : ((w == 140) ? "Medium" : "Wide Button"));
				label.TextColor = .White;
						label.HAlign = .Center;
				panel.AddView(label, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
			}
		}

		// 9-slice StateList button.
		if (mButtonNormal != null && mButtonPressed != null)
		{
			let sld = new StateListDrawable();
			sld.Set(.Normal, new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8)));
			sld.Set(.Pressed, new NineSliceDrawable(mButtonPressed, .(8, 8, 8, 8)));
			sld.Set(.Hover, new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8), .(220, 230, 255, 255)));

			let btn = new Button();
			btn.SetText("9-Slice StateList");
			btn.Background = sld;
				right.AddView(btn, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 42 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "ListView (1000 items, virtualized)");

		// Virtualized ListView with 1000 items — only visible items created.
		{
			let list = new ListView();
			list.ItemHeight = 22;
			mListAdapter = new SandboxListAdapter(1000);
			list.Adapter = mListAdapter;
			right.AddView(list, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 200 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "XML-Loaded UI");

		// Load a UI fragment from an XML string.
		{
			let xml = """
				<LinearLayout orientation="Horizontal" spacing="6" padding="4">
				  <Button text="XML Btn 1" layout_weight="1" layout_width="match_parent" layout_height="match_parent"/>
				  <Button text="XML Btn 2" layout_weight="1" layout_width="match_parent" layout_height="match_parent"/>
				  <Label text="from XML!" layout_height="match_parent"/>
				</LinearLayout>
				""";

			let xmlView = UIXmlLoader.LoadFromString(xml);
			if (xmlView != null)
				right.AddView(xmlView, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "Controls");

		// CheckBox + ToggleSwitch row
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 12;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 24 });

			let cb = new CheckBox();
			cb.SetText("Check me");
			row.AddView(cb);

			let sw = new ToggleSwitch();
			sw.SetText("Switch");
			row.AddView(sw);
		}

		// RadioGroup
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 12;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });

			let group = new RadioGroup();
			group.Orientation = .Horizontal;
			group.Spacing = 12;
			let r1 = new RadioButton(); r1.SetText("Option A");
			let r2 = new RadioButton(); r2.SetText("Option B");
			let r3 = new RadioButton(); r3.SetText("Option C");
			group.AddRadioButton(r1);
			group.AddRadioButton(r2);
			group.AddRadioButton(r3);
			group.CheckAt(0);
			row.AddView(group, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
		}

		// ProgressBar (animates in OnUpdate)
		{
			mDemoProgressBar = new ProgressBar();
			mDemoProgressBar.Progress = 0;
			right.AddView(mDemoProgressBar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 12 });
		}

		// Slider (smooth — no step)
		{
			let slider = new Slider();
			slider.Min = 0;
			slider.Max = 100;
			slider.Value = 40;
			right.AddView(slider, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 24 });
		}

		// ToggleButton row
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });

			let tb1 = new ToggleButton(); tb1.SetText("Bold");
			let tb2 = new ToggleButton(); tb2.SetText("Italic");
			row.AddView(tb1, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
			row.AddView(tb2, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
		}

		// ComboBox
		{
			let combo = new ComboBox();
			combo.AddItem("Apple");
			combo.AddItem("Banana");
			combo.AddItem("Cherry");
			combo.AddItem("Date");
			combo.SelectedIndex = 0;
			right.AddView(combo, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
		}

		// TabView with placement toggle
		{
			let tabRow = new LinearLayout();
			tabRow.Orientation = .Vertical;
			tabRow.Spacing = 4;
			right.AddView(tabRow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 110 });

			let tabs = new TabView();
			let tab1Content = new Label(); tab1Content.SetText("Content of Tab 1");
			let tab2Content = new Label(); tab2Content.SetText("Content of Tab 2");
			let tab3Content = new Label(); tab3Content.SetText("Content of Tab 3");
			tabs.AddTab("Tab 1", tab1Content);
			tabs.AddTab("Tab 2", tab2Content);
			tabs.AddTab("Tab 3", tab3Content);
			tabRow.AddView(tabs, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 80 });

			let placeBtn = new Button();
			placeBtn.SetText("Placement: Top");
			placeBtn.OnClick.Add(new (b) =>
			{
				switch (tabs.Placement)
				{
				case .Top:    tabs.Placement = .Bottom; placeBtn.SetText("Placement: Bottom");
				case .Bottom: tabs.Placement = .Left;   placeBtn.SetText("Placement: Left");
				case .Left:   tabs.Placement = .Right;  placeBtn.SetText("Placement: Right");
				case .Right:  tabs.Placement = .Top;    placeBtn.SetText("Placement: Top");
				}
			});
			tabRow.AddView(placeBtn, new LinearLayout.LayoutParams() { Height = 26 });
		}

		// NumericField
		{
			let numRow = new LinearLayout();
			numRow.Orientation = .Horizontal;
			numRow.Spacing = 8;
			right.AddView(numRow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });

			let numLabel = new Label();
			numLabel.SetText("Numeric:");
			numLabel.VAlign = .Middle;
			numRow.AddView(numLabel, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			let numField = new NumericField();
			numField.Min = 0;
			numField.Max = 100;
			numField.Value = 42;
			numField.Step = 1;
			numRow.AddView(numField, new LinearLayout.LayoutParams() { Width = 120, Height = LayoutParams.MatchParent });

			let numFieldDec = new NumericField();
			numFieldDec.Min = 0;
			numFieldDec.Max = 1;
			numFieldDec.Value = 0.5f;
			numFieldDec.Step = 0.05f;
			numFieldDec.DecimalPlaces = 2;
			numRow.AddView(numFieldDec, new LinearLayout.LayoutParams() { Width = 120, Height = LayoutParams.MatchParent });
		}

		// Expander
		{
			let expander = new Expander();
			expander.SetHeaderText("Expandable Section");
			let content = new Label();
			content.SetText("Hidden content revealed!");
			expander.SetContent(content, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 24 });
			right.AddView(expander, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });
		}

		AddSeparator(right);
		AddSectionLabel(right, "Overlays (right-click / dialog)");

		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });

			// Dialog button.
			let dialogBtn = new Button();
			dialogBtn.SetText("Show Dialog");
			dialogBtn.TooltipText = new String("Opens a modal alert dialog");
			dialogBtn.OnClick.Add(new [&](b) =>
			{
				let dialog = Dialog.Alert("Hello!", "This is a modal dialog.\nPress OK or Escape to close.");
				dialog.Show(mUI.UIContext);
			});
			row.AddView(dialogBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			// Copyable label — right-click to copy, then paste in EditText.
			let copyPanel = new CopyableLabel();
			copyPanel.SetText("Right-click to copy this text");
			row.AddView(copyPanel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "Animation");

		{
			// Target view to animate.
			let animTarget = new ColorView();
			animTarget.Color = .(80, 160, 255, 255);
			right.AddView(animTarget, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });

			let animRow = new LinearLayout();
			animRow.Orientation = .Horizontal;
			animRow.Spacing = 6;
			right.AddView(animRow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });

			// Fade Out button.
			let fadeOutBtn = new Button();
			fadeOutBtn.SetText("Fade Out");
			fadeOutBtn.OnClick.Add(new (b) =>
			{
				mUI.UIContext.Animations.Add(ViewAnimator.FadeOut(animTarget, 0.5f, Easing.EaseOutCubic));
			});
			animRow.AddView(fadeOutBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			// Fade In button.
			let fadeInBtn = new Button();
			fadeInBtn.SetText("Fade In");
			fadeInBtn.OnClick.Add(new (b) =>
			{
				mUI.UIContext.Animations.Add(ViewAnimator.FadeIn(animTarget, 0.5f, Easing.EaseOutCubic));
			});
			animRow.AddView(fadeInBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			// Bounce button.
			let bounceBtn = new Button();
			bounceBtn.SetText("Bounce");
			bounceBtn.OnClick.Add(new (b) =>
			{
				let sb = new Storyboard(.Sequential);
				sb.Add(ViewAnimator.ScaleTo(animTarget, 1.0f, 1.3f, 0.15f, Easing.EaseOutCubic));
				sb.Add(ViewAnimator.ScaleTo(animTarget, 1.3f, 1.0f, 0.3f, Easing.BounceOut));
				mUI.UIContext.Animations.Add(sb);
			});
			animRow.AddView(bounceBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			// Slide button.
			let slideBtn = new Button();
			slideBtn.SetText("Slide");
			slideBtn.OnClick.Add(new (b) =>
			{
				let sb = new Storyboard(.Sequential);
				sb.Add(ViewAnimator.TranslateX(animTarget, 0, 50, 0.3f, Easing.EaseOutCubic));
				sb.Add(ViewAnimator.TranslateX(animTarget, 50, 0, 0.3f, Easing.EaseInCubic));
				mUI.UIContext.Animations.Add(sb);
			});
			animRow.AddView(slideBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			// Transformed buttons — rotated and scaled, with working hit-testing.
			let transformRow = new LinearLayout();
			transformRow.Orientation = .Horizontal;
			transformRow.Spacing = 20;
			right.AddView(transformRow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });

			let rotBtn = new Button();
			rotBtn.SetText("Rotated");
			rotBtn.RenderTransform = Matrix.CreateRotationZ(0.15f);
			rotBtn.OnClick.Add(new (b) => { mClickLabel?.SetText("Rotated button clicked!"); });
			transformRow.AddView(rotBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			let scaleBtn = new Button();
			scaleBtn.SetText("Scaled 1.2x");
			scaleBtn.RenderTransform = Matrix.CreateScale(1.2f);
			scaleBtn.OnClick.Add(new (b) => { mClickLabel?.SetText("Scaled button clicked!"); });
			transformRow.AddView(scaleBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			let skewBtn = new Button();
			skewBtn.SetText("Skewed");
			var skew = Matrix.Identity;
			skew.M21 = 0.2f; // horizontal skew
			skewBtn.RenderTransform = skew;
			skewBtn.OnClick.Add(new (b) => { mClickLabel?.SetText("Skewed button clicked!"); });
			transformRow.AddView(skewBtn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
		}

		AddSeparator(right);
		AddSectionLabel(right, "Drag & Drop");

		// Reorderable color chips + drop target box.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });

			// Reorder container with draggable chips.
			let container = new ChipReorderContainer();
			container.Orientation = .Horizontal;
			container.Spacing = 4;
			row.AddView(container, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });

			Color[?] chipColors = .(
				.(220, 60, 60, 255), .(60, 180, 60, 255), .(60, 100, 220, 255),
				.(220, 180, 40, 255), .(180, 60, 220, 255));

			for (int i = 0; i < chipColors.Count; i++)
			{
				let chip = new DragChip();
				chip.Color = chipColors[i];
				chip.PreferredWidth = 30;
				chip.PreferredHeight = 30;
				container.AddView(chip, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
			}

			// Drop target box — changes color when a chip is dropped on it.
			let dropBox = new ColorDropBox();
			row.AddView(dropBox, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "Toolkit");

		// SplitView demo.
		{
			let split = new Sedulous.UI.Toolkit.SplitView();
			split.Orientation = .Horizontal;
			split.SplitRatio = 0.4f;

			let leftPane = new Panel();
			leftPane.Padding = .(4);
			let leftLabel = new Label();
			leftLabel.SetText("Left pane");
			leftLabel.FontSize = 12;
			leftPane.AddView(leftLabel, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

			let rightPane = new Panel();
			rightPane.Padding = .(4);
			let rightLabel = new Label();
			rightLabel.SetText("Right pane (drag divider)");
			rightLabel.FontSize = 12;
			rightPane.AddView(rightLabel, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

			split.SetPanes(leftPane, rightPane);
			right.AddView(split, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 60 });
		}

		// Toolbar demo.
		{
			let toolbar = new Sedulous.UI.Toolkit.Toolbar();
			let btn1 = toolbar.AddButton("File");
			btn1.OnClick.Add(new (b) => { mClickLabel?.SetText("File clicked"); });
			let btn2 = toolbar.AddButton("Edit");
			btn2.OnClick.Add(new (b) => { mClickLabel?.SetText("Edit clicked"); });
			toolbar.AddSeparator();
			let toggle = toolbar.AddToggle("Grid");
			toggle.OnCheckedChanged.Add(new (t, v) => {
				let msg = scope String();
				msg.AppendF("Grid: {}", v ? "ON" : "OFF");
				mClickLabel?.SetText(msg);
			});
			right.AddView(toolbar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
		}

		// MenuBar demo.
		{
			let menuBar = new Sedulous.UI.Toolkit.MenuBar();
			let fileMenu = menuBar.AddMenu("File");
			fileMenu.AddItem("New", new () => { mClickLabel?.SetText("File > New"); });
			fileMenu.AddItem("Open", new () => { mClickLabel?.SetText("File > Open"); });
			fileMenu.AddSeparator();
			fileMenu.AddItem("Exit", new () => { mClickLabel?.SetText("File > Exit"); });

			let editMenu = menuBar.AddMenu("Edit");
			editMenu.AddItem("Undo", new () => { mClickLabel?.SetText("Edit > Undo"); });
			editMenu.AddItem("Redo", new () => { mClickLabel?.SetText("Edit > Redo"); });

			let viewMenu = menuBar.AddMenu("View");
			viewMenu.AddItem("Zoom In", new () => { mClickLabel?.SetText("View > Zoom In"); });
			viewMenu.AddItem("Zoom Out", new () => { mClickLabel?.SetText("View > Zoom Out"); });

			right.AddView(menuBar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 28 });
		}

		// StatusBar demo.
		{
			let statusBar = new Sedulous.UI.Toolkit.StatusBar();
			statusBar.SetText("Ready");
			statusBar.AddSection("Ln 1, Col 1");
			statusBar.AddSection("UTF-8");
			right.AddView(statusBar, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 24 });
		}

		// PropertyGrid demo.
		{
			let grid = new Sedulous.UI.Toolkit.PropertyGrid();
			grid.AddProperty(new Sedulous.UI.Toolkit.BoolEditor("Visible", true));
			grid.AddProperty(new Sedulous.UI.Toolkit.StringEditor("Name", "Player"));
			grid.AddProperty(new Sedulous.UI.Toolkit.FloatEditor("Speed", 5.0, 0, 100, 0.5, 1, category: "Physics"));
			grid.AddProperty(new Sedulous.UI.Toolkit.IntEditor("Health", 100, 0, 999, category: "Stats"));
			grid.AddProperty(new Sedulous.UI.Toolkit.RangeEditor("Volume", 0.8f, 0, 1, category: "Audio"));
			grid.AddProperty(new Sedulous.UI.Toolkit.ColorEditor("Tint", .(200, 100, 50, 255)));
			right.AddView(grid, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 180 });
		}

		// F2=bounds  F3=padding  F4=margin  F5=theme  F6=xml-theme
	}

	// === Helpers ===

	private void AddSectionLabel(LinearLayout parent, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.StyleId = new String("SectionLabel");
		parent.AddView(label, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });
	}

	private void AddSeparator(LinearLayout parent)
	{
		let sep = new Separator();
		// No explicit color — uses theme's "Separator.Color".
		parent.AddView(sep, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 1 });
	}

	private void AddWeightedColor(LinearLayout row, Color color, float weight)
	{
		let cv = new ColorView();
		cv.Color = color;
		row.AddView(cv, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = weight });
	}

	private void AddButton(LinearLayout row, StringView text, Color bgColor, StringView tooltip = default, TooltipPlacement tooltipPlacement = .Bottom)
	{
		let btn = new Button();
		btn.SetText(text);
		if (tooltip.Length > 0)
		{
			btn.TooltipText = new String(tooltip);
			btn.TooltipPlacement = tooltipPlacement;
		}

		let bg = new StateListDrawable();
		bg.Set(.Normal, new RoundedRectDrawable(bgColor, 4));
		bg.Set(.Hover, new RoundedRectDrawable(Lighten(bgColor, 0.15f), 4));
		bg.Set(.Pressed, new RoundedRectDrawable(Darken(bgColor, 0.15f), 4));
		bg.Set(.Disabled, new RoundedRectDrawable(Desaturate(bgColor, 0.5f), 4));
		btn.Background = bg;

		// Wire click feedback.
		btn.OnClick.Add(new [&](clickedBtn) =>
		{
			if (mClickLabel != null)
			{
				let msg = scope String();
				msg.AppendF("Clicked: {}", clickedBtn.Text);
				mClickLabel.SetText(msg);
				mClickLabel.TextColor = mUI.UIContext.Theme?.Palette.Success ?? .(60, 180, 80, 255);
			}
		});

		row.AddView(btn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
	}

	private void AddAbsBox(AbsoluteLayout abs, Color color, float x, float y, float w, float h)
	{
		let cv = new ColorView();
		cv.Color = color;
		cv.PreferredWidth = w;
		cv.PreferredHeight = h;
		abs.AddView(cv, new AbsoluteLayout.LayoutParams() { X = x, Y = y });
	}

	private void AddGridCell(GridLayout grid, StringView text, int32 row, int32 col)
	{
		let label = new Label();
		label.SetText(text);
		// No explicit TextColor — uses theme's Label.Foreground.
		grid.AddView(label, new GridLayout.LayoutParams() {
			Row = row, Column = col,
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});
	}

	private static Color Lighten(Color c, float amount)
	{
		return .(
			(uint8)Math.Min(255, (int)(c.R + (255 - c.R) * amount)),
			(uint8)Math.Min(255, (int)(c.G + (255 - c.G) * amount)),
			(uint8)Math.Min(255, (int)(c.B + (255 - c.B) * amount)),
			c.A);
	}

	private static Color Darken(Color c, float amount)
	{
		return .(
			(uint8)Math.Max(0, (int)(c.R * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.G * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.B * (1 - amount))),
			c.A);
	}

	private static Color Desaturate(Color c, float amount)
	{
		let gray = (uint8)((c.R + c.G + c.B) / 3);
		return .(
			(uint8)(c.R + (gray - c.R) * amount),
			(uint8)(c.G + (gray - c.G) * amount),
			(uint8)(c.B + (gray - c.B) * amount),
			(uint8)(c.A * (1 - amount * 0.5f)));
	}

	private static Color HSLToColor(float h, float s, float l)
	{
		var h;
		h = h % 1.0f;
		if (h < 0) h += 1.0f;

		float r, g, b;
		if (s <= 0.0f) { r = g = b = l; }
		else
		{
			let q = l < 0.5f ? l * (1.0f + s) : l + s - l * s;
			let p = 2.0f * l - q;
			r = HueToRGB(p, q, h + 1.0f / 3.0f);
			g = HueToRGB(p, q, h);
			b = HueToRGB(p, q, h - 1.0f / 3.0f);
		}
		return Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), 255);
	}

	private static float HueToRGB(float p, float q, float t)
	{
		var t;
		if (t < 0) t += 1.0f;
		if (t > 1) t -= 1.0f;
		if (t < 1.0f / 6.0f) return p + (q - p) * 6.0f * t;
		if (t < 1.0f / 2.0f) return q;
		if (t < 2.0f / 3.0f) return p + (q - p) * (2.0f / 3.0f - t) * 6.0f;
		return p;
	}
	*/

	protected override void OnInput()
	{
		if (mUI == null) return;

		let mouse = Shell?.InputManager?.Mouse;
		let dragDrop = mUI.UIContext.DragDropManager;

		// During active drag, use global mouse coords and handle cross-window movement.
		if (dragDrop.IsDragging || dragDrop.IsPotentialDrag)
		{
			mUI.UIContext.ActiveInputRoot = mUI.Root;

			if (mouse != null)
			{
				let globalX = mouse.GlobalX;
				let globalY = mouse.GlobalY;

				// Move the floating OS window to follow cursor (like legacy).
				if (dragDrop.IsDragging && mDragSourceWindow == null)
				{
					// First frame of active drag — find the source floating window
					// and capture the mouse offset within it.
					for (let kv in mFloatingWindowMap)
					{
						if (kv.value.Window.Focused)
						{
							mDragSourceWindow = kv.value.Window;
							mDragWindowOffsetX = globalX - (float)mDragSourceWindow.X;
							mDragWindowOffsetY = globalY - (float)mDragSourceWindow.Y;
							break;
						}
					}
				}

				if (mDragSourceWindow != null)
				{
					mDragSourceWindow.X = (int32)(globalX - mDragWindowOffsetX);
					mDragSourceWindow.Y = (int32)(globalY - mDragWindowOffsetY);
				}

				// Convert global to main-window-relative for input routing.
				let mx = globalX - (float)mWindow.X;
				let my = globalY - (float)mWindow.Y;

				mUI.UIContext.InputManager.ProcessMouseMove(mx, my);

				// Edge-detect mouse button for drag end.
				let leftDown = mouse.IsButtonDown(.Left);
				if (!leftDown && mDragPrevLeftDown)
					mUI.UIContext.InputManager.ProcessMouseUp(.Left, mx, my);
				mDragPrevLeftDown = leftDown;

				mUI.SkipInputThisFrame = true;
			}
			return;
		}

		// Not dragging — clear drag source tracking.
		if (mDragSourceWindow != null)
			mDragSourceWindow = null;

		// Route input to whichever window has focus.
		for (let kv in mFloatingWindowMap)
		{
			if (kv.value.Window.Focused)
			{
				if (let data = kv.value.UserData as FloatingWindowRenderData)
				{
					mUI.UIContext.ActiveInputRoot = data.RootView;
					return;
				}
			}
		}

		// Default: main window.
		mUI.UIContext.ActiveInputRoot = mUI.Root;
	}

	protected override void OnUpdate(FrameContext frame)
	{
		if (mUI == null) return;

		// Animate progress bar in controls page.
		mControlsPage?.Update(frame.DeltaTime);

		let kb = Shell?.InputManager?.Keyboard;
		if (kb == null) return;

		// F2 toggles debug bounds overlay.
		if (kb.IsKeyPressed(.F2))
			mUI.UIContext.DebugSettings.ShowBounds = !mUI.UIContext.DebugSettings.ShowBounds;

		// F3 toggles padding overlay.
		if (kb.IsKeyPressed(.F3))
			mUI.UIContext.DebugSettings.ShowPadding = !mUI.UIContext.DebugSettings.ShowPadding;

		// F4 toggles margin overlay.
		if (kb.IsKeyPressed(.F4))
			mUI.UIContext.DebugSettings.ShowMargin = !mUI.UIContext.DebugSettings.ShowMargin;

		// F5 toggles between Dark and Light themes.
		if (kb.IsKeyPressed(.F5))
		{
			let ctx = mUI.UIContext;
			let isDark = ctx.Theme?.Name.Contains("Dark") ?? true;
			ctx.Theme = isDark ? LightTheme.Create() : DarkTheme.Create();
		}

		// F6 loads a custom theme from XML (demonstrates ThemeXmlParser).
		if (kb.IsKeyPressed(.F6))
		{
			let themeXml = """
				<Theme name="XmlCustom">
				  <Palette primary="180,60,120" background="25,20,30" surface="40,32,48"
				           border="70,55,85" text="230,220,240" textDim="150,130,170"/>
				  <Color key="Button.Background" value="180,60,120"/>
				  <Color key="Button.Background.Hover" value="210,90,150"/>
				  <Color key="Button.Background.Pressed" value="140,40,90"/>
				  <Color key="Button.Foreground" value="255,240,250"/>
				  <Color key="Label.Foreground" value="230,220,240"/>
				  <Color key="Panel.Background" value="40,32,48"/>
				  <Color key="Panel.Border" value="70,55,85"/>
				  <Color key="Separator.Color" value="70,55,85"/>
				  <Color key="SectionLabel.Foreground" value="255,180,220"/>
				  <Color key="Focus.Ring" value="200,100,160,200"/>
				  <Color key="ScrollBar.Track" value="50,40,60,150"/>
				  <Color key="ScrollBar.Thumb" value="160,100,140,220"/>
				  <Color key="CheckBox.BoxBackground" value="35,25,42"/>
				  <Color key="CheckBox.CheckColor" value="200,80,150"/>
				  <Color key="RadioButton.DotColor" value="200,80,150"/>
				  <Color key="ToggleSwitch.TrackOff" value="40,32,48"/>
				  <Color key="ToggleSwitch.TrackOn" value="200,80,150"/>
				  <Color key="ProgressBar.Fill" value="200,80,150"/>
				  <Color key="Slider.Fill" value="200,80,150"/>
				  <Color key="ToggleButton.CheckedBackground" value="200,80,150"/>
				  <Color key="TabView.StripBackground" value="30,22,38"/>
				  <Color key="TabView.ContentBackground" value="40,32,48"/>
				  <Color key="TabView.ActiveTabBackground" value="40,32,48"/>
				  <Color key="TabView.ActiveTabText" value="230,220,240"/>
				  <Color key="TabView.InactiveTabText" value="150,130,170"/>
				  <Color key="TabView.HoverTabText" value="210,190,230"/>
				  <Color key="TabView.TabHover" value="180,60,120,40"/>
				  <Color key="ToggleButton.Background" value="55,45,65"/>
				  <Color key="ToggleButton.CheckedBackground" value="200,80,150"/>
				  <Color key="ComboBox.Background" value="40,32,48"/>
				  <Color key="ComboBox.Border" value="70,55,85"/>
				  <Color key="ComboBox.Text" value="230,220,240"/>
				  <Color key="ComboBox.ArrowColor" value="180,140,200"/>
				  <Color key="ContextMenu.Background" value="45,35,55,240"/>
				  <Color key="ContextMenu.Border" value="70,55,85"/>
				  <Color key="ContextMenu.Hover" value="180,60,120,80"/>
				  <Color key="ContextMenu.Text" value="230,220,240"/>
				  <Color key="Dialog.Background" value="45,35,55,245"/>
				  <Color key="Dialog.Border" value="90,65,110"/>
				  <Color key="Tooltip.Background" value="40,30,50,230"/>
				  <Color key="Tooltip.Border" value="80,60,100"/>
				  <Color key="EditText.Background" value="35,25,42"/>
				  <Color key="EditText.Border" value="70,55,85"/>
				  <Color key="EditText.Border.Focused" value="200,80,150"/>
				  <Color key="EditText.Foreground" value="230,220,240"/>
				  <Color key="EditText.Placeholder" value="120,100,140"/>
				  <Color key="EditText.Selection" value="180,60,120,80"/>
				  <Color key="EditText.Cursor" value="230,220,240"/>
				  <Dimension key="Button.CornerRadius" value="6"/>
				  <Dimension key="Panel.CornerRadius" value="8"/>
				  <Dimension key="Panel.BorderWidth" value="1"/>
				  <Padding key="Button.Padding" value="12,8"/>
				</Theme>
				""";

			let ctx = mUI.UIContext;
			let newTheme = ThemeXmlParser.Parse(themeXml);
			if (newTheme != null)
				ctx.Theme = newTheme;
		}
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return false;

		// Use theme background for clear color.
		let bg = mUI.UIContext.Theme?.Palette.Background ?? Color(30, 30, 35, 255);
		ColorAttachment[1] clearAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(bg.R / 255.0f, bg.G / 255.0f, bg.B / 255.0f, 1.0f)
		});
		RenderPassDesc clearPass = .() { ColorAttachments = .(clearAttachments) };
		let rp = render.Encoder.BeginRenderPass(clearPass);
		if (rp != null) rp.End();

		mUI.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height,
			render.Frame.FrameIndex);

		return true;
	}

	protected override void OnShutdown()
	{
		// Destroy all floating windows before UI shutdown.
		let floatingViews = scope System.Collections.List<View>();
		for (let kv in mFloatingWindowMap)
			floatingViews.Add(kv.key);
		for (let view in floatingViews)
			DestroyFloatingWindowImpl(view, detachView: false);
		mFloatingWindowMap.Clear();
	}

	// === IFloatingWindowHost ===

	public bool SupportsOSWindows => true;

	public void CreateFloatingWindow(View floatingWindow, float width, float height,
		float screenX, float screenY, delegate void(View) onCloseRequested)
	{
		let settings = Sedulous.Shell.WindowSettings()
		{
			Title = scope .("Float"),
			Width = (int32)width,
			Height = (int32)height,
			Resizable = true,
			Bordered = false // chromeless
		};

		if (CreateSecondaryWindow(settings) case .Err)
		{
			Console.WriteLine("Failed to create floating OS window");
			delete onCloseRequested;
			return;
		}

		let ctx = mSecondaryWindows[mSecondaryWindows.Count - 1];

		// Position the window (screenX/Y are main-window-relative → convert to global).
		ctx.Window.X = mWindow.X + (int32)screenX;
		ctx.Window.Y = mWindow.Y + (int32)screenY;

		// Create per-window rendering resources.
		let data = new FloatingWindowRenderData();

		// Store the close delegate so it's properly owned and deleted.
		data.OnCloseDelegate = onCloseRequested;
		if (onCloseRequested != null)
			ctx.OnCloseRequested = new (swCtx) => { data.OnCloseDelegate(floatingWindow); };
		else
			ctx.OnCloseRequested = new (swCtx) => { };

		data.RootView = new RootView();
		data.RootView.DpiScale = ctx.Window.ContentScale;
		data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
		mUI.UIContext.AddRootView(data.RootView);
		data.RootView.AddView(floatingWindow);
		data.FloatingView = floatingWindow;

		data.VGContext = new Sedulous.VG.VGContext(mUI.FontService);

		data.VGRenderer = new Sedulous.VG.Renderer.VGRenderer();
		if (data.VGRenderer.Initialize(Device, ctx.SwapChain.Format,
			(int32)ctx.SwapChain.BufferCount, mUI.ShaderSystem) case .Err)
		{
			Console.WriteLine("Failed to initialize VGRenderer for floating window");
		}

		ctx.UserData = data;
		mFloatingWindowMap[floatingWindow] = ctx;
	}

	public void DestroyFloatingWindow(View floatingWindow)
	{
		DestroyFloatingWindowImpl(floatingWindow);
	}

	public void MoveFloatingWindow(View floatingWindow, float screenX, float screenY)
	{
		if (mFloatingWindowMap.TryGetValue(floatingWindow, let ctx))
		{
			// screenX/screenY are main-window-relative (from DragDropManager.LastScreenX/Y).
			// Convert to global screen coordinates for OS window positioning.
			ctx.Window.X = mWindow.X + (int32)screenX;
			ctx.Window.Y = mWindow.Y + (int32)screenY;
		}
	}

	/// Destroy a floating window's secondary window and GPU resources.
	/// During normal operation (IFloatingWindowHost.DestroyFloatingWindow), the floating
	/// view is detached from its RootView so DockManager can queue-delete it separately.
	/// During shutdown, cascade-delete via RootView cleans up everything.
	private void DestroyFloatingWindowImpl(View floatingWindow, bool detachView = true)
	{
		if (!mFloatingWindowMap.TryGetValue(floatingWindow, let ctx))
			return;

		mFloatingWindowMap.Remove(floatingWindow);

		if (let data = ctx.UserData as FloatingWindowRenderData)
		{
			// Detach floating window from RootView so it survives for
			// DockManager's QueueDeleteNode. During shutdown, skip detach
			// to let RootView's destructor cascade-delete everything.
			if (detachView && floatingWindow.Parent == data.RootView)
				data.RootView.DetachView(floatingWindow);

			mUI.UIContext.RemoveRootView(data.RootView);
			mDevice.WaitIdle(); // Ensure GPU is done before freeing VGRenderer resources.
			delete data;
		}

		ctx.UserData = null;
		DestroySecondaryWindow(ctx);
	}

	// === Secondary window rendering ===

	protected override void OnPrepareSecondaryFrame(SecondaryWindowContext ctx, FrameContext frame)
	{
		if (let data = ctx.UserData as FloatingWindowRenderData)
		{
			data.RootView.DpiScale = ctx.Window.ContentScale;
			data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
			mUI.UIContext.UpdateRootView(data.RootView);
		}
	}

	protected override void OnRenderSecondaryWindow(SecondaryWindowContext ctx,
		IRenderPassEncoder renderPass, FrameContext frame)
	{
		if (let data = ctx.UserData as FloatingWindowRenderData)
		{
			let vg = data.VGContext;
			let renderer = data.VGRenderer;
			let w = ctx.SwapChain.Width;
			let h = ctx.SwapChain.Height;

			vg.Clear();
			mUI.UIContext.DrawRootView(data.RootView, vg);
			let batch = vg.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			renderer.UpdateProjection(w, h, frame.FrameIndex);
			renderer.Prepare(batch, frame.FrameIndex);
			renderer.Render(renderPass, w, h, frame.FrameIndex);
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope UISandboxApp();
		return app.Run(.()
		{
			Title = "UI Sandbox",
			Width = 900, Height = 620,
			EnableDepth = false
		});
	}
}
