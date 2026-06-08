namespace UISandbox;

using System;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shell.Input;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.IO;
using Sedulous.Images;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using System.Collections;
using Sedulous.UI.Toolkit;

/// Render data for each dockable OS window (secondary window).
class DockableWindowRenderData
{
	public RootView RootView ~ delete _;
	public Sedulous.VG.VGContext VGContext ~ delete _;
	public Sedulous.VG.Renderer.VGRenderer VGRenderer ~ { _.Dispose(); delete _; };
	public View DockableView; // non-owning ref
	public delegate void(View) OnCloseDelegate ~ delete _;
}

/// Minimal UI sandbox application. Extends Application directly (no engine).
/// App owns UIContext and RootView. Subsystem owns rendering pipeline.
class UISandboxApp : Application, IDockableWindowHost
{
	// Subsystem (registered with Context, cleaned up by Context)
	private UISubsystem mUI;

	// App-owned UI state (cleaned up in OnShutdown)
	private UIContext mUIContext;
	private RootView mRoot;
	private int32 mThemeIndex = 0; // 0=Dark, 1=Light, 2=RoundedDark, 3=Textured
	private OwnedImageData mTestImage ~ delete _;
	private RepeatButton mRepeatBtn;
	private DemoListAdapter mDemoListAdapter ~ delete _;
	private DemoTreeAdapter mDemoTreeAdapter ~ delete _;
	private DemoGridAdapter mDemoGridAdapter ~ delete _;
	private ReorderableListAdapter mReorderAdapter ~ delete _;

	// Dockable window OS multi-window support.
	private System.Collections.Dictionary<View, SecondaryWindowContext> mDockableWindowMap = new .() ~ delete _;

	// .sss theme loading infrastructure
	private FileSystemMount mGuiMount ~ delete _;
	private VfsResourceProvider mGuiResourceProvider ~ delete _;

	private Label mThemeLabel;

	private Sedulous.Shell.IWindow mDragSourceWindow; // OS window being dragged cross-window
	private float mDragWindowOffsetX;
	private float mDragWindowOffsetY;
	private int32 mRepeatCount;

	protected override void OnInitialize(Context context)
	{
		// Create app-owned UI state
		mUIContext = new UIContext();
		mRoot = new RootView();

		// Register toolkit theme extension before creating themes.
		ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());

		// Initialize .sss and .sml loading infrastructure
		StyleSheetLoader.InitializeGlobals();
		MarkupLoader.Initialize();
		let guiPath = scope String();
		GetAssetPath("gui", guiPath);
		mGuiMount = new FileSystemMount(guiPath);
		mGuiResourceProvider = new VfsResourceProvider(mGuiMount);

		// Set default theme
		ApplyTheme();

		// Create and register subsystem
		mUI = new UISubsystem();
		mUI.ManualInputRouting = true; // App handles multi-window input routing
		context.RegisterSubsystem<UISubsystem>(mUI);

		// Initialize rendering - pass app-owned context and root
		let shaderPath = scope String();
		GetAssetPath("shaders", shaderPath);

		// Pass BuiltinMount so the UI subsystem's font service routes
		// font loads through the `builtin://` VFS scheme.
		if (mUI.InitializeRendering(
			mUIContext, mRoot,
			Device, SwapChain.Format, (int32)SwapChain.BufferCount,
			scope StringView[](shaderPath), Shell, Window, BuiltinMount) case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize UI2 rendering");
			return;
		}

		// Load fonts. Locator is relative to BuiltinMount.
		let fontLocator = "fonts/roboto/Roboto-Regular.ttf";
		mUI.LoadFont("Roboto", fontLocator, .()
			{
				PixelHeight = 16, FirstCodepoint = 32,
				LastCodepoint = 255,
				AtlasWidth = 1024,
				AtlasHeight = 1024,
				OversampleX = 2,
				OversampleY = 2,
				Padding = 2
			});
		mUI.LoadFont("Roboto", fontLocator, .()
			{
				PixelHeight = 24, FirstCodepoint = 32,
				LastCodepoint = 255,
				AtlasWidth = 1024,
				AtlasHeight = 1024,
				OversampleX = 2,
				OversampleY = 2,
				Padding = 2
			});

		// Generate a test image for ImageView demo
		mTestImage = GenerateCheckerboard(64, 64, 8, .(100, 140, 200, 255), .(40, 50, 70, 255));

		// Build initial UI
		BuildUI();

		Console.WriteLine("=== UI2 Sandbox Ready ===");
	}

	private void BuildUI()
	{
		// Main vertical layout filling the window
		let main = new FlexLayout() { Direction = .Vertical };
		mRoot.AddView(main);

		// TabView as the main navigation
		let tabView = new TabView();
		tabView.TabsClosable.Value = false;
		tabView.OnTabCloseRequested.Add(new (tv, idx) => { tv.RemoveTab(idx); });
		main.AddView(tabView, new FlexLayout.LayoutParams() { Grow = 1 });

		// === Tab 1: Controls ===
		let body = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		tabView.AddTab("Controls", body);

		// Left panel - Controls demo
		let leftPanel = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		leftPanel.Padding = .(12, 8);
		body.AddView(leftPanel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		// Buttons
		let btnRow = new FlexLayout() { Direction = .Horizontal, Spacing = 6 };
		btnRow.AddView(new Button("Click Me"));
		btnRow.AddView(new Button("Disabled") { IsEnabled = false });
		btnRow.AddView(new ToggleButton("Toggle"));
		leftPanel.AddView(btnRow);

		// ContentButton (custom content: icon + text)
		let contentBtnRow = new FlexLayout() { Direction = .Horizontal, Spacing = 6 };
		let iconTextLayout = new FlexLayout() { Direction = .Horizontal, Spacing = 6, AlignItems = .Center };
		iconTextLayout.AddView(new ColorView(.(80, 180, 80, 255), 12, 12));
		iconTextLayout.AddView(new Label("Icon + Text"));
		contentBtnRow.AddView(new ContentButton(iconTextLayout));
		let multiLineContent = new FlexLayout() { Direction = .Vertical, Spacing = 2, AlignItems = .Center };
		let lblLine1 = new Label("Line 1"); lblLine1.FontSize.Value = 12;
		multiLineContent.AddView(lblLine1);
		let lblLine2 = new Label("Line 2"); lblLine2.FontSize.Value = 10;
		multiLineContent.AddView(lblLine2);
		contentBtnRow.AddView(new ContentButton(multiLineContent));
		leftPanel.AddView(contentBtnRow);

		// RepeatButton
		let repeatRow = new FlexLayout() { Direction = .Horizontal, Spacing = 6 };
		let repeatLabel = new Label("Count: 0");
		let repeatBtn = new RepeatButton("Hold Me");
		mRepeatBtn = repeatBtn;
		repeatBtn.OnClick.Add(new (btn) =>
			{
				mRepeatCount++;
				repeatLabel.SetText(scope String()..AppendF("Count: {}", mRepeatCount));
			});
		repeatRow.AddView(repeatBtn);
		repeatRow.AddView(repeatLabel);
		leftPanel.AddView(repeatRow);

		// Spacer
		leftPanel.AddView(new Spacer(0, 4));

		// Toggle controls
		leftPanel.AddView(new CheckBox("Enable sounds", true));
		leftPanel.AddView(new CheckBox("Fullscreen"));
		leftPanel.AddView(new ToggleSwitch("VSync"));

		// Separator
		leftPanel.AddView(new Separator());

		// Radio group
		let radioGroup = new RadioGroup();
		radioGroup.AddRadioButton(new RadioButton("Low"));
		radioGroup.AddRadioButton(new RadioButton("Medium"));
		radioGroup.AddRadioButton(new RadioButton("High"));
		radioGroup.CheckAt(1);
		leftPanel.AddView(radioGroup);

		// Separator
		leftPanel.AddView(new Separator());

		// Slider
		leftPanel.AddView(new Label("Volume"));
		leftPanel.AddView(new Slider(0, 100, 75));

		// Progress bar
		leftPanel.AddView(new Label("Loading..."));
		let progressBar = new ProgressBar();
		progressBar.Value.Value = 0.65f;
		leftPanel.AddView(progressBar);

		// Center panel - Panel with Expanders
		let centerPanel = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		centerPanel.Padding = .(8);
		body.AddView(centerPanel, new FlexLayout.LayoutParams() { Grow = 1 });

		// Themed panel containing expanders
		let settingsPanel = new Panel();
		settingsPanel.Padding = .(8);
		settingsPanel.AddClass("panel");
		let settingsLayout = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		settingsPanel.AddView(settingsLayout);
		centerPanel.AddView(settingsPanel);

		let expander1 = new Expander("Graphics Settings");
		let expanderContent1 = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		expanderContent1.AddView(new CheckBox("Anti-Aliasing"));
		expanderContent1.AddView(new CheckBox("Shadows", true));
		expanderContent1.AddView(new CheckBox("Bloom", true));
		expander1.SetContent(expanderContent1);
		settingsLayout.AddView(expander1);

		let expander2 = new Expander("Audio Settings");
		let expanderContent2 = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		expanderContent2.AddView(new Label("Master Volume"));
		expanderContent2.AddView(new Slider(0, 100, 80));
		expanderContent2.AddView(new Label("Music Volume"));
		expanderContent2.AddView(new Slider(0, 100, 50));
		expander2.SetContent(expanderContent2);
		settingsLayout.AddView(expander2);

		// Right panel - ImageView modes + Color swatches
		let rightPanel = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		rightPanel.Padding = .(4);
		body.AddView(rightPanel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		// ImageView demos - all ScaleType modes
		let lblNone = new Label("None"); lblNone.VAlign.Value = .Top;
		rightPanel.AddView(lblNone);
		let imgNone = new ImageView(mTestImage);
		imgNone.ScaleType.Value = .None;
		imgNone.ClipsContent = true;
		rightPanel.AddView(imgNone, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });

		let lblFitCenter = new Label("FitCenter"); lblFitCenter.VAlign.Value = .Top;
		rightPanel.AddView(lblFitCenter);
		let imgFit = new ImageView(mTestImage);
		imgFit.ScaleType.Value = .FitCenter;
		rightPanel.AddView(imgFit, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });

		let lblFillBounds = new Label("FillBounds"); lblFillBounds.VAlign.Value = .Top;
		rightPanel.AddView(lblFillBounds);
		let imgFill = new ImageView(mTestImage);
		imgFill.ScaleType.Value = .FillBounds;
		rightPanel.AddView(imgFill, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });

		let lblCenterCrop = new Label("CenterCrop"); lblCenterCrop.VAlign.Value = .Top;
		rightPanel.AddView(lblCenterCrop);
		let imgCrop = new ImageView(mTestImage);
		imgCrop.ScaleType.Value = .CenterCrop;
		rightPanel.AddView(imgCrop, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });

		// Tinted image
		let lblTinted = new Label("Tinted"); lblTinted.VAlign.Value = .Top;
		rightPanel.AddView(lblTinted);
		let imgTint = new ImageView(mTestImage);
		imgTint.ScaleType.Value = .FitCenter;
		imgTint.Tint.Value = .(255, 100, 100, 255);
		rightPanel.AddView(imgTint, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });

		rightPanel.AddView(new Separator());

		// Color swatches
		let lblColorView = new Label("ColorView"); lblColorView.VAlign.Value = .Top;
		rightPanel.AddView(lblColorView);
		let swatchFlow = new FlowLayout() { Orientation = .Horizontal, HSpacing = 4, VSpacing = 4 };
		rightPanel.AddView(swatchFlow);

		Color[?] swatchColors = .(
			.(220, 60, 60, 255), .(60, 180, 60, 255), .(60, 60, 220, 255),
			.(220, 180, 40, 255), .(180, 60, 180, 255), .(60, 180, 180, 255),
			.(220, 120, 60, 255), .(120, 60, 220, 255)
			);
		for (int i = 0; i < swatchColors.Count; i++)
		{
			let swatch = new ColorView(swatchColors[i], 40, 40);
			swatchFlow.AddView(swatch);
		}

		rightPanel.AddView(new Separator());

		// DrawableView + SVGDrawable demos
		let lblDrawSvg = new Label("DrawableView + SVG"); lblDrawSvg.VAlign.Value = .Top;
		rightPanel.AddView(lblDrawSvg);

		let svgRow = new FlowLayout() { Orientation = .Horizontal, HSpacing = 6, VSpacing = 6 };
		rightPanel.AddView(svgRow);

		// Badge with text
		if (let badge = SVGDrawable.FromString("""
			<svg viewBox="0 0 48 48">
			  <circle cx="24" cy="24" r="22" fill="#2A6BC0" stroke="#1A4A90" stroke-width="2"/>
			  <text x="24" y="30" text-anchor="middle" font-size="18" font-weight="bold" fill="#FFFFFF">UI</text>
			</svg>
			"""))
			svgRow.AddView(new DrawableView(badge, 40, 40, ownsDrawable: true));

		// Star
		if (let star = SVGDrawable.FromString("""
			<svg viewBox="0 0 24 24">
			  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" fill="#FFD700" stroke="#B8960F" stroke-width="0.8"/>
			</svg>
			"""))
			svgRow.AddView(new DrawableView(star, 32, 32, ownsDrawable: true));

		// Heart
		if (let heart = SVGDrawable.FromString("""
			<svg viewBox="0 0 24 24">
			  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="#FF4444"/>
			</svg>
			"""))
			svgRow.AddView(new DrawableView(heart, 32, 32, ownsDrawable: true));

		// Tinted heart (blue)
		if (let tintedHeart = SVGDrawable.FromString("""
			<svg viewBox="0 0 24 24">
			  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="#FF4444"/>
			</svg>
			""", .(100, 200, 255, 255)))
			svgRow.AddView(new DrawableView(tintedHeart, 32, 32, ownsDrawable: true));

		// === Tab 2: ScrollView demo ===
		let scrollDemo = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };
		scrollDemo.Padding = .(12, 8);
		tabView.AddTab("ScrollView", scrollDemo);

		// Overlay mode (default)
		let overlayCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		let lblOverlay = new Label("Overlay Mode"); lblOverlay.VAlign.Value = .Top;
		overlayCol.AddView(lblOverlay);
		let scrollOverlay = new ScrollView();
		scrollOverlay.ScrollBarMode.Value = .Overlay;
		let overlayContent = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		for (int i = 0; i < 30; i++)
			overlayContent.AddView(new Label(scope String()..AppendF("Overlay item {}", i + 1)));
		scrollOverlay.AddView(overlayContent);
		overlayCol.AddView(scrollOverlay, new FlexLayout.LayoutParams() { Grow = 1 });
		scrollDemo.AddView(overlayCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// Reserved mode
		let reservedCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		let lblReserved = new Label("Reserved Mode"); lblReserved.VAlign.Value = .Top;
		reservedCol.AddView(lblReserved);
		let scrollReserved = new ScrollView();
		scrollReserved.ScrollBarMode.Value = .Reserved;
		let reservedContent = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		for (int i = 0; i < 30; i++)
			reservedContent.AddView(new Label(scope String()..AppendF("Reserved item {}", i + 1)));
		scrollReserved.AddView(reservedContent);
		reservedCol.AddView(scrollReserved, new FlexLayout.LayoutParams() { Grow = 1 });
		scrollDemo.AddView(reservedCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// Horizontal scroll
		let hScrollCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		let lblHoriz = new Label("Horizontal"); lblHoriz.VAlign.Value = .Top;
		hScrollCol.AddView(lblHoriz);
		let scrollH = new ScrollView();
		scrollH.VScrollBarPolicy.Value = .Always;
		scrollH.HScrollBarPolicy.Value = .Always;
		scrollH.ScrollBarMode.Value = .Reserved;
		let hContent = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		for (int i = 0; i < 20; i++)
		{
			let @box = new ColorView(Color((uint8)(60 + i * 9), (uint8)(100 + i * 5), (uint8)(180 - i * 6), 255), 60, 60);
			hContent.AddView(@box);
		}
		scrollH.AddView(hContent);
		hScrollCol.AddView(scrollH, new FlexLayout.LayoutParams() { Grow = 1 });
		scrollDemo.AddView(hScrollCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// === Tab 3: Layouts demo (closable) ===
		let layoutDemo = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		layoutDemo.Padding = .(8);
		tabView.AddTab("Layouts", layoutDemo, true);

		let gridDemo = new GridLayout();
		gridDemo.Columns.Add(.Flex(1));
		gridDemo.Columns.Add(.Flex(1));
		gridDemo.Columns.Add(.Flex(1));
		gridDemo.Rows.Add(.Flex(1));
		gridDemo.Rows.Add(.Flex(1));
		gridDemo.ColumnSpacing = 4;
		gridDemo.RowSpacing = 4;

		Color[?] gridColors = .(
			.(80, 60, 60, 255), .(60, 80, 60, 255), .(60, 60, 80, 255),
			.(70, 50, 50, 255), .(50, 70, 50, 255), .(50, 50, 70, 255)
			);
		for (int i = 0; i < 6; i++)
		{
			let cell = new ColorView(gridColors[i], 0, 0);
			gridDemo.AddView(cell, new GridLayout.LayoutParams() { Row = (int32)(i / 3), Column = (int32)(i % 3) });
		}
		layoutDemo.AddView(gridDemo, new FlexLayout.LayoutParams() { Grow = 1 });

		// === Tab 4: Tab Placement demo (closable) ===
		let tabPlacementDemo = new GridLayout();
		tabPlacementDemo.Columns.Add(.Flex(1));
		tabPlacementDemo.Columns.Add(.Flex(1));
		tabPlacementDemo.Rows.Add(.Flex(1));
		tabPlacementDemo.Rows.Add(.Flex(1));
		tabPlacementDemo.ColumnSpacing = 4;
		tabPlacementDemo.RowSpacing = 4;
		tabView.AddTab("Tab Placement", tabPlacementDemo, true);

		// Top placement
		let topTabs = new TabView();
		topTabs.Placement.Value = .Top;
		topTabs.AddTab("Top A", new Label("Top placement A"));
		topTabs.AddTab("Top B", new Label("Top placement B"));
		tabPlacementDemo.AddView(topTabs, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

		// Bottom placement
		let bottomTabs = new TabView();
		bottomTabs.Placement.Value = .Bottom;
		bottomTabs.AddTab("Bot A", new Label("Bottom placement A"));
		bottomTabs.AddTab("Bot B", new Label("Bottom placement B"));
		tabPlacementDemo.AddView(bottomTabs, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

		// Left placement
		let leftTabs = new TabView();
		leftTabs.Placement.Value = .Left;
		leftTabs.AddTab("Left A", new Label("Left placement A"));
		leftTabs.AddTab("Left B", new Label("Left placement B"));
		tabPlacementDemo.AddView(leftTabs, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

		// Right placement
		let rightTabs = new TabView();
		rightTabs.Placement.Value = .Right;
		rightTabs.AddTab("Right A", new Label("Right placement A"));
		rightTabs.AddTab("Right B", new Label("Right placement B"));
		tabPlacementDemo.AddView(rightTabs, new GridLayout.LayoutParams() { Row = 1, Column = 1 });

		// === Tab 5: Text Input demo ===
		let textInputScroll = new ScrollView();
		textInputScroll.VScrollBarPolicy.Value = .Auto;
		tabView.AddTab("Text Input", textInputScroll);

		let textInputDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		textInputDemo.Padding = .(12, 8);
		textInputScroll.AddView(textInputDemo);

		// --- EditText section ---
		textInputDemo.AddView(new Label("EditText"));
		textInputDemo.AddView(new Separator());

		let editBasic = new EditText();
		editBasic.SetText("Editable text");
		textInputDemo.AddView(editBasic, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editPlaceholder = new EditText();
		editPlaceholder.SetPlaceholder("Enter name...");
		textInputDemo.AddView(editPlaceholder, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editReadOnly = new EditText();
		editReadOnly.SetText("Read-only text");
		editReadOnly.IsReadOnly.Value = true;
		textInputDemo.AddView(editReadOnly, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editMultiline = new EditText();
		editMultiline.Multiline.Value = true;
		editMultiline.SetText("Line 1\nLine 2\nLine 3");
		textInputDemo.AddView(editMultiline, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)), Height = .Fixed(.Px(80)) });

		let editMaxLen = new EditText();
		editMaxLen.MaxLength.Value = 10;
		editMaxLen.SetPlaceholder("Max 10 chars");
		textInputDemo.AddView(editMaxLen, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editDigits = new EditText();
		editDigits.Filter = InputFilter.Digits();
		editDigits.SetPlaceholder("Digits only");
		textInputDemo.AddView(editDigits, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editPrefix = new EditText();
		editPrefix.SetPrefix("$");
		editPrefix.SetText("100");
		textInputDemo.AddView(editPrefix, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let editSuffix = new EditText();
		editSuffix.SetSuffix("px");
		editSuffix.SetText("16");
		textInputDemo.AddView(editSuffix, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		// --- PasswordBox section ---
		textInputDemo.AddView(new Spacer(0, 4));
		textInputDemo.AddView(new Label("PasswordBox"));
		textInputDemo.AddView(new Separator());

		let pw1 = new PasswordBox();
		pw1.SetPlaceholder("Password");
		textInputDemo.AddView(pw1, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let pw2 = new PasswordBox();
		pw2.PasswordChar.Value = '\u{25CF}'; // ● bullet
		pw2.SetPlaceholder("Custom mask");
		textInputDemo.AddView(pw2, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		// --- NumericField section ---
		textInputDemo.AddView(new Spacer(0, 4));
		textInputDemo.AddView(new Label("NumericField"));
		textInputDemo.AddView(new Separator());

		let nfDefault = new NumericField();
		nfDefault.Min = 0;
		nfDefault.Max = 100;
		nfDefault.Value = 42;
		textInputDemo.AddView(nfDefault, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		let nfNoSpin = new NumericField();
		nfNoSpin.Min = 0;
		nfNoSpin.Max = 100;
		nfNoSpin.ShowSpinButtons.Value = false;
		nfNoSpin.Value = 25;
		textInputDemo.AddView(nfNoSpin, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		let nfConstrained = new NumericField();
		nfConstrained.Min = -10;
		nfConstrained.Max = 10;
		nfConstrained.Step = 0.5;
		nfConstrained.DecimalPlaces = 1;
		nfConstrained.Value = 0;
		textInputDemo.AddView(nfConstrained, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		let nfInteger = new NumericField();
		nfInteger.Min = 0;
		nfInteger.Max = 999;
		nfInteger.DecimalPlaces = 0;
		nfInteger.Value = 100;
		textInputDemo.AddView(nfInteger, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		let nfSuffix = new NumericField();
		nfSuffix.Min = 0;
		nfSuffix.Max = 360;
		nfSuffix.DecimalPlaces = 1;
		nfSuffix.SetSuffix("\u{00B0}"); // degree sign
		nfSuffix.Value = 90;
		textInputDemo.AddView(nfSuffix, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		// Vector3-style editor: 3 numeric fields with colored prefix labels
		textInputDemo.AddView(new Label("Vector3 Editor"));
		let vecRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };

		void AddAxisField(FlexLayout row, StringView axis, Color axisColor, double val)
		{
			let nf = new NumericField();
			nf.Min = -999;
			nf.Max = 999;
			nf.Step = 0.1;
			nf.DecimalPlaces = 2;
			nf.ShowSpinButtons.Value = false;
			nf.Value = val;
			let prefixView = new ColoredLabel(axis, axisColor);
			nf.SetPrefix(prefixView);
			row.AddView(nf, new FlexLayout.LayoutParams() { Grow = 1 });
		}

		AddAxisField(vecRow, "X", .(220, 80, 80, 255), 1.06);
		AddAxisField(vecRow, "Y", .(80, 200, 80, 255), 0.0);
		AddAxisField(vecRow, "Z", .(80, 120, 220, 255), 2.17);
		textInputDemo.AddView(vecRow, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(400)) });

		// --- EditableLabel section ---
		textInputDemo.AddView(new Spacer(0, 4));
		textInputDemo.AddView(new Label("EditableLabel (double-click to edit)"));
		textInputDemo.AddView(new Separator());

		let el1 = new EditableLabel();
		el1.SetText("Double-click me");
		el1.SlowClickToEdit.Value = false;
		textInputDemo.AddView(el1, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let el2 = new EditableLabel();
		el2.SetText("Slow-click me");
		el2.DoubleClickToEdit.Value = false;
		textInputDemo.AddView(el2, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		let el3 = new EditableLabel();
		el3.SetText("With validation");
		el3.ValidateRename = new (text) => !text.Contains("bad");
		textInputDemo.AddView(el3, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(300)) });

		// === Tab 6: Overlays demo ===
		let overlaysScroll = new ScrollView();
		overlaysScroll.VScrollBarPolicy.Value = .Auto;
		tabView.AddTab("Overlays", overlaysScroll);

		let overlaysDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		overlaysDemo.Padding = .(12, 8);
		overlaysScroll.AddView(overlaysDemo);

		// --- ComboBox section ---
		overlaysDemo.AddView(new Label("ComboBox"));
		overlaysDemo.AddView(new Separator());

		let comboBasic = new ComboBox();
		comboBasic.AddItem("Option 1");
		comboBasic.AddItem("Option 2");
		comboBasic.AddItem("Option 3");
		overlaysDemo.AddView(comboBasic, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		let comboPreselected = new ComboBox();
		comboPreselected.AddItem("Red");
		comboPreselected.AddItem("Green");
		comboPreselected.AddItem("Blue");
		comboPreselected.SelectedIndex = 1;
		overlaysDemo.AddView(comboPreselected, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		// --- Dialog section ---
		overlaysDemo.AddView(new Spacer(0, 4));
		overlaysDemo.AddView(new Label("Dialog"));
		overlaysDemo.AddView(new Separator());

		let dialogRow = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };

		let alertBtn = new Button("Alert");
		alertBtn.OnClick.Add(new (b) =>
		{
			let dlg = Dialog.Alert("Information", "This is an alert dialog.");
			dlg.Show(mUIContext);
		});
		dialogRow.AddView(alertBtn);

		let confirmBtn = new Button("Confirm");
		confirmBtn.OnClick.Add(new (b) =>
		{
			let dlg = Dialog.Confirm("Confirm", "Are you sure you want to proceed?");
			dlg.Show(mUIContext);
		});
		dialogRow.AddView(confirmBtn);
		overlaysDemo.AddView(dialogRow);

		// --- ContextMenu section ---
		overlaysDemo.AddView(new Spacer(0, 4));
		overlaysDemo.AddView(new Label("ContextMenu (right-click below)"));
		overlaysDemo.AddView(new Separator());

		let contextArea = new ContextMenuDemoArea();
		overlaysDemo.AddView(contextArea, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(80)) });

		// --- Tooltip section ---
		overlaysDemo.AddView(new Spacer(0, 4));
		overlaysDemo.AddView(new Label("Tooltips (hover below)"));
		overlaysDemo.AddView(new Separator());

		let tooltipRow = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };
		let ttBtn1 = new Button("Bottom tooltip");
		ttBtn1.TooltipText = new String("This appears below");
		tooltipRow.AddView(ttBtn1);

		let ttBtn2 = new Button("Top tooltip");
		ttBtn2.TooltipText = new String("This appears above");
		ttBtn2.TooltipPlacement = .Top;
		tooltipRow.AddView(ttBtn2);

		let ttBtn3 = new Button("Right tooltip");
		ttBtn3.TooltipText = new String("This appears on the right");
		ttBtn3.TooltipPlacement = .Right;
		tooltipRow.AddView(ttBtn3);

		let ttBtn4 = new Button("Interactive");
		ttBtn4.TooltipText = new String("This tooltip stays while you hover it");
		ttBtn4.IsTooltipInteractive = true;
		tooltipRow.AddView(ttBtn4);

		let ttBtn5 = new RichTooltipButton("Rich content");
		tooltipRow.AddView(ttBtn5);
		overlaysDemo.AddView(tooltipRow);

		// === Tab 7: Drag & Drop demo ===
		let dndDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		dndDemo.Padding = .(12, 8);
		tabView.AddTab("Drag & Drop", dndDemo);

		dndDemo.AddView(new Label("Drag chips to reorder, or drop onto the box"));
		dndDemo.AddView(new Separator());

		let dndRow = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };

		let chipContainer = new ChipReorderContainer();
		chipContainer.Direction = .Horizontal;
		chipContainer.Spacing = 4;

		Color[?] chipColors = .(
			.(220, 60, 60, 255), .(60, 180, 60, 255), .(60, 100, 220, 255),
			.(220, 180, 40, 255), .(180, 60, 220, 255));
		for (int i = 0; i < chipColors.Count; i++)
		{
			let chip = new DragChip(chipColors[i]);
			chipContainer.AddView(chip, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(30)), Height = .Fixed(.Px(30)) });
		}
		dndRow.AddView(chipContainer);

		let dropBox = new ColorDropBox();
		dndRow.AddView(dropBox, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(30)) });
		dndDemo.AddView(dndRow);

		// === Tab 8: Data Controls demo ===
		let dataDemo = new FlexLayout() { Direction = .Horizontal, Spacing = 8 };
		dataDemo.Padding = .(8);
		tabView.AddTab("Data Controls", dataDemo);

		// ListView with 1000 items
		let listCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		listCol.AddView(new Label("ListView (1000 items)"));
		mDemoListAdapter = new DemoListAdapter(1000);
		let listView = new ListView();
		listView.Adapter = mDemoListAdapter;
		listCol.AddView(listView, new FlexLayout.LayoutParams() { Grow = 1 });
		dataDemo.AddView(listCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// TreeView with hierarchy
		let treeCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		treeCol.AddView(new Label("TreeView"));
		mDemoTreeAdapter = new DemoTreeAdapter();
		let treeView = new TreeView();
		treeView.SetAdapter(mDemoTreeAdapter);
		treeCol.AddView(treeView, new FlexLayout.LayoutParams() { Grow = 1 });
		dataDemo.AddView(treeCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// GridView with 200 colored cells
		let gridCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		gridCol.AddView(new Label("GridView (200 cells)"));
		mDemoGridAdapter = new DemoGridAdapter(200);
		let gridView = new GridView();
		gridView.Adapter = mDemoGridAdapter;
		gridCol.AddView(gridView, new FlexLayout.LayoutParams() { Grow = 1 });
		dataDemo.AddView(gridCol, new FlexLayout.LayoutParams() { Grow = 1 });

		// === Tab 9: Docking demo ===
		let dockDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		dockDemo.Padding = .(8);
		tabView.AddTab("Docking", dockDemo);

		let dockManager = new DockManager();
		dockManager.DockableWindowHost = this;
		dockDemo.AddView(dockManager, new FlexLayout.LayoutParams() { Grow = 1 });

		// Create panels with content.
		let dockP1 = dockManager.AddPanel("Scene", new Label("Scene viewport"));
		let dockP2 = dockManager.AddPanel("Inspector", new Label("Inspector properties"));
		let dockP3 = dockManager.AddPanel("Hierarchy", new Label("Scene hierarchy"));
		let dockP4 = dockManager.AddPanel("Console", new Label("Console output"));
		let dockP5 = dockManager.AddPanel("Assets", new Label("Asset browser"));

		// Build an IDE-like layout: Scene center, Inspector right, Hierarchy left, Console+Assets bottom.
		dockManager.DockPanel(dockP1, .Center);
		dockManager.DockPanel(dockP3, .Left);
		dockManager.DockPanel(dockP2, .Right);
		dockManager.DockPanel(dockP4, .Bottom);
		dockManager.DockPanelRelativeTo(dockP5, .Center, dockP4.Parent); // tab alongside Console

		// === Tab 10: Toolkit demo ===
		let toolkitDemo = new FlexLayout() { Direction = .Vertical, Spacing = 0 };
		tabView.AddTab("Toolkit", toolkitDemo);

		// MenuBar at top (fixed height).
		let menuBar = new MenuBar();
		let fileMenu = menuBar.AddMenu("File");
		fileMenu.AddItem("New", new () => {});
		fileMenu.AddItem("Open", new () => {});
		fileMenu.AddSeparator();
		fileMenu.AddItem("Exit", new () => {});
		let editMenu = menuBar.AddMenu("Edit");
		editMenu.AddItem("Undo", new () => {});
		editMenu.AddItem("Redo", new () => {});
		editMenu.AddSeparator();
		editMenu.AddItem("Cut", new () => {});
		editMenu.AddItem("Copy", new () => {});
		editMenu.AddItem("Paste", new () => {});
		let viewMenu = menuBar.AddMenu("View");
		viewMenu.AddItem("Zoom In", new () => {});
		viewMenu.AddItem("Zoom Out", new () => {});
		toolkitDemo.AddView(menuBar, new FlexLayout.LayoutParams() { Width = .Match });

		// Toolbar below menu.
		let toolbar = new Toolbar();
		toolbar.AddButton("New");
		toolbar.AddButton("Open");
		toolbar.AddButton("Save");
		toolbar.AddSeparator();
		toolbar.AddToggle("Bold");
		toolbar.AddToggle("Italic");
		toolkitDemo.AddView(toolbar, new FlexLayout.LayoutParams() { Width = .Match });

		// BreadcrumbBar.
		let breadcrumb = new BreadcrumbBar();
		breadcrumb.SetPath("Project/Assets/Textures/Environment");
		toolkitDemo.AddView(breadcrumb, new FlexLayout.LayoutParams() { Width = .Match });

		// Center area: SplitView on left, DraggableTreeView on right.
		let centerRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		toolkitDemo.AddView(centerRow, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// SplitView.
		let splitView = new SplitView(.Horizontal);
		let leftPane = new Label("Left Pane");
		let rightPane = new Label("Right Pane");
		splitView.SetPanes(leftPane, rightPane);
		splitView.SplitRatio = 0.4f;
		centerRow.AddView(splitView, new FlexLayout.LayoutParams() { Grow = 1 });

		// DraggableTreeView.
		let dragCol = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		dragCol.AddView(new Label("Drag to reorder:"));
		let reorderAdapter = new ReorderableListAdapter(
			StringView[]("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"));
		mReorderAdapter = reorderAdapter;
		let dragTree = new DraggableTreeView();
		dragTree.SetAdapter(reorderAdapter);
		dragTree.ItemHeight = 22;
		dragCol.AddView(dragTree, new FlexLayout.LayoutParams() { Grow = 1 });
		centerRow.AddView(dragCol, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(200)) });

		// ColorPicker.
		let colorPicker = new ColorPicker();
		colorPicker.CurrentColor = .(80, 160, 240, 255);
		colorPicker.SetOriginalColor(.(80, 160, 240, 255));
		centerRow.AddView(colorPicker);

		// StatusBar at bottom.
		let statusBar = new StatusBar();
		statusBar.SetText("Ready");
		statusBar.AddSection("Ln 42, Col 8");
		statusBar.AddSection("UTF-8");
		toolkitDemo.AddView(statusBar, new FlexLayout.LayoutParams() { Width = .Match });

		// === Tab 11: PropertyGrid demo ===
		let pgDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		pgDemo.Padding = .(8);
		tabView.AddTab("PropertyGrid", pgDemo);

		let propGrid = new PropertyGrid();
		propGrid.AddProperty(new BoolEditor("Enabled", true));
		propGrid.AddProperty(new BoolEditor("Visible", true));
		propGrid.AddProperty(new StringEditor("Name", "Player"));
		propGrid.AddProperty(new FloatEditor("Speed", 5.0, 0, 100, 0.5, 1));
		propGrid.AddProperty(new IntEditor("Health", 100, 0, 999));
		propGrid.AddProperty(new RangeEditor("Volume", 0.75f, 0, 1, 0.01f));
		propGrid.AddProperty(new EnumEditor("Mode", 0, StringView[]("Easy", "Normal", "Hard")));
		propGrid.AddProperty(new ColorEditor("Tint", .(255, 200, 100, 255)));
		propGrid.AddProperty(new Vector3Editor("Position", .(1.0f, 2.5f, -3.0f), category: "Transform"));
		propGrid.AddProperty(new Vector3Editor("Rotation", .(0, 45, 0), category: "Transform"));
		propGrid.AddProperty(new Vector3Editor("Scale", .(1, 1, 1), category: "Transform"));
		pgDemo.AddView(propGrid, new FlexLayout.LayoutParams() { Grow = 1 });

		// === Tab 12a: CurveCanvas / tangent editor demo ===
		let curveDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		curveDemo.Padding = .(12, 8);
		tabView.AddTab("Curve Editor", curveDemo);

		let curveHelp = new Label();
		curveHelp.SetText("Left-click empty space: add key.  Left-click + drag key: move.  Right-click key: delete.\nLeft-click + drag the colored handles on the selected key: edit tangent.  Right-click handle: cycle TangentMode (Mirrored / Free / Flat).");
		curveDemo.AddView(curveHelp, new FlexLayout.LayoutParams() { Width = .Match });

		let curve = new CurveCanvas();
		curve.MaxKeys = 12;
		ChannelDescriptor[1] curveChannels = .(.()
			{
				Name = "easeOut",
				StrokeColor = .(120, 220, 160, 255),
				DefaultValue = 0,
				DisplayMin = 0, DisplayMax = 1,
				Interpolation = .Hermite,
			});
		curve.SetChannels(curveChannels);

		// Seed with a default ease-in / ease-out shape so the user sees
		// curving tangents immediately - flat keys would hide what the
		// new handle UI is actually doing.
		CurveCanvas.Key[3] seedKeys = .(
			.(0.0f, 0.0f, 0,    1.5f, .Mirrored),
			.(0.5f, 0.5f, 1.5f, 1.5f, .Mirrored),
			.(1.0f, 1.0f, 1.5f, 0,    .Mirrored));
		curve.SetKeys(0, seedKeys);
		curveDemo.AddView(curve, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		let curveStatus = new Label();
		curveStatus.SetText("Selected key: (none)");
		curveDemo.AddView(curveStatus, new FlexLayout.LayoutParams() { Width = .Match });

		// Refresh the status line whenever a key is edited - both
		// position drags and tangent drags hit OnKeyChanged.
		delegate void(int32, int32) refreshStatus = new [=curve, =curveStatus] (c, k) =>
		{
			let selCh = curve.SelectedChannel;
			let selKey = curve.SelectedKeyIndex;
			if (selCh < 0 || selKey < 0 || selKey >= curve.GetKeyCount(selCh))
			{
				curveStatus.SetText("Selected key: (none)");
				return;
			}
			let key = curve.GetKey(selCh, selKey);
			let modeName = scope String();
			switch (key.Mode)
			{
			case .Mirrored: modeName.Set("Mirrored");
			case .Free:     modeName.Set("Free");
			case .Flat:     modeName.Set("Flat");
			}
			curveStatus.SetText(scope $"Key #{selKey}  t={key.Time:0.00}  v={key.Value:0.00}  tIn={key.TangentIn:0.00}  tOut={key.TangentOut:0.00}  mode={modeName}");
		};
		curve.OnKeyChanged.Add(refreshStatus);
		curve.OnKeyAdded.Add(new  (c, k) => refreshStatus(c, k));
		curve.OnKeyRemoved.Add(new  (c, k) => refreshStatus(c, k));

		// === Tab 12: Animations & Transforms demo ===
		let animDemo = new FlexLayout() { Direction = .Vertical, Spacing = 8 };
		animDemo.Padding = .(12, 8);
		tabView.AddTab("Animations", animDemo);

		// Animation target
		animDemo.AddView(new Label("Animation Target"));
		let animTarget = new ColorView(.(80, 160, 255, 255), 0, 30);
		animDemo.AddView(animTarget, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(30)) });

		// Animation buttons
		let animRow = new FlexLayout() { Direction = .Horizontal, Spacing = 6 };

		let fadeOutBtn = new Button("Fade Out");
		fadeOutBtn.OnClick.Add(new (b) =>
		{
			mUIContext.Animations.Add(ViewAnimator.FadeOut(animTarget, 0.5f, Easing.EaseOutCubic));
		});
		animRow.AddView(fadeOutBtn);

		let fadeInBtn = new Button("Fade In");
		fadeInBtn.OnClick.Add(new (b) =>
		{
			mUIContext.Animations.Add(ViewAnimator.FadeIn(animTarget, 0.5f, Easing.EaseOutCubic));
		});
		animRow.AddView(fadeInBtn);

		let bounceBtn = new Button("Bounce");
		bounceBtn.OnClick.Add(new (b) =>
		{
			let sb = new Storyboard(.Sequential);
			sb.Add(ViewAnimator.ScaleTo(animTarget, 1.0f, 1.3f, 0.15f, Easing.EaseOutCubic));
			sb.Add(ViewAnimator.ScaleTo(animTarget, 1.3f, 1.0f, 0.3f, Easing.BounceOut));
			mUIContext.Animations.Add(sb);
		});
		animRow.AddView(bounceBtn);

		let slideBtn = new Button("Slide");
		slideBtn.OnClick.Add(new (b) =>
		{
			let sb = new Storyboard(.Sequential);
			sb.Add(ViewAnimator.TranslateX(animTarget, 0, 50, 0.3f, Easing.EaseOutCubic));
			sb.Add(ViewAnimator.TranslateX(animTarget, 50, 0, 0.3f, Easing.EaseInCubic));
			mUIContext.Animations.Add(sb);
		});
		animRow.AddView(slideBtn);
		animDemo.AddView(animRow);

		// Transform demos
		animDemo.AddView(new Spacer(0, 8));
		animDemo.AddView(new Label("Static Transforms (click to verify hit-testing)"));
		animDemo.AddView(new Separator());

		let transformClickLabel = new Label("Click a transformed button...");
		let transformRow = new FlexLayout() { Direction = .Horizontal, Spacing = 16 };

		let rotBtn = new Button("Rotated");
		rotBtn.Transform = .() { Rotation = 0.15f };
		rotBtn.OnClick.Add(new (b) => { transformClickLabel.SetText("Rotated button clicked!"); });
		transformRow.AddView(rotBtn);

		let scaleBtn = new Button("Scaled 1.2x");
		scaleBtn.Transform = .() { Scale = .(1.2f, 1.2f) };
		scaleBtn.OnClick.Add(new (b) => { transformClickLabel.SetText("Scaled button clicked!"); });
		transformRow.AddView(scaleBtn);

		let skewTranslateBtn = new Button("Translated");
		skewTranslateBtn.Transform = .() { Translation = .(10, 5) };
		skewTranslateBtn.OnClick.Add(new (b) => { transformClickLabel.SetText("Translated button clicked!"); });
		transformRow.AddView(skewTranslateBtn);

		animDemo.AddView(transformRow);
		animDemo.AddView(transformClickLabel);

		// === Tab 13: Node Graph demo ===
		{
			let graphCanvas = new NodeGraphCanvas();
			graphCanvas.ShowGrid = true;

			// Sample nodes
			let nodeA = new NodeGraphNode();
			nodeA.Title.Set("Idle");
			nodeA.Position = .(50, 50);
			nodeA.HeaderColor = .(70, 130, 80, 255);
			let aOut = new NodeGraphPort();
			aOut.Direction = .Output;
			aOut.Label.Set("Out");
			nodeA.OutputPorts.Add(aOut);
			let aIn = new NodeGraphPort();
			aIn.Direction = .Input;
			aIn.Label.Set("In");
			nodeA.InputPorts.Add(aIn);
			graphCanvas.AddNode(nodeA);

			let nodeB = new NodeGraphNode();
			nodeB.Title.Set("Walk");
			nodeB.Position = .(300, 50);
			nodeB.HeaderColor = .(70, 100, 180, 255);
			let bOut = new NodeGraphPort();
			bOut.Direction = .Output;
			bOut.Label.Set("Out");
			nodeB.OutputPorts.Add(bOut);
			let bIn = new NodeGraphPort();
			bIn.Direction = .Input;
			bIn.Label.Set("In");
			nodeB.InputPorts.Add(bIn);
			graphCanvas.AddNode(nodeB);

			let nodeC = new NodeGraphNode();
			nodeC.Title.Set("Run");
			nodeC.Subtitle.Set("BlendTree1D");
			nodeC.Position = .(300, 200);
			nodeC.HeaderColor = .(180, 100, 70, 255);
			let cOut = new NodeGraphPort();
			cOut.Direction = .Output;
			cOut.Label.Set("Out");
			nodeC.OutputPorts.Add(cOut);
			let cIn = new NodeGraphPort();
			cIn.Direction = .Input;
			cIn.Label.Set("In");
			nodeC.InputPorts.Add(cIn);
			let cIn2 = new NodeGraphPort();
			cIn2.Direction = .Input;
			cIn2.Label.Set("Speed");
			cIn2.PortType = .(1, .(100, 200, 100, 255));
			nodeC.InputPorts.Add(cIn2);
			graphCanvas.AddNode(nodeC);

			let nodeD = new NodeGraphNode();
			nodeD.Title.Set("Any State");
			nodeD.Position = .(50, 200);
			nodeD.HeaderColor = .(100, 100, 110, 255);
			nodeD.IsDeletable = false;
			let dOut = new NodeGraphPort();
			dOut.Direction = .Output;
			dOut.Label.Set("");
			nodeD.OutputPorts.Add(dOut);
			graphCanvas.AddNode(nodeD);

			// Connections: Idle -> Walk, Idle -> Run, AnyState -> Walk
			graphCanvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
			graphCanvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 2, DestPortIndex = 0 });
			graphCanvas.AddConnection(.() { SourceNodeIndex = 3, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });

			// Wire events to console
			graphCanvas.OnNodeMoved.Add(new (idx) => { Console.WriteLine("Node moved: {}", idx); });
			graphCanvas.OnConnectionCreated.Add(new (idx) => { Console.WriteLine("Connection created: {}", idx); });
			graphCanvas.OnNodeDeleted.Add(new (idx) => { Console.WriteLine("Node deleted: {}", idx); });
			graphCanvas.OnSelectionChanged.Add(new () => { Console.WriteLine("Selection changed"); });
			graphCanvas.OnCanvasContextMenu.Add(new (x, y) => { Console.WriteLine("Canvas context menu at ({}, {})", x, y); });
			graphCanvas.OnNodeContextMenu.Add(new (idx) => { Console.WriteLine("Node context menu: {}", idx); });
			graphCanvas.OnNodeDoubleClicked.Add(new (idx) => { Console.WriteLine("Node double-clicked: {}", idx); });

			tabView.AddTab("Node Graph", graphCanvas);
		}

		// === Pause Menu (.sml demo) ===
		let pauseMenu = MarkupLoader.LoadFromFile("screens/pause-menu.sml", mGuiResourceProvider);
		if (pauseMenu != null)
		{
			tabView.AddTab("Pause (.sml)", pauseMenu, true);

			// Wire up button events by name lookup
			let pauseRoot = pauseMenu as ViewGroup;
			if (pauseRoot != null)
			{
				if (let resumeBtn = pauseRoot.FindByName<Button>("resume-btn"))
					resumeBtn.OnClick.Add(new (b) => { Console.WriteLine("Resume clicked!"); });
				if (let settingsBtn = pauseRoot.FindByName<Button>("settings-btn"))
					settingsBtn.OnClick.Add(new (b) => { Console.WriteLine("Settings clicked!"); });
				if (let saveBtn = pauseRoot.FindByName<Button>("save-btn"))
					saveBtn.OnClick.Add(new (b) => { Console.WriteLine("Save clicked!"); });
				if (let loadBtn = pauseRoot.FindByName<Button>("load-btn"))
					loadBtn.OnClick.Add(new (b) => { Console.WriteLine("Load clicked!"); });
				if (let quitBtn = pauseRoot.FindByName<Button>("quit-btn"))
					quitBtn.OnClick.Add(new (b) => { Console.WriteLine("Quit clicked!"); });
			}
		}

		// Footer with theme label
		let footer = new Panel();
		footer.AddClass("panel");
		footer.Padding = .(8, 2, 8, 2);
		mThemeLabel = new Label("Theme: Dark (F5)");
		mThemeLabel.FontSize.Value = 11;
		footer.AddView(mThemeLabel);
		main.AddView(footer, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });
		UpdateThemeLabel();
	}

	protected override void OnInput(FrameContext frame)
	{
		// Update repeat button
		mRepeatBtn?.UpdateRepeat(frame.DeltaTime);

		// Multi-window input routing.
		let mouse = Shell?.InputManager?.Mouse;
		let kb = Shell?.InputManager?.Keyboard;
		let inputHelper = mUI.InputHelper;

		if (mouse != null && inputHelper != null)
		{
			let dragDrop = mUIContext.DragDropManager;

			// Determine which window has the mouse.
			RootView inputRoot = mRoot;
			for (let kv in mDockableWindowMap)
			{
				if (kv.value.Window.Focused)
				{
					if (let data = kv.value.UserData as DockableWindowRenderData)
						inputRoot = data.RootView;
					break;
				}
			}

			// Update keyboard modifiers for shift+wheel and other modifier-aware input.
			inputHelper.UpdateModifiers(kb);

			// Cross-window drag: move OS window, route input to main window.
			if ((dragDrop.IsDragging || dragDrop.IsPotentialDrag) && inputRoot !== mRoot)
			{
				let globalX = mouse.GlobalX;
				let globalY = mouse.GlobalY;

				if (dragDrop.IsDragging && mDragSourceWindow == null)
				{
					for (let kv in mDockableWindowMap)
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

				mUIContext.ActiveInputRoot = mRoot;
				let mx = globalX - (float)mWindow.X;
				let my = globalY - (float)mWindow.Y;
				inputHelper.ProcessMouseInput(mouse, mUIContext, mx, my);
				if (kb != null)
					inputHelper.ProcessKeyboardInput(kb, mUIContext, 0);
			}
			else
			{
				if (mDragSourceWindow != null)
					mDragSourceWindow = null;

				mUIContext.ActiveInputRoot = inputRoot;
				inputHelper.ProcessMouseInput(mouse, mUIContext);
				if (kb != null)
					inputHelper.ProcessKeyboardInput(kb, mUIContext, 0);
			}
		}

		let keyboard = Shell.InputManager.Keyboard;

		if (keyboard.IsKeyPressed(.Escape))
			Exit();

		// Debug overlay toggles
		if (keyboard.IsKeyPressed(.F2))
			mUIContext.DebugSettings.ShowBounds = !mUIContext.DebugSettings.ShowBounds;
		if (keyboard.IsKeyPressed(.F3))
		{
			mUIContext.DebugSettings.ShowPadding = !mUIContext.DebugSettings.ShowPadding;
			mUIContext.DebugSettings.ShowMargin = !mUIContext.DebugSettings.ShowMargin;
		}
		if (keyboard.IsKeyPressed(.F4))
		{
			mUIContext.DebugSettings.ShowHitTarget = !mUIContext.DebugSettings.ShowHitTarget;
			mUIContext.DebugSettings.ShowFocusPath = !mUIContext.DebugSettings.ShowFocusPath;
		}
		// F5: cycle themes
		if (keyboard.IsKeyPressed(.F5))
		{
			mThemeIndex = (mThemeIndex + 1) % 5;
			ApplyTheme();
		}
	}

	private void ApplyTheme()
	{
		StyleSheet sheet;
		switch (mThemeIndex)
		{
		case 0:  sheet = DarkTheme.Create(); mPalette = .Dark;
		case 1:  sheet = LightTheme.Create(); mPalette = .Light;
		case 2:  sheet = RoundedDarkTheme.Create(); mPalette = .Dark;
		case 3:  sheet = CreateTexturedTheme(); mPalette = .Light;
		default: sheet = LoadSSSTheme("themes/breeze.sss", .Dark); mPalette = .Dark;
		}
		mUIContext.StyleSheet = sheet;
		sheet.ReleaseRef();
		UpdateThemeLabel();
	}

	private void UpdateThemeLabel()
	{
		if (mThemeLabel != null)
		{
			StringView[5] names = .("Dark", "Light", "Rounded Dark", "Textured", "Breeze (.sss)");
			let name = (mThemeIndex >= 0 && mThemeIndex < 5) ? names[mThemeIndex] : "Unknown";
			mThemeLabel.SetText(scope $"Theme: {name} (F5)");
		}
	}

	/// Load a .sss theme file from Assets/gui/.
	private StyleSheet LoadSSSTheme(StringView path, ThemePalette palette)
	{
		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = mGuiResourceProvider;
		loader.SetPalette(palette);

		// Register built-in SVG icons
		loader.RegisterSvg("checkmark", ThemeIcons.Checkmark);
		loader.RegisterSvg("radio-mark-square", ThemeIcons.RadioMarkSquare);
		loader.RegisterSvg("radio-mark-round", ThemeIcons.RadioMarkRound);
		loader.RegisterSvg("close", ThemeIcons.Close);
		loader.RegisterSvg("chevron-down", ThemeIcons.ChevronDown);
		loader.RegisterSvg("chevron-right", ThemeIcons.ChevronRight);
		loader.RegisterSvg("arrow-down", ThemeIcons.ArrowDown);
		loader.RegisterSvg("arrow-up", ThemeIcons.ArrowUp);

		let sssText = scope String();
		if (mGuiResourceProvider.LoadText(path, sssText) case .Err)
		{
			// Fallback to Beef-coded dark theme
			Console.WriteLine(scope $"WARNING: Failed to load {path}, falling back to DarkTheme");
			return DarkTheme.Create();
		}

		return loader.Load(sssText);
	}

	/// Create a textured theme with procedurally generated game-styled images.
	private static StyleSheet CreateTexturedTheme()
	{
		let images = scope ThemeImageSet();

		// --- Button: soft blue ---
		let btnN = MakeRoundedRectImage(48, 32, .(180, 200, 225, 255), .(140, 165, 195, 255), 6);
		let btnH = MakeRoundedRectImage(48, 32, .(190, 210, 235, 255), .(150, 175, 205, 255), 6);
		let btnP = MakeRoundedRectImage(48, 32, .(150, 175, 205, 255), .(120, 145, 175, 255), 6);
		let btnD = MakeRoundedRectImage(48, 32, .(195, 205, 215, 128), .(175, 185, 195, 128), 6);
		defer { delete btnN; delete btnH; delete btnP; delete btnD; }
		images.AddStateImages("button:Background", btnN, btnH, btnP, btnD, slices: .(8, 8, 8, 8));

		// --- Panel: light blue-gray ---
		let panelImg = MakeRoundedRectImage(48, 48, .(220, 230, 240, 255), .(185, 200, 220, 255), 4);
		defer delete panelImg;
		images.AddImage("panel:Background", panelImg, .(8, 8, 8, 8));

		// --- EditText: white with blue border ---
		let etNorm = MakeRoundedRectImage(48, 28, .(245, 248, 252, 255), .(170, 185, 210, 255), 4);
		let etFocus = MakeRoundedRectImage(48, 28, .(245, 248, 252, 255), .(80, 130, 200, 255), 4);
		defer { delete etNorm; delete etFocus; }
		images.AddStateImages("edittext:Background", etNorm, focused: etFocus, slices: .(6, 6, 6, 6));
		images.AddStateImages("numericfield:Background", etNorm, focused: etFocus, slices: .(6, 6, 6, 6));

		// --- NumericField spin buttons: light gray, rounded on right side only ---
		let spinUpN = MakeRoundedRectImage(20, 16, .(225, 230, 240, 255), .(170, 185, 210, 255), 0, 3, 0, 0);
		let spinUpH = MakeRoundedRectImage(20, 16, .(210, 218, 230, 255), .(150, 170, 200, 255), 0, 3, 0, 0);
		let spinUpP = MakeRoundedRectImage(20, 16, .(195, 205, 220, 255), .(140, 160, 190, 255), 0, 3, 0, 0);
		defer { delete spinUpN; delete spinUpH; delete spinUpP; }
		images.AddStateImages("numericfield::spin-up", spinUpN, spinUpH, spinUpP, slices: .(4, 4, 4, 4));

		let spinDnN = MakeRoundedRectImage(20, 16, .(225, 230, 240, 255), .(170, 185, 210, 255), 0, 0, 3, 0);
		let spinDnH = MakeRoundedRectImage(20, 16, .(210, 218, 230, 255), .(150, 170, 200, 255), 0, 0, 3, 0);
		let spinDnP = MakeRoundedRectImage(20, 16, .(195, 205, 220, 255), .(140, 160, 190, 255), 0, 0, 3, 0);
		defer { delete spinDnN; delete spinDnH; delete spinDnP; }
		images.AddStateImages("numericfield::spin-down", spinDnN, spinDnH, spinDnP, slices: .(4, 4, 4, 4));

		// --- CheckBox ---
		let cbUnchecked = MakeRoundedRectImage(16, 16, .(240, 244, 250, 255), .(160, 175, 200, 255), 3);
		let cbChecked = MakeRoundedRectImage(16, 16, .(80, 140, 220, 255), .(60, 120, 200, 255), 3);
		defer { delete cbUnchecked; delete cbChecked; }
		images.AddImage("checkbox::box", cbUnchecked);
		images.AddImage("checkbox::box:checked", cbChecked);

		// --- RadioButton ---
		let rbCircle = MakeRoundedRectImage(16, 16, .(240, 244, 250, 255), .(160, 175, 200, 255), 8);
		let rbDot = MakeRoundedRectImage(16, 16, .(80, 140, 220, 255), .(60, 120, 200, 255), 8);
		defer { delete rbCircle; delete rbDot; }
		images.AddImage("radiobutton::box", rbCircle);
		images.AddImage("radiobutton::box:checked", rbDot);

		// --- Slider ---
		let slTrack = MakeRoundedRectImage(32, 6, .(195, 205, 220, 255), .(195, 205, 220, 0), 3);
		let slFill = MakeRoundedRectImage(32, 6, .(80, 140, 220, 255), .(80, 140, 220, 0), 3);
		let slThumb = MakeRoundedRectImage(14, 14, .(255, 255, 255, 255), .(140, 165, 200, 255), 7);
		defer { delete slTrack; delete slFill; delete slThumb; }
		images.AddImage("slider::track", slTrack, .(3, 2, 3, 2));
		images.AddImage("slider::fill", slFill, .(3, 2, 3, 2));
		images.AddImage("slider::thumb", slThumb);

		// --- ProgressBar ---
		let progTrack = MakeRoundedRectImage(32, 12, .(195, 205, 220, 255), .(195, 205, 220, 0), 4);
		let progFill = MakeRoundedRectImage(32, 12, .(80, 140, 220, 255), .(80, 140, 220, 0), 4);
		defer { delete progTrack; delete progFill; }
		images.AddImage("progressbar::track", progTrack, .(4, 4, 4, 4));
		images.AddImage("progressbar::fill", progFill, .(4, 4, 4, 4));

		// --- ToggleSwitch ---
		let tsOff = MakeRoundedRectImage(44, 24, .(190, 200, 215, 255), .(170, 185, 205, 255), 12);
		let tsOn = MakeRoundedRectImage(44, 24, .(80, 140, 220, 255), .(60, 120, 200, 255), 12);
		let tsKnob = MakeRoundedRectImage(20, 20, .(255, 255, 255, 255), .(210, 215, 225, 255), 10);
		defer { delete tsOff; delete tsOn; delete tsKnob; }
		images.AddImage("toggleswitch::track", tsOff, .(12, 12, 12, 12));
		images.AddImage("toggleswitch::track:checked", tsOn, .(12, 12, 12, 12));
		images.AddImage("toggleswitch::knob", tsKnob);

		// --- ComboBox ---
		let cbxN = MakeRoundedRectImage(48, 28, .(240, 244, 250, 255), .(170, 185, 210, 255), 4);
		let cbxH = MakeRoundedRectImage(48, 28, .(230, 238, 248, 255), .(150, 170, 200, 255), 4);
		defer { delete cbxN; delete cbxH; }
		images.AddStateImages("combobox:Background", cbxN, cbxH, slices: .(6, 6, 6, 6));

		// --- ScrollBar ---
		let scrollTrack = MakeRoundedRectImage(12, 32, .(210, 218, 230, 150), .(210, 218, 230, 0), 3);
		let scrollThumb = MakeRoundedRectImage(12, 24, .(150, 170, 200, 200), .(150, 170, 200, 0), 3);
		defer { delete scrollTrack; delete scrollThumb; }
		images.AddImage("scrollbar::track", scrollTrack, .(4, 6, 4, 6));
		images.AddImage("scrollbar::thumb", scrollThumb, .(4, 6, 4, 6));

		// --- Dialog ---
		let dialogImg = MakeRoundedRectImage(64, 64, .(235, 240, 248, 255), .(170, 185, 210, 255), 8);
		defer delete dialogImg;
		images.AddImage("dialog:Background", dialogImg, .(10, 10, 10, 10));

		// --- Tooltip ---
		let tooltipImg = MakeRoundedRectImage(32, 24, .(255, 255, 225, 245), .(180, 175, 140, 255), 4);
		defer delete tooltipImg;
		images.AddImage("tooltip:Background", tooltipImg, .(6, 6, 6, 6));

		// --- ContextMenu ---
		let ctxMenuImg = MakeRoundedRectImage(48, 48, .(240, 244, 250, 255), .(175, 190, 215, 255), 6);
		defer delete ctxMenuImg;
		images.AddImage("contextmenu:Background", ctxMenuImg, .(8, 8, 8, 8));

		// --- ContextMenu item hover ---
		let ctxHover = MakeRoundedRectImage(32, 24, .(80, 140, 220, 60), .(80, 140, 220, 0), 3);
		defer delete ctxHover;
		images.AddImage("contextmenu:MenuItemHoverDrawable", ctxHover, .(4, 4, 4, 4));

		// --- TabView ---
		let tabStrip = MakeRoundedRectImage(48, 32, .(210, 218, 230, 255), .(210, 218, 230, 0), 0);
		let tabContent = MakeRoundedRectImage(48, 48, .(228, 234, 244, 255), .(228, 234, 244, 0), 0);
		let tabActive = MakeRoundedRectImage(64, 28, .(240, 244, 250, 255), .(240, 244, 250, 0), 4);
		let tabHover = MakeRoundedRectImage(64, 28, .(220, 228, 240, 255), .(220, 228, 240, 0), 4);
		defer { delete tabStrip; delete tabContent; delete tabActive; delete tabHover; }
		images.AddImage("tabview::strip", tabStrip, .(4, 4, 4, 4));
		images.AddImage("tabview::content", tabContent, .(4, 4, 4, 4));
		images.AddImage("tabview::tab:checked", tabActive, .(6, 6, 6, 4));
		images.AddImage("tabview::tab:hover", tabHover, .(6, 6, 6, 4));

		// --- Expander header ---
		let expN = MakeRoundedRectImage(48, 24, .(215, 222, 235, 255), .(215, 222, 235, 0), 0);
		let expH = MakeRoundedRectImage(48, 24, .(205, 215, 230, 255), .(205, 215, 230, 0), 0);
		defer { delete expN; delete expH; }
		images.AddImage("expander::header", expN, .(4, 4, 4, 4));
		images.AddImage("expander::header:hover", expH, .(4, 4, 4, 4));

		return TexturedTheme.Create(images, .Light);
	}

	/// Generate a rounded rectangle image with per-corner radii.
	private static OwnedImageData MakeRoundedRectImage(uint32 w, uint32 h,
		Color fill, Color border, int radiusTL, int radiusTR, int radiusBR, int radiusBL)
	{
		let data = new uint8[w * h * 4];

		for (uint32 y = 0; y < h; y++)
		{
			for (uint32 x = 0; x < w; x++)
			{
				bool inside = true;
				bool isBorder = false;

				int cx = -1, cy = -1;
				int r = 0;
				if (x < (uint32)radiusTL && y < (uint32)radiusTL) { cx = radiusTL; cy = radiusTL; r = radiusTL; }
				else if (x >= w - (uint32)radiusTR && y < (uint32)radiusTR) { cx = (int)w - radiusTR - 1; cy = radiusTR; r = radiusTR; }
				else if (x < (uint32)radiusBL && y >= h - (uint32)radiusBL) { cx = radiusBL; cy = (int)h - radiusBL - 1; r = radiusBL; }
				else if (x >= w - (uint32)radiusBR && y >= h - (uint32)radiusBR) { cx = (int)w - radiusBR - 1; cy = (int)h - radiusBR - 1; r = radiusBR; }

				if (cx >= 0)
				{
					let dx = (int)x - cx;
					let dy = (int)y - cy;
					let dist = Math.Sqrt((float)(dx * dx + dy * dy));
					if (dist > (float)r) inside = false;
					else if (dist > (float)(r - 1)) isBorder = true;
				}

				if (inside && cx < 0)
				{
					if (x == 0 || x == w - 1 || y == 0 || y == h - 1)
						isBorder = true;
				}

				let c = inside ? (isBorder ? border : fill) : Color(0, 0, 0, 0);
				let offset = (int)(y * w + x) * 4;
				data[offset] = c.R;
				data[offset + 1] = c.G;
				data[offset + 2] = c.B;
				data[offset + 3] = c.A;
			}
		}

		return new OwnedImageData(w, h, .RGBA8, data);
	}

	/// Generate a rounded rectangle image with fill and border colors.
	private static OwnedImageData MakeRoundedRectImage(uint32 w, uint32 h,
		Color fill, Color border, int radius)
	{
		let data = new uint8[w * h * 4];

		for (uint32 y = 0; y < h; y++)
		{
			for (uint32 x = 0; x < w; x++)
			{
				bool inside = true;
				bool isBorder = false;

				int cx = -1, cy = -1;
				if (x < (uint32)radius && y < (uint32)radius) { cx = radius; cy = radius; }
				else if (x >= w - (uint32)radius && y < (uint32)radius) { cx = (int)w - radius - 1; cy = radius; }
				else if (x < (uint32)radius && y >= h - (uint32)radius) { cx = radius; cy = (int)h - radius - 1; }
				else if (x >= w - (uint32)radius && y >= h - (uint32)radius) { cx = (int)w - radius - 1; cy = (int)h - radius - 1; }

				if (cx >= 0)
				{
					let dx = (int)x - cx;
					let dy = (int)y - cy;
					let dist = Math.Sqrt((float)(dx * dx + dy * dy));
					if (dist > (float)radius) inside = false;
					else if (dist > (float)(radius - 1)) isBorder = true;
				}

				if (inside && cx < 0)
				{
					if (x == 0 || x == w - 1 || y == 0 || y == h - 1)
						isBorder = true;
				}

				let c = inside ? (isBorder ? border : fill) : Color(0, 0, 0, 0);
				let offset = (int)(y * w + x) * 4;
				data[offset] = c.R;
				data[offset + 1] = c.G;
				data[offset + 2] = c.B;
				data[offset + 3] = c.A;
			}
		}

		return new OwnedImageData(w, h, .RGBA8, data);
	}

	private ThemePalette mPalette = .Dark;

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return false;

		// Clear with theme background color.
		let bg = mPalette.Background;
		ColorAttachment[1] clearAttachments = .(.()
			{
				View = render.CurrentTextureView,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = ClearColor(bg.R / 255.0f, bg.G / 255.0f, bg.B / 255.0f, 1.0f)
			});
		RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
		let clearPass = render.Encoder.BeginRenderPass(clearDesc);
		if (clearPass != null)
			clearPass.End();

		// Render UI overlay on top of cleared background.
		mUI.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height, render.Frame.FrameIndex);

		return true;
	}

	protected override void OnShutdown()
	{
		// Destroy all dockable OS windows before UI shutdown.
		let dockableViews = scope System.Collections.List<View>();
		for (let kv in mDockableWindowMap)
			dockableViews.Add(kv.key);
		for (let view in dockableViews)
			DestroyDockableWindowImpl(view, detachView: false);
		mDockableWindowMap.Clear();

		// Remove root from context before deletion (unregisters all views)
		if (mUIContext != null && mRoot != null)
			mUIContext.RemoveRootView(mRoot);

		// App owns UIContext and RootView - delete in reverse creation order
		if (mRoot != null)
		{
			delete mRoot;
			mRoot = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}
	}

	// =================================================================
	// IDockableWindowHost
	// =================================================================

	public bool SupportsOSWindows => true;

	public void CreateDockableWindow(View dockableWindow, float width, float height,
		float screenX, float screenY, delegate void(View) onCloseRequested = null)
	{
		let settings = Sedulous.Shell.WindowSettings()
		{
			Title = scope .("Float"),
			Width = (int32)width,
			Height = (int32)height,
			Resizable = true,
			Bordered = false
		};

		if (CreateSecondaryWindow(settings) case .Err)
		{
			Console.WriteLine("Failed to create dockable OS window");
			delete onCloseRequested;
			return;
		}

		let ctx = mSecondaryWindows[mSecondaryWindows.Count - 1];
		ctx.Window.X = mWindow.X + (int32)screenX;
		ctx.Window.Y = mWindow.Y + (int32)screenY;

		let data = new DockableWindowRenderData();
		data.OnCloseDelegate = onCloseRequested;
		if (onCloseRequested != null)
			ctx.OnCloseRequested = new (swCtx) => { data.OnCloseDelegate(dockableWindow); };
		else
			ctx.OnCloseRequested = new (swCtx) => { };

		data.RootView = new RootView();
		data.RootView.DpiScale = ctx.Window.ContentScale;
		data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
		mUIContext.AddRootView(data.RootView);
		data.RootView.AddView(dockableWindow);
		data.DockableView = dockableWindow;

		data.VGContext = new Sedulous.VG.VGContext(mUI.FontService);

		data.VGRenderer = new Sedulous.VG.Renderer.VGRenderer();
		if (data.VGRenderer.Initialize(Device, ctx.SwapChain.Format,
			(int32)ctx.SwapChain.BufferCount, mUI.ShaderSystem) case .Err)
		{
			Console.WriteLine("Failed to initialize VGRenderer for dockable window");
		}

		ctx.UserData = data;
		mDockableWindowMap[dockableWindow] = ctx;
	}

	public void DestroyDockableWindow(View dockableWindow)
	{
		DestroyDockableWindowImpl(dockableWindow);
	}

	public void MoveDockableWindow(View dockableWindow, float screenX, float screenY)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let ctx))
		{
			ctx.Window.X = mWindow.X + (int32)screenX;
			ctx.Window.Y = mWindow.Y + (int32)screenY;
		}
	}

	private void DestroyDockableWindowImpl(View dockableWindow, bool detachView = true)
	{
		if (!mDockableWindowMap.TryGetValue(dockableWindow, let ctx))
			return;

		mDockableWindowMap.Remove(dockableWindow);

		if (let data = ctx.UserData as DockableWindowRenderData)
		{
			if (detachView && dockableWindow.Parent == data.RootView)
				data.RootView.RemoveView(dockableWindow, false);

			mUIContext.RemoveRootView(data.RootView);
			mDevice.WaitIdle();
			delete data;
		}

		ctx.UserData = null;
		DestroySecondaryWindow(ctx);
	}

	protected override void OnPrepareSecondaryFrame(SecondaryWindowContext ctx, FrameContext frame)
	{
		if (let data = ctx.UserData as DockableWindowRenderData)
		{
			data.RootView.DpiScale = ctx.Window.ContentScale;
			data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
			mUIContext.UpdateRootView(data.RootView);
		}
	}

	protected override void OnRenderSecondaryWindow(SecondaryWindowContext ctx,
		IRenderPassEncoder renderPass, FrameContext frame)
	{
		if (let data = ctx.UserData as DockableWindowRenderData)
		{
			let vg = data.VGContext;
			let renderer = data.VGRenderer;
			let w = ctx.SwapChain.Width;
			let h = ctx.SwapChain.Height;

			vg.Clear();
			mUIContext.DrawRootView(data.RootView, vg);
			let batch = vg.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			renderer.UpdateProjection(w, h, frame.FrameIndex);
			renderer.Prepare(batch, frame.FrameIndex);
			renderer.Render(renderPass, w, h, frame.FrameIndex);
		}
	}

	/// Generate a checkerboard image for ImageView demo.
	private static OwnedImageData GenerateCheckerboard(int w, int h, int cellSize, Color c1, Color c2)
	{
		let data = new uint8[w * h * 4];
		for (int y = 0; y < h; y++)
		{
			for (int x = 0; x < w; x++)
			{
				let cell = ((x / cellSize) + (y / cellSize)) % 2 == 0;
				let c = cell ? c1 : c2;
				let offset = (y * w + x) * 4;
				data[offset] = c.R;
				data[offset + 1] = c.G;
				data[offset + 2] = c.B;
				data[offset + 3] = c.A;
			}
		}
		return new OwnedImageData((.)w, (.)h, .RGBA8, data);
	}
}

/// Small text label with a specific color, used as a prefix View in NumericField.
class ColoredLabel : View
{
	private String mText ~ delete _;
	private Color mColor;

	public this(StringView text, Color color)
	{
		mText = new String(text);
		mColor = color;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		float w = 12, h = fontSize;
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				w = font.Font.MeasureString(mText);
				h = font.Font.Metrics.LineHeight;
			}
		}
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = ctx.FontService?.GetFont(fontSize);
		if (font != null)
			ctx.VG.DrawText(mText, font, .(0, 0, Width, Height), .Center, .Middle, mColor);
	}
}

/// Simple colored rectangle view for layout demos.
class ColorBox : View
{
	public Color Color;
	private float mDesiredW;
	private float mDesiredH;

	public this(Color color, float desiredW = 0, float desiredH = 0)
	{
		Color = color;
		mDesiredW = desiredW;
		mDesiredH = desiredH;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = (mDesiredW > 0) ? mDesiredW : constraints.MaxWidth;
		let h = (mDesiredH > 0) ? mDesiredH : constraints.MaxHeight;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color);
	}
}

/// View that draws its background from the theme via StyleSheet.
/// Add a style class to match a theme rule (e.g., "panel").
class ThemedBox : View
{
	private float mDesiredW;
	private float mDesiredH;

	public this(StringView styleClass, float desiredW = 0, float desiredH = 0)
	{
		AddClass(styleClass);
		mDesiredW = desiredW;
		mDesiredH = desiredH;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = (mDesiredW > 0) ? mDesiredW : constraints.MaxWidth;
		let h = (mDesiredH > 0) ? mDesiredH : constraints.MaxHeight;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Try drawable from stylesheet first.
		let drawable = ResolveStyleDrawable(.Background);
		if (drawable != null)
		{
			drawable.Draw(ctx, bounds, GetControlState());
			return;
		}

		// Fallback: fill with resolved background color or surface.
		let bgColor = ResolveStyleColor(.TextColor, .(50, 52, 60, 255));
		ctx.VG.FillRect(bounds, Palette.Darken(bgColor, 0.7f));
	}
}

/// Demo area that shows a ContextMenu on right-click.
class ContextMenuDemoArea : View
{
	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(80));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let bg = ResolveStyleColor(.BorderColor, .(50, 55, 65, 255));
		ctx.VG.FillRoundedRect(bounds, 4, Palette.Darken(bg, 0.3f));
		ctx.VG.StrokeRoundedRect(bounds, 4, bg, 1);
		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(14);
			if (font != null)
				ctx.VG.DrawText("Right-click for context menu", font,
					bounds, .Center, .Middle, .(180, 185, 200, 255));
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Right && Context != null)
		{
			let menu = new ContextMenu();
			menu.AddItem("Cut", new () => {});
			menu.AddItem("Copy", new () => {});
			menu.AddItem("Paste", new () => {});
			menu.AddSeparator();
			let sub = menu.AddSubmenu("More");
			sub.Submenu.AddItem("Select All", new () => {});
			sub.Submenu.AddItem("Find", new () => {});
			sub.Submenu.AddSeparator();
			let nested = sub.Submenu.AddSubmenu("Even More");
			nested.Submenu.AddItem("Nested Item 1", new () => {});
			nested.Submenu.AddItem("Nested Item 2", new () => {});
			menu.AddSeparator();
			menu.AddItem("Disabled Item", new () => {}, false);

			let screenPos = LocalToScreen(.(e.X, e.Y));
			menu.Show(Context, screenPos.X, screenPos.Y);
			e.Handled = true;
		}
	}
}

/// Custom drag data carrying a reference to the source chip.
class ChipDragData : DragData
{
	public DragChip SourceChip;

	public this(DragChip source) : base("demo/chip")
	{
		SourceChip = source;
	}
}

/// Draggable colored chip implementing IDragSource.
class DragChip : ColorView, IDragSource
{
	public this(Color color) : base(color, 30, 30) { }

	public DragData CreateDragData()
	{
		return new ChipDragData(this);
	}

	public View CreateDragVisual(DragData data)
	{
		let panel = new Panel();
		panel.Padding = .(6, 2);
		let label = new Label(scope String()..AppendF("#{0:X2}{1:X2}{2:X2}", Color.Value.R, Color.Value.G, Color.Value.B));
		panel.AddView(label);
		return panel;
	}

	public void OnDragStarted(DragData data) { Opacity = 0.4f; }
	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled) { Opacity = 1.0f; }
}

/// Container that accepts chip drops and reorders by swapping colors.
class ChipReorderContainer : FlexLayout, IDropTarget
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
			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (localX >= child.Bounds.X && localX < child.Bounds.X + child.Width)
				{
					if (let targetChip = child as DragChip)
					{
						if (targetChip !== sourceChip)
						{
							let tempColor = sourceChip.Color.Value;
							sourceChip.Color.Value = targetChip.Color.Value;
							targetChip.Color.Value = tempColor;
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
class ColorDropBox : View, IDropTarget
{
	private String mText = new .("Drop here") ~ delete _;
	private Color mBgColor = .(50, 55, 65, 255);

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(30));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		ctx.VG.FillRoundedRect(bounds, 4, mBgColor);
		ctx.VG.StrokeRoundedRect(bounds, 4, .(70, 75, 85, 255), 1);
		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(12);
			if (font != null)
				ctx.VG.DrawText(mText, font, bounds, .Center, .Middle, .(220, 225, 235, 255));
		}
	}

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		return (data.Format == "demo/chip") ? .Copy : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY) { mText.Set("Release!"); Invalidate(); }
	public void OnDragOver(DragData data, float localX, float localY) { }
	public void OnDragLeave(DragData data) { mText.Set("Drop here"); Invalidate(); }

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (let chipData = data as ChipDragData)
		{
			mBgColor = chipData.SourceChip.Color.Value;
			mText.Set("Dropped!");
			Invalidate();
		}
		return .Copy;
	}
}

/// Tree item view - renders text with depth-based indent.
/// Expand/collapse arrows are drawn by TreeView as an overlay.
class TreeItemView : View
{
	public String Text ~ delete _;
	public int32 Depth;
	private float mIndent = 20;

	public void Set(StringView text, int32 depth)
	{
		if (Text == null) Text = new String(text);
		else Text.Set(text);
		Depth = depth;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Text != null && Text.Length > 0 && ctx.FontService != null)
		{
			let textX = (Depth + 1) * mIndent;
			let textColor = ResolveStyleColor(.TextColor, .(220, 220, 230, 255));
			let font = ctx.FontService.GetFont(14);
			if (font != null)
				ctx.VG.DrawText(Text, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
		}
	}
}

/// Demo list adapter for ListView.
class DemoListAdapter : ListAdapterBase
{
	private int32 mCount;
	public this(int32 count) { mCount = count; }
	public override int32 ItemCount => mCount;
	public override View CreateView(int32 viewType) => new Label("");
	public override void BindView(View view, int32 position)
	{
		if (let label = view as Label)
			label.SetText(scope String()..AppendF("Item {}", position + 1));
	}
}

/// Demo tree adapter: 5 folders, each with 3 files, folder 0 has a subfolder with 2 files.
class DemoTreeAdapter : ITreeAdapter
{
	// Node IDs: folders = 0-4, files = 100+folderIdx*10+fileIdx
	// Subfolder of folder 0 = 50, files in subfolder = 500, 501
	public int32 RootCount => 5;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1) return 5;
		if (nodeId >= 0 && nodeId < 5) return (nodeId == 0) ? 4 : 3; // folder 0 has 3 files + 1 subfolder
		if (nodeId == 50) return 2; // subfolder
		return 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1) return childIndex;
		if (parentId >= 0 && parentId < 5)
		{
			if (parentId == 0 && childIndex == 3) return 50; // subfolder
			return 100 + parentId * 10 + childIndex;
		}
		if (parentId == 50) return 500 + childIndex;
		return -1;
	}

	public int32 GetDepth(int32 nodeId)
	{
		if (nodeId >= 500) return 2;
		if (nodeId >= 100 || nodeId == 50) return 1;
		return 0;
	}

	public bool HasChildren(int32 nodeId)
	{
		return (nodeId >= 0 && nodeId < 5) || nodeId == 50;
	}

	public View CreateView(int32 viewType) => new TreeItemView();

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let item = view as TreeItemView)
		{
			let text = scope String();
			if (HasChildren(nodeId))
				text.AppendF("Folder {}", nodeId);
			else
				text.AppendF("File {}", nodeId);
			item.Set(text, depth);
		}
	}
}

/// Demo grid adapter with colored cells.
class DemoGridAdapter : ListAdapterBase
{
	private int32 mCount;
	public this(int32 count) { mCount = count; }
	public override int32 ItemCount => mCount;
	public override View CreateView(int32 viewType) => new ColorView(.(100, 100, 100, 255), 0, 0);
	public override void BindView(View view, int32 position)
	{
		if (let cv = view as ColorView)
		{
			let r = (uint8)(60 + (position * 7) % 160);
			let g = (uint8)(80 + (position * 13) % 140);
			let b = (uint8)(100 + (position * 23) % 120);
			cv.Color.Value = .(r, g, b, 255);
		}
	}
}

/// Simple flat list that supports drag-to-reorder.
class ReorderableListAdapter : IReorderableTreeAdapter
{
	private List<String> mItems = new .() ~ { for (let s in _) delete s; delete _; };

	public this(Span<StringView> items)
	{
		for (let item in items)
			mItems.Add(new String(item));
	}

	public int32 RootCount => (int32)mItems.Count;
	public int32 GetChildCount(int32 nodeId) => (nodeId == -1) ? (int32)mItems.Count : 0;
	public int32 GetChildId(int32 parentId, int32 childIndex) => childIndex;
	public int32 GetDepth(int32 nodeId) => 0;
	public bool HasChildren(int32 nodeId) => false;

	public View CreateView(int32 viewType) => new Label("");

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let label = view as Label)
			if (nodeId >= 0 && nodeId < mItems.Count)
				label.SetText(mItems[nodeId]);
	}

	public bool CanMove(int32 fromPosition, int32 toPosition)
	{
		return fromPosition >= 0 && fromPosition < mItems.Count &&
			   toPosition >= 0 && toPosition <= mItems.Count &&
			   fromPosition != toPosition;
	}

	public void MoveItem(int32 fromPosition, int32 toPosition)
	{
		if (!CanMove(fromPosition, toPosition)) return;
		let item = mItems[fromPosition];
		mItems.RemoveAt(fromPosition);
		let insertAt = (toPosition > fromPosition) ? toPosition - 1 : toPosition;
		mItems.Insert(Math.Min(insertAt, mItems.Count), item);
	}
}

/// Button that provides rich tooltip content via ITooltipProvider.
class RichTooltipButton : Button, ITooltipProvider
{
	public this(StringView text) : base(text)
	{
		IsTooltipInteractive = true;
	}

	public View CreateTooltipContent()
	{
		let layout = new FlexLayout() { Direction = .Vertical, Spacing = 4 };
		layout.AddView(new Label("Rich Tooltip"));
		layout.AddView(new Separator());
		let tipLine1 = new Label("This tooltip has multiple lines,");
		tipLine1.AddClass("label-dim");
		layout.AddView(tipLine1);
		let tipLine2 = new Label("a separator, and custom content.");
		tipLine2.AddClass("label-dim");
		layout.AddView(tipLine2);
		let colorRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		colorRow.AddView(new ColorView(.(220, 60, 60, 255), 16, 16));
		colorRow.AddView(new ColorView(.(60, 180, 60, 255), 16, 16));
		colorRow.AddView(new ColorView(.(60, 60, 220, 255), 16, 16));
		layout.AddView(colorRow);
		return layout;
	}
}
