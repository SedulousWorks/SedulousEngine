namespace TowerDefense;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Full-screen pause overlay with Resume and Main Menu buttons.
class PauseUI
{
	private Panel mRoot; // Owned by view tree (parent deletes)
	public delegate void() OnResume ~ delete _;
	public delegate void() OnMainMenu ~ delete _;

	public Panel Root => mRoot;

	public void Setup(RootView root, delegate void() onResume, delegate void() onMainMenu)
	{
		OnResume = onResume;
		OnMainMenu = onMainMenu;

		// Full-screen dark overlay
		mRoot = new Panel();
		mRoot.Background = new ColorDrawable(.(0, 0, 0, 180));
		mRoot.IsHitTestVisible = true;
		mRoot.Visibility = .Gone;

		// Centered content
		let content = new FlexLayout();
		content.Direction = .Vertical;
		content.Spacing = 16;
		content.AlignItems = .Center;
		content.JustifyContent = .Center;
		mRoot.AddView(content, new LayoutParams() { Width = .Match, Height = .Match });

		// Title
		let title = new Label("PAUSED");
		title.FontSize.Value = 28;
		title.TextColor.Value = .(220, 230, 240, 255);
		title.HAlign.Value = .Center;
		content.AddView(title);

		content.AddView(new Spacer(0, 12));

		// Resume button
		let resumeBtn = new Button("Resume");
		resumeBtn.FontSize.Value = 16;
		resumeBtn.Background = new ColorDrawable(.(40, 120, 60, 255));
		resumeBtn.OnClick.Add(new (btn) =>
			{
				if (OnResume != null) OnResume();
			});
		content.AddView(resumeBtn);

		// Main Menu button
		let menuBtn = new Button("Main Menu");
		menuBtn.FontSize.Value = 16;
		menuBtn.Background = new ColorDrawable(.(120, 50, 50, 255));
		menuBtn.OnClick.Add(new (btn) =>
			{
				if (OnMainMenu != null) OnMainMenu();
			});
		content.AddView(menuBtn);

		// Add to view tree immediately - view tree owns mRoot
		root.AddView(mRoot, new LayoutParams() { Width = .Match, Height = .Match });
	}

	public void Show()
	{
		mRoot.Visibility = .Visible;
	}

	public void Hide()
	{
		mRoot.Visibility = .Gone;
	}
}
