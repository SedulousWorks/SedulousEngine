namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;
using Sedulous.Imaging;

/// Demo 13: Tree & Hierarchical Controls
/// Shows TreeView, TreeViewItem, TileView, and TileViewItem.
class TreeViewDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mTreeStatusLabel /*~ delete _*/;
	private TextBlock mTileStatusLabel /*~ delete _*/;
	private TreeView mTreeView /*~ delete _*/;
	private TileView mTileView /*~ delete _*/;
	private OwnedImageData mTileImage;

	public UIElement CreateDemo(OwnedImageData tileImage)
	{
		mTileImage = tileImage;

		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 70, 20, 20);

		// Title
		let title = new TextBlock("Tree & Hierarchical Controls Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// TreeView section
		CreateTreeViewSection();

		// TileView section
		CreateTileViewSection();

		// Instructions
		let instructions = new TextBlock("TreeView: Up/Down navigate, Left/Right expand/collapse, Home/End, Space/Enter toggle\nTileView: Arrow keys navigate grid, Home/End for first/last");
		mRoot.AddChild(instructions);

		return mRoot;
	}

	private void CreateTreeViewSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("TreeView - Hierarchical Data");
		header.FontSize = 16;
		section.AddChild(header);

		// Control buttons row
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 10;

		let expandAllBtn = new Button("Expand All");
		expandAllBtn.Click.Subscribe(new (b) => mTreeView.ExpandAll());
		buttonRow.AddChild(expandAllBtn);

		let collapseAllBtn = new Button("Collapse All");
		collapseAllBtn.Click.Subscribe(new (b) => mTreeView.CollapseAll());
		buttonRow.AddChild(collapseAllBtn);

		section.AddChild(buttonRow);

		// Create TreeView
		mTreeView = new TreeView();
		mTreeView.Width = 350;
		mTreeView.Height = 200;

		// Create a file system-like structure
		let documents = mTreeView.AddItem("Documents");
		documents.AddChild("Resume.docx");
		documents.AddChild("CoverLetter.docx");
		let projects = documents.AddChild("Projects");
		projects.AddChild("Project1.txt");
		projects.AddChild("Project2.txt");
		let archives = projects.AddChild("Archives");
		archives.AddChild("OldProject.zip");

		let pictures = mTreeView.AddItem("Pictures");
		pictures.AddChild("Vacation.jpg");
		pictures.AddChild("Family.jpg");
		let screenshots = pictures.AddChild("Screenshots");
		screenshots.AddChild("Screenshot1.png");
		screenshots.AddChild("Screenshot2.png");

		let music = mTreeView.AddItem("Music");
		music.AddChild("Song1.mp3");
		music.AddChild("Song2.mp3");
		let playlists = music.AddChild("Playlists");
		playlists.AddChild("Favorites.m3u");
		playlists.AddChild("Workout.m3u");

		// Status label
		mTreeStatusLabel = new TextBlock("Click an item to select");

		mTreeView.SelectionChanged.Subscribe(new (tv) => {
			if (tv.SelectedItem != null)
				mTreeStatusLabel.Text = scope $"Selected: {tv.SelectedItem.Text}";
			else
				mTreeStatusLabel.Text = "No selection";
		});

		mTreeView.ItemExpanded.Subscribe(new (tv, item) => {
			mTreeStatusLabel.Text = scope $"Expanded: {item.Text}";
		});

		mTreeView.ItemCollapsed.Subscribe(new (tv, item) => {
			mTreeStatusLabel.Text = scope $"Collapsed: {item.Text}";
		});

		section.AddChild(mTreeView);
		section.AddChild(mTreeStatusLabel);

		mRoot.AddChild(section);
	}

	private void CreateTileViewSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("TileView - Icon Grid (Content-based tiles with Image + TextBlock)");
		header.FontSize = 16;
		section.AddChild(header);

		// Tile size controls
		let sizeRow = new StackPanel();
		sizeRow.Orientation = .Horizontal;
		sizeRow.Spacing = 10;

		let sizeLabel = new TextBlock("Tile Size:");
		sizeRow.AddChild(sizeLabel);

		let smallBtn = new Button("Small");
		smallBtn.Click.Subscribe(new (b) => {
			mTileView.TileWidth = 60;
			mTileView.TileHeight = 70;
		});
		sizeRow.AddChild(smallBtn);

		let mediumBtn = new Button("Medium");
		mediumBtn.Click.Subscribe(new (b) => {
			mTileView.TileWidth = 80;
			mTileView.TileHeight = 90;
		});
		sizeRow.AddChild(mediumBtn);

		let largeBtn = new Button("Large");
		largeBtn.Click.Subscribe(new (b) => {
			mTileView.TileWidth = 100;
			mTileView.TileHeight = 110;
		});
		sizeRow.AddChild(largeBtn);

		section.AddChild(sizeRow);

		// Create TileView
		mTileView = new TileView();
		mTileView.Width = 500;
		mTileView.Height = 250;

		// Add tiles with Image + TextBlock content
		String[?] folderNames = .("Documents", "Pictures", "Music", "Videos", "Downloads", "Desktop", "Projects", "Backup", "Config", "Temp", "Archive", "Notes");
		for (let name in folderNames)
		{
			AddTileWithImage(name);
		}

		// Status label
		mTileStatusLabel = new TextBlock("Click a tile to select");

		mTileView.SelectionChanged.Subscribe(new (tv) => {
			if (tv.SelectedItem != null)
			{
				// Get the text from the content if it's a StackPanel with TextBlock
				StringView itemName = "Unknown";
				if (let stack = tv.SelectedItem.Content as StackPanel)
				{
					if (stack.ChildCount >= 2)
					{
						if (let textBlock = stack.GetChild(1) as TextBlock)
							itemName = textBlock.Text;
					}
				}
				mTileStatusLabel.Text = scope $"Selected: {itemName} (index {tv.SelectedItem.Index})";
			}
			else
				mTileStatusLabel.Text = "No selection";
		});

		section.AddChild(mTileView);
		section.AddChild(mTileStatusLabel);

		mRoot.AddChild(section);
	}

	/// Creates a tile with Image on top and TextBlock below.
	private void AddTileWithImage(StringView name)
	{
		let item = mTileView.AddItem();

		// Create a vertical stack with image and text
		let stack = new StackPanel();
		stack.Orientation = .Vertical;
		stack.Spacing = 4;
		stack.HorizontalAlignment = .Center;
		stack.VerticalAlignment = .Center;

		// Add image (thumbnail preview)
		let image = new Sedulous.GUI.Image(mTileImage);
		image.Stretch = .Uniform;
		image.Width = 40;
		image.Height = 40;
		image.HorizontalAlignment = .Center;
		stack.AddChild(image);

		// Add text label
		let textBlock = new TextBlock(name);
		textBlock.FontSize = 10;
		textBlock.TextAlignment = .Center;
		textBlock.HorizontalAlignment = .Center;
		stack.AddChild(textBlock);

		item.Content = stack;
	}
}
