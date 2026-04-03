namespace GUISandbox;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;
using Sedulous.Imaging;
using Sedulous.Drawing;

/// Main shell for the GUISandbox with header bar and navigation.
/// Provides a professional UI shell with theme switching, scaling, and demo selection.
class MainShell
{
	private GUIContext mContext;
	private DockPanel mRoot ~ delete _;
	private Panel mContentArea;
	private UIElement mCurrentDemo /*~ delete _*/;
	private DemoType mCurrentDemoType = .FocusAndTheme;

	// Header controls for updating state
	private RadioButton mDarkThemeRadio;
	private RadioButton mLightThemeRadio;
	private RadioButton mGameThemeRadio;
	private RadioButton mScale08Radio;
	private RadioButton mScale10Radio;
	private RadioButton mScale15Radio;
	private ComboBox mDemoSelector;
	private TextBlock mFpsDisplay;

	// Demo instances with state
	private InteractiveControlsDemo mInteractiveDemo ~ delete _;
	private TextInputDemo mTextInputDemo ~ delete _;
	private ScrollingDemo mScrollingDemo ~ delete _;
	private ListControlsDemo mListControlsDemo ~ delete _;
	private TabNavigationDemo mTabNavigationDemo ~ delete _;
	private TreeViewDemo mTreeViewDemo ~ delete _;
	private PopupDialogDemo mPopupDialogDemo ~ delete _;
	private DragDropDemo mDragDropDemo ~ delete _;
	private MenuToolbarDemo mMenuToolbarDemo ~ delete _;
	private DockingDemo mDockingDemo ~ delete _;
	private DataDisplayDemo mDataDisplayDemo ~ delete _;
	private AnimationDemo mAnimationDemo ~ delete _;
	private TooltipsDemo mTooltipsDemo ~ delete _;

	// Demo images reference (not owned)
	private OwnedImageData mCheckerboard;
	private OwnedImageData mGradient;

	// Asset directory for theme loading
	private String mAssetDirectory = new .() ~ delete _;

	// Breeze theme radio button
	private RadioButton mBreezeThemeRadio;

	// Current Breeze theme reference (null if not active)
	private BreezeTheme mBreezeTheme;

	public this(GUIContext context, OwnedImageData checkerboard, OwnedImageData gradient, StringView assetDirectory)
	{
		mContext = context;
		mCheckerboard = checkerboard;
		mGradient = gradient;
		mAssetDirectory.Set(assetDirectory);
	}

	public UIElement Root => mRoot;

	public DemoType CurrentDemoType => mCurrentDemoType;

	/// Creates the main shell UI.
	public void Create()
	{
		mRoot = new DockPanel();
		// Set root background to theme's Background color for proper base layer
		mRoot.Background = mContext.Theme.Palette.Background;

		// Create header bar
		let header = CreateHeader();
		DockPanelProperties.SetDock(header, .Top);
		mRoot.AddChild(header);

		// Create content area
		mContentArea = new Panel();
		mContentArea.Margin = .(10, 10, 10, 10);
		mRoot.AddChild(mContentArea);

		// Load initial demo
		SwitchDemo(.FocusAndTheme);
	}

	/// Creates the header bar with theme/scale controls and demo selector.
	private Border CreateHeader()
	{
		let header = new Border();
		header.Height = 50;
		// Header uses SurfaceVariant for slight elevation from main content

		let layout = new StackPanel();
		layout.Orientation = .Horizontal;
		layout.VerticalAlignment = .Center;
		layout.Margin = .(10, 0, 10, 0);
		header.Child = layout;

		// Title
		let title = new TextBlock("Sedulous.GUI Sandbox");
		title.FontSize = 18;
		title.VerticalAlignment = .Center;
		title.Margin = .(0, 0, 30, 0);
		layout.AddChild(title);

		// Demo selector
		let demoLabel = new TextBlock("Demo:");
		demoLabel.VerticalAlignment = .Center;
		demoLabel.Margin = .(0, 0, 8, 0);
		layout.AddChild(demoLabel);

		mDemoSelector = new ComboBox();
		mDemoSelector.Width = 180;
		mDemoSelector.VerticalAlignment = .Center;
		mDemoSelector.Margin = .(0, 0, 30, 0);
		AddDemoItems(mDemoSelector);
		mDemoSelector.SelectedIndex = 0;
		mDemoSelector.SelectionChanged.Subscribe(new => OnDemoSelectionChanged);
		layout.AddChild(mDemoSelector);

		// Theme selector
		let themeLabel = new TextBlock("Theme:");
		themeLabel.VerticalAlignment = .Center;
		themeLabel.Margin = .(0, 0, 8, 0);
		layout.AddChild(themeLabel);

		mDarkThemeRadio = new RadioButton("Dark");
		mDarkThemeRadio.GroupName = "Theme";
		mDarkThemeRadio.IsChecked = true;
		mDarkThemeRadio.VerticalAlignment = .Center;
		mDarkThemeRadio.Margin = .(0, 0, 8, 0);
		mDarkThemeRadio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnThemeChanged(.Dark); });
		layout.AddChild(mDarkThemeRadio);

		mLightThemeRadio = new RadioButton("Light");
		mLightThemeRadio.GroupName = "Theme";
		mLightThemeRadio.VerticalAlignment = .Center;
		mLightThemeRadio.Margin = .(0, 0, 8, 0);
		mLightThemeRadio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnThemeChanged(.Light); });
		layout.AddChild(mLightThemeRadio);

		mGameThemeRadio = new RadioButton("Game");
		mGameThemeRadio.GroupName = "Theme";
		mGameThemeRadio.VerticalAlignment = .Center;
		mGameThemeRadio.Margin = .(0, 0, 8, 0);
		mGameThemeRadio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnThemeChanged(.Game); });
		layout.AddChild(mGameThemeRadio);

		mBreezeThemeRadio = new RadioButton("Breeze");
		mBreezeThemeRadio.GroupName = "Theme";
		mBreezeThemeRadio.VerticalAlignment = .Center;
		mBreezeThemeRadio.Margin = .(0, 0, 30, 0);
		mBreezeThemeRadio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnThemeChanged(.Breeze); });
		layout.AddChild(mBreezeThemeRadio);

		// Scale selector
		let scaleLabel = new TextBlock("Scale:");
		scaleLabel.VerticalAlignment = .Center;
		scaleLabel.Margin = .(0, 0, 8, 0);
		layout.AddChild(scaleLabel);

		mScale08Radio = new RadioButton("0.8x");
		mScale08Radio.GroupName = "Scale";
		mScale08Radio.VerticalAlignment = .Center;
		mScale08Radio.Margin = .(0, 0, 8, 0);
		mScale08Radio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnScaleChanged(0.8f); });
		layout.AddChild(mScale08Radio);

		mScale10Radio = new RadioButton("1.0x");
		mScale10Radio.GroupName = "Scale";
		mScale10Radio.IsChecked = true;
		mScale10Radio.VerticalAlignment = .Center;
		mScale10Radio.Margin = .(0, 0, 8, 0);
		mScale10Radio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnScaleChanged(1.0f); });
		layout.AddChild(mScale10Radio);

		mScale15Radio = new RadioButton("1.5x");
		mScale15Radio.GroupName = "Scale";
		mScale15Radio.VerticalAlignment = .Center;
		mScale15Radio.Margin = .(0, 0, 30, 0);
		mScale15Radio.Checked.Subscribe(new (rb, isChecked) => { if (isChecked) OnScaleChanged(1.5f); });
		layout.AddChild(mScale15Radio);

		// FPS display (right-aligned with spacer)
		let spacer = new Panel();
		spacer.HorizontalAlignment = .Stretch;
		spacer.Width = 0; // Will stretch to fill
		layout.AddChild(spacer);

		mFpsDisplay = new TextBlock("FPS: --");
		// Keep green for FPS - it's an intentional highlight color
		mFpsDisplay.Foreground = Color(50, 180, 50, 255);
		mFpsDisplay.VerticalAlignment = .Center;
		mFpsDisplay.Margin = .(0, 0, 10, 0);
		layout.AddChild(mFpsDisplay);

		// Debug toggle button
		let debugBtn = new Button("Debug (F2)");
		debugBtn.VerticalAlignment = .Center;
		debugBtn.Click.Subscribe(new (btn) => ToggleDebug());
		layout.AddChild(debugBtn);

		return header;
	}

	/// Adds all demo items to the combo box.
	private void AddDemoItems(ComboBox combo)
	{
		combo.AddItem("Focus & Theme");      // 0
		combo.AddItem("StackPanel");         // 1
		combo.AddItem("Grid");               // 2
		combo.AddItem("Canvas");             // 3
		combo.AddItem("DockPanel");          // 4
		combo.AddItem("WrapPanel");          // 5
		combo.AddItem("SplitPanel");         // 6
		combo.AddItem("Display Controls");   // 7
		combo.AddItem("Interactive Controls"); // 8
		combo.AddItem("Text Input");         // 9
		combo.AddItem("Scrolling");          // 10
		combo.AddItem("List Controls");      // 11
		combo.AddItem("Tab Navigation");     // 12
		combo.AddItem("TreeView");           // 13
		combo.AddItem("Popup & Dialog");     // 14
		combo.AddItem("Drag and Drop");      // 15
		combo.AddItem("Menu & Toolbar");     // 16
		combo.AddItem("Docking");            // 17
		combo.AddItem("Data Display");       // 18
		combo.AddItem("Animation");          // 19
		combo.AddItem("Tooltips");           // 20
	}

	private void OnDemoSelectionChanged(ComboBox combo)
	{
		let index = combo.SelectedIndex;
		if (index < 0) return;

		DemoType demo = .FocusAndTheme;
		switch (index)
		{
		case 0: demo = .FocusAndTheme;
		case 1: demo = .StackPanel;
		case 2: demo = .Grid;
		case 3: demo = .Canvas;
		case 4: demo = .DockPanel;
		case 5: demo = .WrapPanel;
		case 6: demo = .SplitPanel;
		case 7: demo = .DisplayControls;
		case 8: demo = .InteractiveControls;
		case 9: demo = .TextInput;
		case 10: demo = .Scrolling;
		case 11: demo = .ListControls;
		case 12: demo = .TabNavigation;
		case 13: demo = .TreeView;
		case 14: demo = .PopupDialog;
		case 15: demo = .DragDrop;
		case 16: demo = .MenuToolbar;
		case 17: demo = .Docking;
		case 18: demo = .DataDisplay;
		case 19: demo = .Animation;
		case 20: demo = .Tooltips;
		}

		if (demo != mCurrentDemoType)
			SwitchDemo(demo);
	}

	private void OnThemeChanged(ThemeType theme)
	{
		switch (theme)
		{
		case .Dark:
			mContext.Theme = new DarkTheme();
			mBreezeTheme = null;
		case .Light:
			mContext.Theme = new LightTheme();
			mBreezeTheme = null;
		case .Game:
			mContext.Theme = new GameTheme();
			mBreezeTheme = null;
		case .Breeze:
			let breeze = new BreezeTheme(mAssetDirectory);
			mContext.Theme = breeze;
			mBreezeTheme = breeze;
		}

		// Update root background to match the new theme
		if (mRoot != null)
			mRoot.Background = mContext.Theme.Palette.Background;

		// Apply/clear per-instance image properties across the visual tree
		ApplyPerInstanceImages(mRoot);
	}

	private void OnScaleChanged(float scale)
	{
		mContext.ScaleFactor = scale;
	}

	private void ToggleDebug()
	{
		if (mContext.DebugSettings.ShowLayoutBounds)
			mContext.DebugSettings = .Default;
		else
			mContext.DebugSettings = .() { ShowLayoutBounds = true, ShowFocused = true, ShowHovered = true };
	}

	/// Updates FPS display.
	public void UpdateFps(int fps)
	{
		if (mFpsDisplay != null)
			mFpsDisplay.Text = scope $"FPS: {fps}";
	}

	/// Switches to a different demo.
	public void SwitchDemo(DemoType demo)
	{
		if (mCurrentDemo != null)
		{
			mContentArea.RemoveChild(mCurrentDemo);
			mContext.QueueDelete(mCurrentDemo);
			//delete mCurrentDemo;
			mCurrentDemo = null;
		}

		// Clean up demo instances when switching away
		CleanupDemoInstances(demo);

		mCurrentDemoType = demo;

		// Create new demo
		mCurrentDemo = CreateDemo(demo);

		if (mCurrentDemo != null)
		{
			mContentArea.AddChild(mCurrentDemo);

			// Apply per-instance images if Breeze theme is active
			if (mBreezeTheme != null)
				ApplyPerInstanceImages(mCurrentDemo);
		}

		// Update combo box selection if needed
		if (mDemoSelector != null)
		{
			int targetIndex = GetDemoIndex(demo);
			if (mDemoSelector.SelectedIndex != targetIndex)
				mDemoSelector.SelectedIndex = targetIndex;
		}
	}

	private int GetDemoIndex(DemoType demo)
	{
		switch (demo)
		{
		case .FocusAndTheme: return 0;
		case .StackPanel: return 1;
		case .Grid: return 2;
		case .Canvas: return 3;
		case .DockPanel: return 4;
		case .WrapPanel: return 5;
		case .SplitPanel: return 6;
		case .DisplayControls: return 7;
		case .InteractiveControls: return 8;
		case .TextInput: return 9;
		case .Scrolling: return 10;
		case .ListControls: return 11;
		case .TabNavigation: return 12;
		case .TreeView: return 13;
		case .PopupDialog: return 14;
		case .DragDrop: return 15;
		case .MenuToolbar: return 16;
		case .Docking: return 17;
		case .DataDisplay: return 18;
		case .Animation: return 19;
		case .Tooltips: return 20;
		}
	}

	private UIElement CreateDemo(DemoType demo)
	{
		switch (demo)
		{
		case .FocusAndTheme:
			return FocusAndThemeDemo.Create();
		case .StackPanel:
			return LayoutDemos.CreateStackPanel();
		case .Grid:
			return LayoutDemos.CreateGrid();
		case .Canvas:
			return LayoutDemos.CreateCanvas();
		case .DockPanel:
			return LayoutDemos.CreateDockPanel();
		case .WrapPanel:
			return LayoutDemos.CreateWrapPanel();
		case .SplitPanel:
			return LayoutDemos.CreateSplitPanel();
		case .DisplayControls:
			return DisplayControlsDemo.Create(mCheckerboard, mGradient);
		case .InteractiveControls:
			if (mInteractiveDemo == null)
				mInteractiveDemo = new InteractiveControlsDemo();
			return mInteractiveDemo.Create();
		case .TextInput:
			if (mTextInputDemo == null)
				mTextInputDemo = new TextInputDemo();
			return mTextInputDemo.Create();
		case .Scrolling:
			if (mScrollingDemo == null)
				mScrollingDemo = new ScrollingDemo();
			return mScrollingDemo.CreateDemo();
		case .ListControls:
			if (mListControlsDemo == null)
				mListControlsDemo = new ListControlsDemo();
			return mListControlsDemo.CreateDemo();
		case .TabNavigation:
			if (mTabNavigationDemo == null)
				mTabNavigationDemo = new TabNavigationDemo();
			return mTabNavigationDemo.CreateDemo();
		case .TreeView:
			if (mTreeViewDemo == null)
				mTreeViewDemo = new TreeViewDemo();
			return mTreeViewDemo.CreateDemo(mCheckerboard);
		case .PopupDialog:
			if (mPopupDialogDemo == null)
				mPopupDialogDemo = new PopupDialogDemo();
			return mPopupDialogDemo.CreateDemo(mContext);
		case .DragDrop:
			if (mDragDropDemo == null)
				mDragDropDemo = new DragDropDemo();
			return mDragDropDemo.CreateDemo(mContext);
		case .MenuToolbar:
			if (mMenuToolbarDemo == null)
				mMenuToolbarDemo = new MenuToolbarDemo();
			return mMenuToolbarDemo.CreateDemo(mContext);
		case .Docking:
			if (mDockingDemo == null)
				mDockingDemo = new DockingDemo();
			return mDockingDemo.CreateDemo(mContext);
		case .DataDisplay:
			if (mDataDisplayDemo == null)
				mDataDisplayDemo = new DataDisplayDemo();
			return mDataDisplayDemo.CreateDemo();
		case .Animation:
			if (mAnimationDemo == null)
				mAnimationDemo = new AnimationDemo();
			return mAnimationDemo.CreateDemo();
		case .Tooltips:
			if (mTooltipsDemo == null)
				mTooltipsDemo = new TooltipsDemo();
			return mTooltipsDemo.CreateDemo();
		}
	}

	private void CleanupDemoInstances(DemoType newDemo)
	{
		if (newDemo != .InteractiveControls && mInteractiveDemo != null)
		{
			delete mInteractiveDemo;
			mInteractiveDemo = null;
		}
		if (newDemo != .TextInput && mTextInputDemo != null)
		{
			delete mTextInputDemo;
			mTextInputDemo = null;
		}
		if (newDemo != .Scrolling && mScrollingDemo != null)
		{
			delete mScrollingDemo;
			mScrollingDemo = null;
		}
		if (newDemo != .ListControls && mListControlsDemo != null)
		{
			delete mListControlsDemo;
			mListControlsDemo = null;
		}
		if (newDemo != .TabNavigation && mTabNavigationDemo != null)
		{
			delete mTabNavigationDemo;
			mTabNavigationDemo = null;
		}
		if (newDemo != .TreeView && mTreeViewDemo != null)
		{
			delete mTreeViewDemo;
			mTreeViewDemo = null;
		}
		if (newDemo != .PopupDialog && mPopupDialogDemo != null)
		{
			delete mPopupDialogDemo;
			mPopupDialogDemo = null;
		}
		if (newDemo != .DragDrop && mDragDropDemo != null)
		{
			delete mDragDropDemo;
			mDragDropDemo = null;
		}
		if (newDemo != .MenuToolbar && mMenuToolbarDemo != null)
		{
			delete mMenuToolbarDemo;
			mMenuToolbarDemo = null;
		}
		if (newDemo != .Docking && mDockingDemo != null)
		{
			delete mDockingDemo;
			mDockingDemo = null;
		}
		if (newDemo != .DataDisplay && mDataDisplayDemo != null)
		{
			delete mDataDisplayDemo;
			mDataDisplayDemo = null;
		}
		if (newDemo != .Animation && mAnimationDemo != null)
		{
			delete mAnimationDemo;
			mAnimationDemo = null;
		}
		if (newDemo != .Tooltips && mTooltipsDemo != null)
		{
			delete mTooltipsDemo;
			mTooltipsDemo = null;
		}
	}

	/// Recursively applies or clears per-instance image properties on all controls in the tree.
	/// When Breeze theme is active, sets CheckedImage, ThumbImage, etc. from the theme.
	/// When any other theme is active, clears those properties so fallback rendering is used.
	private void ApplyPerInstanceImages(UIElement element)
	{
		if (element == null)
			return;

		if (let control = element as Control)
		{
			if (mBreezeTheme != null)
				mBreezeTheme.ApplyToControl(control);
			else
				ClearPerInstanceImages(control);
		}

		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
				ApplyPerInstanceImages(child);
		}
	}

	/// Clears per-instance image properties on a control (used when switching away from Breeze).
	private static void ClearPerInstanceImages(Control control)
	{
		if (let cb = control as CheckBox)
		{
			cb.CheckedImage = null;
			cb.UncheckedImage = null;
		}
		else if (let rb = control as RadioButton)
		{
			rb.SelectedImage = null;
			rb.UnselectedImage = null;
		}
		else if (let pb = control as ProgressBar)
		{
			pb.FillImage = null;
		}
		else if (let sb = control as ScrollBar)
		{
			sb.ThumbImage = null;
		}
		else if (let slider = control as Slider)
		{
			slider.ThumbImage = null;
		}
		else if (let combo = control as ComboBox)
		{
			combo.ArrowImage = null;
		}
		else if (let lbi = control as ListBoxItem)
		{
			lbi.SelectionImage = null;
			lbi.HoverImage = null;
		}
	}

	/// Toggles debug mode.
	public void ToggleDebugMode()
	{
		ToggleDebug();
	}
}

/// Theme type enumeration.
enum ThemeType
{
	Dark,
	Light,
	Game,
	Breeze
}
