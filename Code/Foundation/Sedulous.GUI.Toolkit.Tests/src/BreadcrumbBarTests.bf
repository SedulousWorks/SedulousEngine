using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A bar 400 wide at the root's top-left, over a path of five segments.
class BreadcrumbBed
{
	public CachedFont Font = new .(new SixFont(), null) ~ delete _; // outlives the widgets
	public SceneRoot Root ~ _.ReleaseRef();
	public BreadcrumbBar Bar = new .() ~ _.ReleaseRef();
	public List<String> Went = new .() ~ DeleteContainerAndItems!(_);

	public this(float width = 400.0f)
	{
		Root = NewRoot(800.0f, 600.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Bar.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(width);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(Bar);
		Bar.SetPath("/home/robert/Projects/Game");
		Fonts();
		Bar.SetOnNavigate(new (item) => { Went.Add(new String(item.Id)); });
		Frame();
	}

	public ~this()
	{
		D.CloseAllPopups();
	}

	/// The mock font on what shows text (a font object is not inherited; a family name is, through a
	/// font service the bed has none of).
	public void Fonts()
	{
		Bar.OverflowButton.Font = Font;
		for (int i = 0; i < Bar.ItemCount; ++i)
			Bar.SegmentAt(i).Font = Font;
	}

	/// A frame: styles (the bar's font reaching its segments), then layout.
	public void Frame()
	{
		ToolkitFixtures.Frame(Root);
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static Float2 Middle(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	public void Click(Float2 at)
	{
		ToolkitFixtures.Click(D, at);
	}

	public void Key(KeyCode key)
	{
		D.InjectKeyDown((uint32)key);
	}

	/// The menu's items' texts, in order, into `outTexts`.
	public static void MenuTexts(Sedulous.GUI.Menu menu, List<String> outTexts)
	{
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
				outTexts.Add(new String(item.Text));
		}
	}

	public static MenuItem MenuItemAt(Sedulous.GUI.Menu menu, int at)
	{
		int n = 0;
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
			{
				if (n++ == at)
					return item;
			}
		}
		return null;
	}
}

/// The breadcrumb bar: segments carrying their target, from items or a path; a click navigating on
/// release, the current segment inert; the segments that do not fit folded from the root into a "…"
/// menu; one tab stop, the arrows moving along it; right to left, run the other way with the chevrons
/// turned. Its chevrons' menus of children, its segments' drops, and its path edited as text.
class BreadcrumbBarTests
{
	[Test]
	public static void SegmentsFromAPathEachCarryingThePathUpToItTheLastTheCurrentOne()
	{
		let bed = scope BreadcrumbBed();
		Test.Assert(bed.Bar.ItemCount == 5);
		Test.Assert(bed.Bar.ItemAt(0).Text == "/");
		Test.Assert(bed.Bar.ItemAt(0).Id == "/");
		Test.Assert(bed.Bar.ItemAt(2).Text == "robert");
		Test.Assert(bed.Bar.ItemAt(2).Id == "/home/robert");
		Test.Assert(bed.Bar.ItemAt(2).Tooltip == "/home/robert");
		Test.Assert(bed.Bar.ItemAt(4).Id == "/home/robert/Projects/Game");
		Test.Assert(bed.Bar.SegmentAt(4).HasClass("current"));
		Test.Assert(!bed.Bar.SegmentAt(3).HasClass("current"));
		Test.Assert(bed.Bar.SegmentAt(4).AccessDescription == "current");
		Test.Assert(bed.Bar.SegmentAt(3).AccessDescription.IsEmpty);

		// A drive is a segment of its own; empty parts are skipped.
		bed.Bar.SetPath("C:/Users//me/");
		Test.Assert(bed.Bar.ItemCount == 3);
		Test.Assert(bed.Bar.ItemAt(0).Text == "C:");
		Test.Assert(bed.Bar.ItemAt(1).Id == "C:/Users");
		Test.Assert(bed.Bar.ItemAt(2).Id == "C:/Users//me");

		// Given items, as they are (an icon and a tooltip the application's).
		let content = scope BreadcrumbItem("g1", "Content", "All content");
		let models = scope BreadcrumbItem("g7", "models");
		BreadcrumbItem[2] items = .(content, models);
		bed.Bar.SetItems(items);
		bed.Frame();
		Test.Assert(bed.Bar.ItemCount == 2);
		Test.Assert(bed.Bar.SegmentAt(0).TooltipText == "All content");
		Test.Assert(bed.Bar.SegmentAt(1).HasClass("current"));
	}

	[Test]
	public static void AClickNavigatesOnReleaseWithTheSegmentsItemTheCurrentSegmentIsInert()
	{
		let bed = scope BreadcrumbBed();
		let home = BreadcrumbBed.Middle(bed.Bar.SegmentAt(1));
		bed.D.InjectMouseMove(home);
		bed.D.InjectMouseDown(home, .Left);
		Test.Assert(bed.Went.IsEmpty); // not on the press
		bed.D.InjectMouseUp(home, .Left);
		Test.Assert(bed.Went.Count == 1);
		Test.Assert(bed.Went[0] == "/home");

		bed.Click(BreadcrumbBed.Middle(bed.Bar.SegmentAt(4)));
		Test.Assert(bed.Went.Count == 1);
		Test.Assert(!bed.Bar.Navigate(4));
		Test.Assert(bed.Bar.Navigate(0));
		Test.Assert(bed.Went.Back == "/");

		// Laid out in order, a chevron between each two.
		for (int i = 1; i < 5; ++i)
		{
			Test.Assert(bed.Bar.SeparatorBefore(i).ScreenBounds.X >= bed.Bar.SegmentAt(i - 1).ScreenBounds.Right - 0.5f);
			Test.Assert(bed.Bar.SegmentAt(i).ScreenBounds.X >= bed.Bar.SeparatorBefore(i).ScreenBounds.Right - 0.5f);
		}
		Test.Assert(bed.Bar.FoldedCount == 0);
		Test.Assert(!bed.Bar.OverflowButton.Visible);
	}

	[Test]
	public static void WhatDoesNotFitFoldsFromTheRootIntoTheOverflowMenuTheCurrentSegmentKept()
	{
		let bed = scope BreadcrumbBed(150.0f);
		let folded = bed.Bar.FoldedCount;
		Test.Assert(folded > 0);
		Test.Assert(folded < 5);
		Test.Assert(bed.Bar.OverflowButton.Visible);
		for (int i = 0; i < folded; ++i)
			Test.Assert(!bed.Bar.SegmentAt(i).Visible);
		for (int i = folded; i < 5; ++i)
			Test.Assert(bed.Bar.SegmentAt(i).Visible);
		// Everything shown inside the bar, the "…" first.
		let barAt = bed.Bar.ContentBounds;
		Test.Assert(bed.Bar.SegmentAt(4).ScreenBounds.Right <= barAt.Right + 0.5f);
		Test.Assert(bed.Bar.OverflowButton.ScreenBounds.X < bed.Bar.SegmentAt(folded).ScreenBounds.X);

		// Its menu lists the folded ones; choosing one navigates there.
		bed.Click(BreadcrumbBed.Middle(bed.Bar.OverflowButton));
		let menu = bed.Bar.GetOpenMenu();
		Test.Assert(menu != null);
		int items = 0;
		MenuItem firstItem = null;
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
			{
				if (firstItem == null)
					firstItem = item;
				++items;
			}
		}
		Test.Assert(items == folded);
		Test.Assert(firstItem != null);
		Test.Assert(firstItem.Text == "/");
		firstItem.HandleActivate();
		Test.Assert(bed.Went.Count == 1);
		Test.Assert(bed.Went[0] == "/");

		// Too narrow for even the current one: it takes what is left.
		bed.Bar.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(60.0f); });
		bed.Frame();
		Test.Assert(bed.Bar.FoldedCount == 4);
		Test.Assert(bed.Bar.SegmentAt(4).ScreenBounds.Right <= bed.Bar.ScreenBounds.Right + 0.5f);
	}

	[Test]
	public static void OneTabStopTheCurrentSegmentLeftRightHomeAndEndMoveAlongItReturnNavigates()
	{
		let bed = scope BreadcrumbBed();
		for (int i = 0; i < 4; ++i)
			Test.Assert(!bed.Bar.SegmentAt(i).TabFocusable);
		Test.Assert(bed.Bar.SegmentAt(4).TabFocusable);
		bed.Bar.SegmentAt(4).RequestFocus();
		bed.Key(.Left);
		Test.Assert(bed.Bar.SegmentAt(3).IsFocused);
		Test.Assert(bed.Bar.SegmentAt(3).TabFocusable); // the tab stop goes with it
		Test.Assert(!bed.Bar.SegmentAt(4).TabFocusable);
		bed.Key(.Return);
		Test.Assert(bed.Went.Count == 1);
		Test.Assert(bed.Went[0] == "/home/robert/Projects");
		bed.Key(.Home);
		Test.Assert(bed.Bar.SegmentAt(0).IsFocused);
		bed.Key(.Left); // at the start, it stays
		Test.Assert(bed.Bar.SegmentAt(0).IsFocused);
		bed.Key(.End);
		Test.Assert(bed.Bar.SegmentAt(4).IsFocused);
		bed.Key(.Right);
		Test.Assert(bed.Bar.SegmentAt(4).IsFocused);
	}

	[Test]
	public static void RightToLeftItsSegmentsRunFromTheRightItsChevronsTurnedLeftTowardTheCurrentOne()
	{
		let bed = scope BreadcrumbBed();
		bed.Root.SetLayoutDirection(.RightToLeft);
		bed.Frame();
		Test.Assert(bed.Bar.SegmentAt(0).ScreenBounds.X > bed.Bar.SegmentAt(4).ScreenBounds.X);
		Test.Assert(bed.Bar.SegmentAt(0).ScreenBounds.Right <= bed.Bar.ScreenBounds.Right + 0.5f);
		Test.Assert(bed.Bar.SeparatorBefore(1).IsMirrored);
		bed.Bar.SegmentAt(2).RequestFocus();
		bed.Key(.Left); // toward the inline end
		Test.Assert(bed.Bar.SegmentAt(3).IsFocused);
	}

	[Test]
	public static void GivenChildrenAChevronOpensTheMenuOfTheSegmentBeforeItDownOnASegmentToo()
	{
		let bed = scope BreadcrumbBed();
		// Without a callback, the chevrons are marks a click passes through.
		Test.Assert(!bed.Bar.SeparatorBefore(2).HitTestVisible);
		let asked = scope List<String>();
		defer { ClearAndDeleteItems!(asked); }
		bed.Bar.SetOnChildren(new [&] (of, children) =>
			{
				asked.Add(new String(of.Id));
				children.Add(new BreadcrumbItem(scope String()..AppendF("{}/alpha", of.Id), "alpha"));
				children.Add(new BreadcrumbItem(scope String()..AppendF("{}/beta", of.Id), "beta"));
			});
		bed.Frame();
		Test.Assert(bed.Bar.SeparatorBefore(2).HitTestVisible);
		Test.Assert(bed.Bar.SeparatorBefore(2).HasClass("menu"));
		Test.Assert(bed.Bar.SeparatorBefore(2).Owner == 1);

		// The chevron between "home" and "robert" lists what lies in "home".
		bed.Click(BreadcrumbBed.Middle(bed.Bar.SeparatorBefore(2)));
		Test.Assert(asked.Count == 1);
		Test.Assert(asked[0] == "/home");
		let menu = bed.Bar.GetOpenMenu();
		Test.Assert(menu != null);
		let texts = scope List<String>();
		defer { ClearAndDeleteItems!(texts); }
		BreadcrumbBed.MenuTexts(menu, texts);
		Test.Assert(texts.Count == 2);
		Test.Assert(texts[1] == "beta");
		BreadcrumbBed.MenuItemAt(menu, 1).HandleActivate();
		Test.Assert(bed.Went.Count == 1);
		Test.Assert(bed.Went[0] == "/home/beta");
		Test.Assert(bed.Bar.GetOpenMenu() == null);

		// Down on the focused current segment lists its own children.
		bed.Bar.SegmentAt(4).RequestFocus();
		bed.Key(.Down);
		Test.Assert(asked.Count == 2);
		Test.Assert(asked[1] == "/home/robert/Projects/Game");
		Test.Assert(bed.Bar.GetOpenMenu() != null);
		bed.D.CloseAllPopups();

		// No children: no menu.
		bed.Bar.SetOnChildren(new (of, children) => { });
		Test.Assert(!bed.Bar.OpenChildren(1, bed.Bar.SeparatorBefore(2)));
	}

	[Test]
	public static void SegmentsButTheCurrentTakeDropsOfTheBarsTypesTheApplicationToldWhich()
	{
		let bed = scope BreadcrumbBed();
		let source = new Panel();
		defer source.ReleaseRef();
		source.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(60.0f);
				s.Height = LayoutLength.Px(40.0f);
			});
		let type = scope String("asset");
		source.SetDragSource(new [&] (r) =>
			{
				r.Payload.Type.Set(type);
				r.Payload.Label.Set("fox.glb");
				return true;
			});
		bed.Root.AddChild(source);
		bed.Frame();
		bed.Bar.SetSegmentDropTypes("asset files");
		let dropped = scope List<String>();
		defer { ClearAndDeleteItems!(dropped); }
		bed.Bar.SetOnSegmentDrop(new [&] (item, payload, effect) =>
			{
				dropped.Add(new String()..AppendF("{} <- {}", item.Id, payload.Label));
			});
		void DragTo(Float2 to)
		{
			let from = BreadcrumbBed.Middle(source);
			bed.D.InjectMouseMove(from);
			bed.D.InjectMouseDown(from, .Left);
			bed.D.InjectMouseMove(.(from.X + 10.0f, from.Y));
			bed.D.InjectMouseMove(to);
			bed.D.InjectMouseMove(.(to.X + 1.0f, to.Y));
			bed.D.InjectMouseUp(.(to.X + 1.0f, to.Y), .Left);
		}
		DragTo(BreadcrumbBed.Middle(bed.Bar.SegmentAt(1)));
		Test.Assert(dropped.Count == 1);
		Test.Assert(dropped[0] == "/home <- fox.glb");
		DragTo(BreadcrumbBed.Middle(bed.Bar.SegmentAt(4))); // the current one takes none
		Test.Assert(dropped.Count == 1);
		type.Set("colour"); // nor a type not the bar's
		DragTo(BreadcrumbBed.Middle(bed.Bar.SegmentAt(2)));
		Test.Assert(dropped.Count == 1);
	}

	[Test]
	public static void WhereEditableAClickOnItsEmptyEndEditsThePathReturnGivesItEscapeLeavesIt()
	{
		let bed = scope BreadcrumbBed();
		let end = Float2(bed.Bar.ScreenBounds.Right - 6.0f, BreadcrumbBed.Middle(bed.Bar).Y);
		bed.Click(end);
		Test.Assert(!bed.Bar.IsEditingPath); // not editable by default

		bed.Bar.IsPathEditable = true;
		let typed = scope List<String>();
		defer { ClearAndDeleteItems!(typed); }
		bed.Bar.SetOnPathSubmitted(new [&] (text) => { typed.Add(new String(text)); });
		bed.Click(end);
		Test.Assert(bed.Bar.IsEditingPath);
		let field = bed.Bar.PathField;
		Test.Assert(field != null);
		field.Font = bed.Font;
		bed.Frame();
		Test.Assert(field.Text == "/home/robert/Projects/Game");
		Test.Assert(field.SelectedText == "/home/robert/Projects/Game");
		Test.Assert(field.IsFocused);
		Test.Assert(!bed.Bar.SegmentAt(4).Visible);
		CheckNear(field.Size.X, bed.Bar.ContentBounds.Width);

		bed.D.InjectText("/tmp/x");
		bed.Key(.Return);
		Test.Assert(!bed.Bar.IsEditingPath);
		Test.Assert(typed.Count == 1);
		Test.Assert(typed[0] == "/tmp/x");
		bed.Frame();
		Test.Assert(bed.Bar.SegmentAt(4).Visible);
		Test.Assert(bed.Bar.SegmentAt(4).IsFocused); // focus back on the bar's tab stop

		// Escape puts the segments back, giving nothing.
		bed.Bar.BeginPathEdit();
		bed.D.InjectText("nowhere");
		bed.Key(.Escape);
		Test.Assert(!bed.Bar.IsEditingPath);
		Test.Assert(typed.Count == 1);
	}

	[Test]
	public static void AnElementMarkupPlaces()
	{
		let made = Load("<Panel><BreadcrumbBar/></Panel>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		Test.Assert(made.ChildCount == 1);
		Test.Assert(made.GetChildAt(0) is BreadcrumbBar);
	}

	// Further cases: a path edit ended from code, submitted or not, and the overflow
	// opened from code.
	[Test]
	public static void APathEditEndedFromCodeGivesItsTextOnlyWhenSubmitted()
	{
		let bed = scope BreadcrumbBed();
		bed.Bar.IsPathEditable = true;
		let typed = scope List<String>();
		defer { ClearAndDeleteItems!(typed); }
		bed.Bar.SetOnPathSubmitted(new [&] (text) => { typed.Add(new String(text)); });
		bed.Bar.BeginPathEdit();
		Test.Assert(bed.Bar.IsEditingPath);
		bed.Bar.EndPathEdit(false);
		Test.Assert(!bed.Bar.IsEditingPath);
		Test.Assert(typed.IsEmpty);
		bed.Bar.BeginPathEdit();
		bed.Bar.EndPathEdit(true);
		Test.Assert(typed.Count == 1);
		Test.Assert(typed[0] == "/home/robert/Projects/Game");
	}
}
