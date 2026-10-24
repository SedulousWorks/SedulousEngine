using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// StyleManager tests: a StyleSheet applied live to a widget tree, including the end-to-end
// showcase where hovering re-resolves :hover rules and drives a CSS transition through the
// ActionManager.

/// The style manager: a sheet live on a tree, its origins, what a rule gives back, code over the
/// sheet, forced states, where a value came from, and what a change restyles.
class StyleManagerTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new widget tagged `tag` at `pos`, `size`, held by the caller.
	private static UIWidget NewTagged(StringView tag, Float2 pos, Float2 size)
	{
		let w = new UIWidget();
		w.Tag = tag;
		w.Position = pos;
		w.Size = size;
		return w;
	}

	/// A new widget tagged `tag` (of the class `cls` when one is given), the last child of
	/// `parent`, held by the caller.
	private static UIWidget Tagged(Node parent, StringView tag, StringView cls = default)
	{
		let w = new UIWidget();
		w.Tag = tag;
		if (cls.Length != 0)
			w.AddClass(cls);
		parent.AddChild(w);
		return w;
	}

	/// A sheet parsed from `css` (named `name` when given), held by the caller's scope.
	private static StyleSheet Sheet(StringView css, StyleSheet outSheet, StringView name = default)
	{
		CSSParser.Parse(css, name, outSheet);
		return outSheet;
	}

	[Test]
	public static void AppliesASheetAcrossTheTree()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer btn.ReleaseRef();
		root.AddChild(btn);

		let mgr = scope StyleManager(Sheet("button { opacity: 0.5; background-color: red; }", scope StyleSheet()));
		mgr.ApplyTree(root);

		Test.Assert(Near(btn.Alpha, 0.5f));
		Test.Assert(Near(btn.Box.BackgroundColor.R, 1.0f));
	}

	[Test]
	public static void HoverReResolveDrivesALiveTransition()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer btn.ReleaseRef();
		root.AddChild(btn);
		let d = root.EventDispatcher;

		// transition on the base rule (applies both directions); :hover changes opacity.
		let mgr = scope StyleManager(Sheet("button { opacity: 1; transition: opacity 0.5s linear; } button:hover { opacity: 0.4; }", scope StyleSheet()));

		mgr.ApplyTree(root); // first apply (snap)
		Test.Assert(Near(btn.Alpha, 1.0f));

		d.InjectMouseMove(.(50.0f, 50.0f)); // hover the button
		Test.Assert(btn.Hovered);

		mgr.ApplyTree(root); // re-resolve: :hover now matches -> transition animates
		Test.Assert(root.ActionManager.Count == 1);
		Test.Assert(Near(btn.Alpha, 1.0f)); // starts where it was

		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(Near(btn.Alpha, 0.7f)); // 1 + (0.4-1)*0.5
		root.Context.Update(SceneFixtures.Seconds(0.25));
		Test.Assert(Near(btn.Alpha, 0.4f)); // arrived at :hover value
	}

	[Test]
	public static void MediaContextGatesWhatApplies()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer btn.ReleaseRef();
		root.AddChild(btn);

		let mgr = scope StyleManager(Sheet("button { opacity: 1; } @media (min-width: 600px) { button { opacity: 0.2; } }", scope StyleSheet()));

		mgr.MediaContext = .(400.0f, 0.0f, 96.0f); // narrow
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 1.0f));

		mgr.Clear(); // forget cached styles so the re-apply is a fresh snap
		mgr.MediaContext = .(800.0f, 0.0f, 96.0f); // wide
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 0.2f));
	}

	[Test]
	public static void SettingTheStyleSheetSwapsStylesHotReload()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer btn.ReleaseRef();
		root.AddChild(btn);

		let mgr = scope StyleManager(Sheet("button { opacity: 1; }", scope StyleSheet()));
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 1.0f));

		mgr.StyleSheet = Sheet("button { opacity: 0.3; }", scope StyleSheet());
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 0.3f));
	}

	// ===================== Origins =====================

	[Test]
	public static void TheGuisSheetOutranksTheUserAgentsAtAnySpecificity()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let button = Tagged(root, "button");
		defer button.ReleaseRef();
		button.Id = "ok";
		let styles = scope StyleManager();
		styles.UserAgentSheet = Sheet("#ok { opacity: 0.2; } button { padding: 9px; }", scope StyleSheet());
		styles.StyleSheet = Sheet("* { opacity: 0.7; }", scope StyleSheet());
		styles.ApplyTree(root);
		Test.Assert(Near(button.Alpha, 0.7f)); // a universal rule over an id one
		Test.Assert(Near(button.Padding.Left, 9.0f)); // what the GUI's sheet does not say
	}

	[Test]
	public static void ASubtreesSheetAppliesInsideItAloneOverTheGuisAnInnerOneOverAnOuter()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let page = Tagged(root, "panel", "page");
		defer page.ReleaseRef();
		let inside = Tagged(page, "label", "note");
		defer inside.ReleaseRef();
		let inner = Tagged(page, "panel", "card");
		defer inner.ReleaseRef();
		let deep = Tagged(inner, "label", "note");
		defer deep.ReleaseRef();
		let outside = Tagged(root, "label", "note");
		defer outside.ReleaseRef();
		let styles = scope StyleManager();
		styles.StyleSheet = Sheet("label.note { opacity: 0.9; }", scope StyleSheet());
		Test.Assert(styles.SetSubtreeSheet(page, Sheet(".note { opacity: 0.5; } @keyframes fade { from { opacity: 0; } to { opacity: 1; } }", scope StyleSheet())));
		Test.Assert(styles.SetSubtreeSheet(inner, Sheet("* { opacity: 0.3; }", scope StyleSheet())));
		styles.ApplyTree(root);
		Test.Assert(Near(inside.Alpha, 0.5f)); // the page's, though less specific
		Test.Assert(Near(deep.Alpha, 0.3f)); // the inner card's
		Test.Assert(Near(outside.Alpha, 0.9f)); // outside the page: the GUI's alone

		styles.RemoveSubtreeSheet(inner);
		styles.ApplyTree(root);
		Test.Assert(Near(deep.Alpha, 0.5f));
		// A node in no GUI cannot hold a subtree sheet.
		let loose = new UIWidget();
		defer loose.ReleaseRef();
		Test.Assert(!styles.SetSubtreeSheet(loose, scope StyleSheet()));
	}

	// ===================== Computed style =====================

	[Test]
	public static void ARuleThatStopsMatchingGivesBackEverythingItSet()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let w = Tagged(root, "box");
		defer w.ReleaseRef();
		let styles = scope StyleManager(Sheet(
			"box.on { opacity: 0.5; padding: 7px; width: 120px; margin-left: 4px; display: grid; overflow: hidden; " +
			"visibility: hidden; enabled: false; flex-grow: 2; }", scope StyleSheet()));
		styles.ApplyTree(root);
		let padding = w.Padding;
		let layout = scope LayoutStyle();
		layout.Set(w.LayoutStyle);

		w.AddClass("on");
		styles.ApplyTree(root);
		Test.Assert(Near(w.Alpha, 0.5f));
		Test.Assert(Near(w.Padding.Top, 7.0f));
		Test.Assert(w.LayoutStyle.Width == LayoutLength.Px(120.0f));
		Test.Assert(w.LayoutStyle.Kind == .Grid);
		Test.Assert(w.ClipsChildren);
		Test.Assert(!w.Visible);
		Test.Assert(!w.Enabled);

		w.RemoveClass("on");
		styles.ApplyTree(root);
		Test.Assert(Near(w.Alpha, 1.0f));
		Test.Assert(w.Padding == padding);
		Test.Assert(!ChangedLayoutSlots(w.LayoutStyle, layout).Any);
		Test.Assert(!w.ClipsChildren);
		Test.Assert(w.Visible);
		Test.Assert(w.Enabled);
	}

	[Test]
	public static void WhatCodeSetsIsCodesOverTheSheetBeforeOrAfterARestyle()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let early = Tagged(root, "box");
		defer early.ReleaseRef();
		let late = Tagged(root, "box");
		defer late.ReleaseRef();
		early.Alpha = 0.3f; // before any sheet
		let styles = scope StyleManager(Sheet("box { opacity: 0.8; width: 50px; }", scope StyleSheet()));
		styles.ApplyTree(root);
		Test.Assert(Near(early.Alpha, 0.3f));
		Test.Assert(Near(late.Alpha, 0.8f));

		late.Alpha = 0.6f; // after the sheet styled it
		late.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(70.0f); });
		late.MarkStyleDirty(false);
		styles.ApplyTree(root);
		Test.Assert(Near(late.Alpha, 0.6f));
		Test.Assert(late.LayoutStyle.Width == LayoutLength.Px(70.0f));
		Test.Assert(late.IsStylePinned(.SlotWidth));
		Test.Assert(!late.IsStylePinned(.SlotHeight)); // only what code changed

		// Given back, the sheet's value returns.
		late.UnpinStyle(SlotBit(.SlotOpacity) | SlotBit(.SlotWidth));
		styles.ApplyTree(root);
		Test.Assert(Near(late.Alpha, 0.8f));
		Test.Assert(late.LayoutStyle.Width == LayoutLength.Px(50.0f));
	}

	[Test]
	public static void AHoverRuleEndsAndWhatItSetReturns()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let w = Tagged(root, "button");
		defer w.ReleaseRef();
		w.Size = .(100.0f, 40.0f);
		let styles = scope StyleManager(Sheet("button:hover { opacity: 0.7; padding-left: 12px; }", scope StyleSheet()));
		styles.ApplyTree(root);
		let d = root.EventDispatcher;
		d.InjectMouseMove(.(50.0f, 20.0f));
		styles.ApplyTree(root);
		Test.Assert(Near(w.Alpha, 0.7f));
		Test.Assert(Near(w.Padding.Left, 12.0f));
		d.InjectMouseMove(.(150.0f, 150.0f));
		styles.ApplyTree(root);
		Test.Assert(Near(w.Alpha, 1.0f));
		Test.Assert(Near(w.Padding.Left, 0.0f));
	}

	[Test]
	public static void ARestyleThatStartsBelowTheTreesTopStillSeesTheAncestorsAboveIt()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let page = NewTagged("panel", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer page.ReleaseRef();
		page.AddClass("page");
		root.AddChild(page);
		let section = NewTagged("panel", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer section.ReleaseRef();
		page.AddChild(section);
		let cell = NewTagged("cell", .(0.0f, 0.0f), .(10.0f, 10.0f));
		defer cell.ReleaseRef();
		section.AddChild(cell);

		let mgr = scope StyleManager(Sheet(".page cell { opacity: 0.5; } .other cell { opacity: 0.25; }", scope StyleSheet()));
		mgr.ApplyTree(section); // .page is above where the walk starts
		Test.Assert(Near(cell.Alpha, 0.5f));
	}

	[Test]
	public static void AForcedStateReadsAsSetRestylingTheNodeAndItsSubtreeWhenARuleReadsItThroughAnAncestor()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer btn.ReleaseRef();
		root.AddChild(btn);
		let label = NewTagged("label", .(0.0f, 0.0f), .(50.0f, 20.0f));
		defer label.ReleaseRef();
		btn.AddChild(label);
		let mgr = scope StyleManager(Sheet(
			"button { opacity: 1; } button:hover { opacity: 0.5; } button:disabled { opacity: 0.25; }" +
			"button:enabled label { opacity: 0.9; } button:hover label { opacity: 0.75; }", scope StyleSheet()));
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 1.0f));
		Test.Assert(Near(label.Alpha, 0.9f));

		btn.ForcedStyleStates = Node.StateHover;
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 0.5f));
		Test.Assert(Near(label.Alpha, 0.75f)); // read through its ancestor
		Test.Assert(!btn.Hovered); // only the style pass sees it

		btn.ForcedStyleStates = Node.StateDisabled; // forced disabled is not enabled
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 0.25f));
		Test.Assert(Near(label.Alpha, 1.0f)); // neither label rule matches now
		Test.Assert(btn.Enabled);

		btn.ForcedStyleStates = 0;
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 1.0f));
		Test.Assert(Near(label.Alpha, 0.9f));
	}

	[Test]
	public static void ANodeSaysWhereEachPropertysValueCameFromARuleItsInlineStyleCodeAnAncestorOrItself()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let panel = NewTagged("panel", .(0.0f, 0.0f), .(200.0f, 200.0f));
		defer panel.ReleaseRef();
		root.AddChild(panel);
		let btn = NewTagged("button", .(0.0f, 0.0f), .(100.0f, 40.0f));
		defer btn.ReleaseRef();
		btn.Id = "ok";
		btn.AddClass("primary");
		panel.AddChild(btn);
		let mgr = scope StyleManager(Sheet(
			"panel { color: #ff0000; }\n" + // line 1
			"button { opacity: 0.8; padding: 4px; }\n" + // line 2
			".primary { opacity: 0.6 !important; }\n" + // line 3
			"#ok { opacity: 0.3; margin: 2px; height: 30px; }\n", // line 4
			scope StyleSheet(), "app.css"));
		btn.SetInlineStyle("margin-left", "9px"); // markup's attribute
		btn.Padding = Thickness(1.0f); // code: the padding is its own now
		mgr.ApplyTree(root);

		let opacity = scope StyleExplanation();
		mgr.ExplainProperty(btn, "opacity", opacity);
		Test.Assert(opacity.Origin == .Sheet);
		Test.Assert(opacity.Value == "0.6");
		Test.Assert(opacity.Declarations.Count == 3); // the winner first, then by precedence
		Test.Assert(opacity.Declarations[0].Selector == ".primary");
		Test.Assert(opacity.Declarations[0].Line == 3);
		Test.Assert(opacity.Declarations[0].Important);
		Test.Assert(opacity.Declarations[0].Sheet == "app.css");
		Test.Assert(opacity.Declarations[1].Selector == "#ok");
		Test.Assert(opacity.Declarations[2].Selector == "button");
		Test.Assert(opacity.Declarations[2].Line == 2);

		let marginLeft = scope StyleExplanation();
		mgr.ExplainProperty(btn, "margin-left", marginLeft);
		Test.Assert(marginLeft.Origin == .Inline); // over the sheet's shorthand
		Test.Assert(marginLeft.Declarations.Count == 2);
		Test.Assert(marginLeft.Declarations[0].Inline);
		Test.Assert(marginLeft.Declarations[1].Selector == "#ok"); // its margin's longhand
		Test.Assert(marginLeft.Declarations[1].Value == "2px");

		let paddingTop = scope StyleExplanation();
		mgr.ExplainProperty(btn, "padding-top", paddingTop);
		Test.Assert(paddingTop.Origin == .Code); // the sheet's padding is overridden
		Test.Assert(paddingTop.Declarations.Count == 1);
		Test.Assert(paddingTop.Declarations[0].Selector == "button");

		let color = scope StyleExplanation();
		mgr.ExplainProperty(btn, "color", color);
		Test.Assert(color.Origin == .Inherited);
		Test.Assert(color.InheritedFrom == panel);
		Test.Assert(color.Declarations.IsEmpty);

		let zIndex = scope StyleExplanation();
		mgr.ExplainProperty(btn, "z-index", zIndex);
		Test.Assert(zIndex.Origin == .Own);

		// The whole list holds each of them once.
		let all = scope List<StyleExplanation>();
		defer { ClearAndDeleteItems!(all); }
		mgr.ExplainStyle(btn, all);
		int found = 0;
		for (let e in all)
			found += ((e.Property == "opacity") || (e.Property == "color") || (e.Property == "padding-top") || (e.Property == "height")) ? 1 : 0;
		Test.Assert(found == 4);
	}

	/// A root 200 by 400 holding a column of twenty rows, each held by the tree alone; the root
	/// and the column held by the caller.
	private static void BuildColumn(out SceneRoot root, out UIWidget column)
	{
		root = SceneFixtures.NewScene(200.0f, 400.0f);
		column = NewTagged("column", .(0.0f, 0.0f), .(200.0f, 400.0f));
		root.AddChild(column);
		for (int i = 0; i < 20; i++)
		{
			let row = NewTagged("row", .(0.0f, 0.0f), .(200.0f, 10.0f));
			column.AddChild(row);
			row.ReleaseRef();
		}
	}

	[Test]
	public static void AChildAddedRestylesItsSiblingsOnlyWhenARuleReadsSiblings()
	{
		{
			// No rule reads siblings: the new row and its column restyle, the other twenty do not.
			BuildColumn(let root, let column);
			defer root.ReleaseRef();
			defer column.ReleaseRef();
			let mgr = scope StyleManager(Sheet("row { opacity: 0.5; }", scope StyleSheet()));
			mgr.ApplyTree(root);
			let row = NewTagged("row", .(0.0f, 0.0f), .(200.0f, 10.0f));
			column.AddChild(row);
			row.ReleaseRef();
			mgr.ApplyTree(root);
			Test.Assert(mgr.LastRestyleCount == 2);
		}
		{
			// :nth-child reads them: taking the first row away flips every other row's match.
			BuildColumn(let root, let column);
			defer root.ReleaseRef();
			defer column.ReleaseRef();
			let mgr = scope StyleManager(Sheet("row { opacity: 1; } row:nth-child(odd) { opacity: 0.5; }", scope StyleSheet()));
			mgr.ApplyTree(root);
			let second = column.GetChildAt(1);
			Test.Assert(Near(second.Alpha, 1.0f));
			column.RemoveChild(column.GetChildAt(0));
			mgr.ApplyTree(root);
			Test.Assert(mgr.LastRestyleCount >= 19);
			Test.Assert(Near(second.Alpha, 0.5f)); // first now: odd
		}
	}

	[Test]
	public static void ADeclarationEditedInItsRuleRestylesEveryNodeTheRuleMatches()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = NewTagged("button", .(0.0f, 0.0f), .(50.0f, 20.0f));
		defer a.ReleaseRef();
		let b = NewTagged("button", .(0.0f, 30.0f), .(50.0f, 20.0f));
		defer b.ReleaseRef();
		root.AddChild(a);
		root.AddChild(b);
		let mgr = scope StyleManager(Sheet("button { opacity: 0.8; padding: 4px; }", scope StyleSheet(), "app.css"));
		mgr.ApplyTree(root);
		let opacity = scope StyleExplanation();
		mgr.ExplainProperty(a, "opacity", opacity);
		Test.Assert(opacity.Declarations.Count == 1);
		Test.Assert(opacity.Declarations[0].Rule != null);
		Test.Assert(mgr.EditDeclaration(opacity.Declarations[0].Rule, "opacity", "0.4"));
		// A longhand of the rule's shorthand: that side alone.
		Test.Assert(mgr.EditDeclaration(opacity.Declarations[0].Rule, "padding-left", "9px"));
		mgr.ApplyTree(root);
		Test.Assert(Near(a.Alpha, 0.4f));
		Test.Assert(Near(b.Alpha, 0.4f)); // the rule's every node
		Test.Assert(Near(a.Padding.Left, 9.0f));
		Test.Assert(Near(a.Padding.Top, 4.0f));
		let stranger = scope StyleRule("button");
		Test.Assert(!mgr.EditDeclaration(stranger, "opacity", "1"));
	}

	[Test]
	public static void AWidgetsOwnDefaultsAreWhatARuleGivesBackTo()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let tip = new Tooltip(); // 6 by 3 padding of its own
		defer tip.ReleaseRef();
		root.AddChild(tip);
		let own = tip.Padding;
		let styles = scope StyleManager(Sheet("tooltip.big { padding: 20px; }", scope StyleSheet()));
		styles.ApplyTree(root);
		Test.Assert(tip.Padding == own); // no rule: its own, not CSS's initial 0
		tip.AddClass("big");
		styles.ApplyTree(root);
		Test.Assert(Near(tip.Padding.Left, 20.0f));
		tip.RemoveClass("big");
		styles.ApplyTree(root);
		Test.Assert(tip.Padding == own);
	}

	[Test]
	public static void APartTakesABoxBackgroundBorderRadiiShadowAndOpacity()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		slider.Size = .(160.0f, 24.0f);
		root.AddChild(slider);
		let styles = scope StyleManager(Sheet(
			"slider::thumb { background-color: #ff0000; border: 2px solid #0000ff; border-radius: 3px; box-shadow: 0 2px 4px #00ff00; opacity: 0.5; }",
			scope StyleSheet()));
		styles.ApplyTree(root);
		let thumb = slider.GetPartStyle("thumb");
		Test.Assert(thumb.HasBackground);
		Test.Assert(thumb.HasBorderWidth);
		Test.Assert(thumb.HasRadii);
		Test.Assert(thumb.HasShadows);
		Test.Assert(Near(thumb.Opacity, 0.5f));
		Test.Assert(Near(thumb.Box.Radii.TopLeft, 3.0f));
		Test.Assert(!slider.GetPartStyle("track").HasBackground); // the track keeps its own
	}

	[Test]
	public static void EmMeasuresByTheElementsOwnFontSizeWhichTakesEmAndPercentagesOfItsParents()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let big = new Panel();
		defer big.ReleaseRef();
		big.AddClass("big");
		root.AddChild(big);
		let pct = new Panel();
		defer pct.ReleaseRef();
		pct.AddClass("pct");
		root.AddChild(pct);
		let styles = scope StyleManager(Sheet(".big { font-size: 2em; padding-left: 1em; } .pct { font-size: 150%; padding-left: 1em; }", scope StyleSheet()));
		styles.ApplyTree(root);
		Test.Assert(Near(big.Padding.Left, 32.0f)); // 2em of the root's 16, then 1em of that
		Test.Assert(Near(pct.Padding.Left, 24.0f));
	}

	[Test]
	public static void ANumberPropertyTakesAPercentageAsAFractionAndRefusesAUnit()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let half = new Panel();
		defer half.ReleaseRef();
		half.AddClass("half");
		root.AddChild(half);
		let junk = new Panel();
		defer junk.ReleaseRef();
		junk.AddClass("junk");
		root.AddChild(junk);
		let styles = scope StyleManager(Sheet(".half { opacity: 50%; } .junk { opacity: 0.3px; }", scope StyleSheet()));
		styles.ApplyTree(root);
		Test.Assert(Near(half.Alpha, 0.5f)); // not 50
		Test.Assert(Near(junk.Alpha, 1.0f)); // not a number: its own value
	}

	[Test]
	public static void APartsBorderColorAloneRecoloursItsOwnOutline()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let area = new CheckBox();
		defer area.ReleaseRef();
		area.Size = .(20.0f, 20.0f);
		root.AddChild(area);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "checkbox::box { border-color: #ff00ff; }");
		styles.ApplyTree(root);
		let part = area.GetPartStyle("box");
		Test.Assert(part.HasBorderColor);
		Test.Assert(!part.HasBorderWidth);
		Test.Assert(!part.HasBackground);
		let drawn = OutlinedBox(Color.White, 2.0f, scope NodeBox());
		part.Over(drawn);
		Test.Assert(Near(drawn.BorderWidths.Top, 2.0f)); // its own width
		Test.Assert(Near(drawn.BorderColors.Top.G, 0.0f)); // the sheet's colour
		Test.Assert(Near(drawn.BackgroundColor.A, 0.0f)); // no fill
	}

	[Test]
	public static void AReflectedPropertyTheSheetSetReturnsToItsOwnValueUnlessCodeTookIt()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Placeholder = "own";
		root.AddChild(field);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "textfield.hint { placeholder: from the sheet; }");
		styles.ApplyTree(root);
		field.AddClass("hint");
		styles.ApplyTree(root);
		Test.Assert(field.Placeholder == "from the sheet");
		field.RemoveClass("hint");
		styles.ApplyTree(root);
		Test.Assert(field.Placeholder == "own");

		field.AddClass("hint");
		styles.ApplyTree(root);
		field.Placeholder = "code's"; // code takes it
		field.RemoveClass("hint");
		styles.ApplyTree(root);
		Test.Assert(field.Placeholder == "code's");
		field.AddClass("hint");
		styles.ApplyTree(root);
		Test.Assert(field.Placeholder == "code's");
	}

	[Test]
	public static void MarkupsInlinePropertiesOutrankEverySheetsNormalOnesNotImportant()
	{
		let markup = MarkupFixtures.Load("<Panel><Label class=\"chip\" opacity=\"0.4\"/><Label class=\"hard\" opacity=\"0.4\"/></Panel>");
		Test.Assert(markup != null);
		defer markup.ReleaseRef();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.AddChild(markup);
		let chip = markup.GetChildAt(0) as UIWidget;
		let hard = markup.GetChildAt(1) as UIWidget;
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".chip { opacity: 0.9; } .hard { opacity: 0.8 !important; }");
		styles.ApplyTree(root);
		Test.Assert(Near(chip.Alpha, 0.4f));
		Test.Assert(Near(hard.Alpha, 0.8f));
		// A script or code may set inline style too.
		chip.SetInlineStyle("opacity", "0.6");
		styles.ApplyTree(root);
		Test.Assert(Near(chip.Alpha, 0.6f));
	}

	[Test]
	public static void AMarkupPropertyARestyleMeetsAgainIsNotWrittenAgainTheTreeSettles()
	{
		let markup = MarkupFixtures.Load("<Panel><ListBox items=\"One|Two|Three\"/></Panel>");
		Test.Assert(markup != null);
		defer markup.ReleaseRef();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.AddChild(markup);
		let list = markup.GetChildAt(0) as ListBox;
		Test.Assert(list != null);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "listbox { opacity: 1; }");
		styles.ApplyTree(root);
		Test.Assert(list.ItemCount == 3);
		let firstRow = list.GetChildAt(0);
		styles.ApplyTree(root);
		styles.ApplyTree(root);
		Test.Assert(styles.LastRestyleCount == 0); // a list rebuilding its rows restyled itself every frame
		Test.Assert(list.GetChildAt(0) == firstRow); // its rows were not made again
	}
}
