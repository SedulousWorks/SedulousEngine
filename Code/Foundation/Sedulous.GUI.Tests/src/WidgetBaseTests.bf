using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using internal Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A UINode that counts what it is told: its text style changing, and a part's style.
class TellingNode : UINode
{
	public int TextChanges = 0;
	public int PartChanges = 0;
	public String LastPart = new .() ~ delete _;

	protected override void OnTextStyleChange()
	{
		TextChanges++;
	}

	protected override void OnPartStyleChange(StringView part)
	{
		PartChanges++;
		LastPart.Set(part);
	}
}

/// A widget that may be its focus group's current member (a checked radio).
class GroupMember : UIWidget
{
	public bool Current = false;

	public override bool IsCurrentInGroup => Current;
}

/// A widget reporting a state of its own.
class CheckedWidget : UIWidget
{
	public override uint32 WidgetStates => WidgetStateChecked;
}

/// A bridge that keeps what it is sent.
class RecordingBridge : IAccessibilityBridge
{
	public List<AccessTreeUpdate> Updates = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Spoken = new .() ~ DeleteContainerAndItems!(_);

	public bool IsListening => true;

	public void Update(AccessTreeUpdate update)
	{
		let copy = new AccessTreeUpdate();
		copy.Set(update);
		Updates.Add(copy);
	}

	public void Announce(StringView text, AnnouncePriority priority)
	{
		Spoken.Add(new String(text));
	}
}

/// What the widget base does beyond the ported tests: classes, ids and their restyles, the
/// widget states, the text style and its pins, inline styles, the animated layer, part styles,
/// drag and drop from markup's properties, the reflected UINode and UIWidget tables, directional
/// navigation's scores, scopes and entries, and the accessibility model's types.
class WidgetBaseTests
{
	/// A focusable widget at (x, y), `w` by `h`, id `id`, the last child of `parent` (borrowed).
	private static UIWidget Cell(Node parent, StringView id, float x, float y, float w = 40.0f, float h = 20.0f)
	{
		let cell = new UIWidget();
		cell.Id = id;
		cell.TabFocusable = true;
		cell.Position = .(x, y);
		cell.Size = .(w, h);
		parent.AddChild(cell);
		cell.ReleaseRef();
		return cell;
	}

	/// A widget that takes no focus at (x, y), `w` by `h`, the last child of `parent` (borrowed).
	private static UIWidget Area(Node parent, float x, float y, float w, float h)
	{
		let area = new UIWidget();
		area.Position = .(x, y);
		area.Size = .(w, h);
		parent.AddChild(area);
		area.ReleaseRef();
		return area;
	}

	// === CSS identity ===

	[Test]
	public static void ClassesAndIdsRestyleOnlyWhenTheyChange()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.ClearStyleDirty();
		w.AddClass("primary");
		Test.Assert(w.IsStyleDirty && w.IsStyleSubtreeDirty); // the selectors it matches change
		w.ClearStyleDirty();
		w.AddClass("primary"); // there already
		w.AddClass(""); // no class
		w.RemoveClass("absent");
		Test.Assert(!w.IsStyleDirty);
		w.RemoveClass("primary");
		Test.Assert(w.IsStyleDirty && w.IsStyleSubtreeDirty);
		w.ClearStyleDirty();
		w.Id = "ok";
		Test.Assert(w.IsStyleDirty && w.IsStyleSubtreeDirty);
		w.AddClass("a");
		w.AddClass("b");
		Test.Assert(w.Classes.Length == 2);
		Test.Assert(w.Classes[0] == "a" && w.Classes[1] == "b");
	}

	[Test]
	public static void AWidgetsDebugNameIsItsTypeAndItsId()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Test.Assert(w.DebugName(.. scope String()) == "UIWidget");
		w.Id = "ok";
		Test.Assert(w.DebugName(.. scope String()) == "UIWidget #ok");
	}

	[Test]
	public static void AWidgetsPlaceAmongItsParentsWidgetsCountsWidgetsOnly()
	{
		let lone = new UIWidget();
		defer lone.ReleaseRef();
		int32 position = 0;
		int32 count = 0;
		lone.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 1 && count == 1);

		let parent = new Node();
		defer parent.ReleaseRef();
		NodeFixtures.Box(parent); // not a widget
		let a = Area(parent, 0.0f, 0.0f, 1.0f, 1.0f);
		NodeFixtures.Box(parent);
		let b = Area(parent, 0.0f, 0.0f, 1.0f, 1.0f);
		a.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 1 && count == 2);
		b.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 2 && count == 2);
		let c = Area(parent, 0.0f, 0.0f, 1.0f, 1.0f); // the children changed: numbered again
		b.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 2 && count == 3);
		c.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 3 && count == 3);
		parent.SetChildIndex(c, 0);
		a.PositionAmongWidgets(out position, out count);
		Test.Assert(position == 2 && count == 3);
	}

	// === States ===

	[Test]
	public static void WidgetStatesAreOneBitEachAndNoneByDefault()
	{
		Test.Assert(WidgetStateNone == 0);
		Test.Assert(WidgetStateChecked == 1);
		Test.Assert(WidgetStateIndeterminate == 2);
		Test.Assert(WidgetStateEditable == 4);
		Test.Assert(WidgetStatePlaceholderShown == 8);
		Test.Assert(WidgetStateSelected == 16);
		let plain = new UIWidget();
		defer plain.ReleaseRef();
		Test.Assert(plain.WidgetStates == WidgetStateNone);
		let checkedOne = new CheckedWidget();
		defer checkedOne.ReleaseRef();
		UIWidget asWidget = checkedOne;
		Test.Assert(asWidget.WidgetStates == WidgetStateChecked);
	}

	[Test]
	public static void ATooltipAndItsInteractivityAnswerThroughNode()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Node asNode = w;
		Test.Assert(asNode.TooltipText.IsEmpty && !asNode.IsTooltipInteractive);
		w.Tooltip = "Saves the file";
		w.TooltipInteractive = true;
		Test.Assert(asNode.TooltipText == "Saves the file");
		Test.Assert(asNode.IsTooltipInteractive);
	}

	[Test]
	public static void AccessibilityOverridesMarkTheNodeForTheNextUpdate()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.ClearAccessDirty();
		w.AccessRoleName = "button";
		Test.Assert(w.IsAccessDirty);
		w.ClearAccessDirty();
		w.AccessLabel = "Close";
		Test.Assert(w.IsAccessDirty);
		w.ClearAccessDirty();
		w.AccessLabelledBy = "title";
		Test.Assert(w.IsAccessDirty);
		w.ClearAccessDirty();
		w.AccessDescribedBy = "hint";
		Test.Assert(w.IsAccessDirty);
		w.ClearAccessDirty();
		w.AccessControls = "panel";
		Test.Assert(w.IsAccessDirty);
		w.ClearAccessDirty();
		w.AccessHidden = true;
		Test.Assert(w.IsAccessDirty && w.AccessHidden);
		Test.Assert(w.AccessRoleName == "button" && w.AccessLabel == "Close" && w.AccessControls == "panel");
	}

	// === Drag and drop in markup ===

	[Test]
	public static void TheDragModeReadsAsItsNameAndBlockOwnsThePress()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Test.Assert(w.DragModeName == "auto");
		Test.Assert(!w.OwnsPressDrag(.(1.0f, 1.0f)));
		w.DragModeName = "  block ";
		Test.Assert(w.DragModeName == "block");
		Test.Assert(w.OwnsPressDrag(.(1.0f, 1.0f)));
		w.DragModeName = "none";
		Test.Assert(w.DragModeName == "none");
		Test.Assert(!w.OwnsPressDrag(.(1.0f, 1.0f)));
		w.DragModeName = "sideways"; // not a mode: auto
		Test.Assert(w.DragModeName == "auto");
	}

	[Test]
	public static void AWidgetWithADragTypeDragsItsValueAndLabel()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		let none = scope DragRequest();
		Test.Assert(!w.HandleDragRequested(none)); // no type: the press passes up

		w.DragType = "card";
		w.DragValue = "7";
		let byValue = scope DragRequest();
		Test.Assert(w.HandleDragRequested(byValue));
		Test.Assert(byValue.Payload.Type == "card");
		Test.Assert(TextOf(byValue.Payload.Value) == "7");
		Test.Assert(byValue.Payload.Label == "7"); // no label: the value

		w.DragLabel = "Seven";
		let labelled = scope DragRequest();
		Test.Assert(w.HandleDragRequested(labelled));
		Test.Assert(labelled.Payload.Label == "Seven");

		w.DragModeName = "none";
		Test.Assert(!w.HandleDragRequested(scope DragRequest()));
		w.DragModeName = "block";
		Test.Assert(!w.HandleDragRequested(scope DragRequest()));
	}

	[Test]
	public static void ADropReasonTakesTheDropAndSaysWhy()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.DropTypes = "card";
		w.DropReason = "Move it here";
		let payload = scope DragPayload();
		payload.Type.Set("card");
		let query = scope DropQuery(payload);
		w.HandleDragQuery(query);
		Test.Assert(query.Effect == .Move); // the source's preferred effect
		Test.Assert(query.Reason == "Move it here");

		let other = scope DragPayload();
		other.Type.Set("photo");
		let refused = scope DropQuery(other);
		w.HandleDragQuery(refused);
		Test.Assert(refused.Effect == .None);
		Test.Assert(refused.Reason.IsEmpty);

		w.DropReason = "";
		let silent = scope DropQuery(payload);
		w.HandleDragQuery(silent);
		Test.Assert(silent.Effect == .Move); // its drop types still take it
		Test.Assert(silent.Reason.IsEmpty);
	}

	[Test]
	public static void AContextMenusIdIsKept()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Test.Assert(w.ContextMenuId.IsEmpty);
		w.ContextMenuId = "edit-menu";
		Test.Assert(w.ContextMenuId == "edit-menu");
		w.ContextMenuId = "edit-menu"; // the same again
		Test.Assert(w.ContextMenuId == "edit-menu");
	}

	// === Reflection ===

	[Test]
	public static void UINodeAndUIWidgetReflectTheirPropertiesUnderTheirCssNames()
	{
		let widgetType = UIWidget.StaticGuiType;
		Test.Assert(widgetType.Tag == "UIWidget");
		Test.Assert(widgetType.Base == UINode.StaticGuiType);
		Test.Assert(UINode.StaticGuiType.Tag == "UINode");
		Test.Assert(UINode.StaticGuiType.Base == Node.StaticGuiType);
		Test.Assert(UINode.StaticGuiType.OwnProperties.Length == 0);
		Test.Assert(!widgetType.CanCreate && !UINode.StaticGuiType.CanCreate);
		Test.Assert(MarkupChildHost.StaticGuiType.Base == widgetType);
		Test.Assert(widgetType.OwnProperties.Length == 15);

		let w = new UIWidget();
		defer w.ReleaseRef();
		Node asNode = w;
		Test.Assert(asNode.GuiType == widgetType);

		let cssNames = scope String[](
			"tooltip", "tooltip-interactive", "role", "aria-label", "aria-labelledby", "aria-describedby",
			"aria-controls", "aria-hidden", "context-menu", "drag-type", "drag-value", "drag-label", "drag",
			"drop-reason");
		for (let css in cssNames)
		{
			let property = widgetType.FindCss(css);
			Test.Assert(property != null, scope $"{css} is reflected");
			Test.Assert(property.Access.IsEmpty);
			Test.Assert(property.CanWrite);
			Test.Assert(property.IsTranslatable == ((css == "tooltip") || (css == "aria-label")), scope $"{css}'s translatable flag");
		}
		let id = widgetType.Find("id");
		Test.Assert((id != null) && id.Css.IsEmpty); // a sheet sets no id
		Test.Assert(widgetType.FindCss("aria-hidden").ValueType == typeof(bool));
		Test.Assert(widgetType.FindCss("nav-up") != null); // Node's, through the chain

		var ok = TextVariant("ok");
		defer ok.Dispose();
		Test.Assert(id.Set(w, ok));
		Test.Assert(w.Id == "ok");
		var title = TextVariant("title");
		defer title.Dispose();
		Test.Assert(widgetType.FindCss("aria-labelledby").Set(w, title));
		Test.Assert(w.AccessLabelledBy == "title");
		var block = TextVariant("block");
		defer block.Dispose();
		Test.Assert(widgetType.FindCss("drag").Set(w, block));
		Test.Assert(w.DragModeName == "block");
		Test.Assert(widgetType.FindCss("tooltip-interactive").Set(w, System.Variant.Create(true)));
		Test.Assert(w.TooltipInteractive);
		Test.Assert(widgetType.FindCss("aria-hidden").Set(w, System.Variant.Create(true)));
		Test.Assert(w.AccessHidden);
		w.Tooltip = "Saves";
		var tip = widgetType.FindCss("tooltip").Get(w);
		Test.Assert(TextOf(tip) == "Saves");
		tip.Dispose();
	}

	// === Text style ===

	[Test]
	public static void ATextPropertyFromCodePinsItAndTellsTheNodeOnce()
	{
		let n = new TellingNode();
		defer n.ReleaseRef();
		n.ClearStyleDirty();
		n.TextColor = Color(1.0f, 0.0f, 0.0f);
		Test.Assert(n.IsStylePinned(.SlotColor));
		Test.Assert(n.TextChanges == 1);
		Test.Assert(n.IsStyleDirty && n.IsStyleSubtreeDirty); // what the subtree inherits changed
		n.TextColor = Color(1.0f, 0.0f, 0.0f); // the same
		Test.Assert(n.TextChanges == 1);

		n.SetTextAlignment(.Center, .Middle);
		Test.Assert(n.TextAlignH == .Center && n.TextAlignV == .Middle);
		Test.Assert(n.IsStylePinned(.SlotTextAlign) && n.IsStylePinned(.SlotVerticalAlign));
		Test.Assert(n.WhiteSpace == .NoWrap); // a node's own: one line
		n.WhiteSpace = .PreWrap;
		Test.Assert(n.GetTextStyle().WhiteSpace == .PreWrap && n.IsStylePinned(.SlotWhiteSpace));
		n.SetLineHeight(-3.0f);
		Test.Assert(n.GetTextStyle().LineHeight == 0.0f); // never below 0: normal, as it was, so no change
		Test.Assert(n.TextChanges == 3);
		n.SetLineHeight(1.5f, true);
		Test.Assert(n.GetTextStyle().LineHeightFactor && n.IsStylePinned(.SlotLineHeight));
		n.SetLetterSpacing(2.0f);
		Test.Assert(n.GetTextStyle().LetterSpacing == 2.0f && n.IsStylePinned(.SlotLetterSpacing));
		n.SetBreakWords(true);
		Test.Assert(n.GetTextStyle().BreakWords && n.IsStylePinned(.SlotOverflowWrap));
		n.SetFontItalic(true);
		Test.Assert(n.GetTextStyle().Selection.Italic && n.IsStylePinned(.SlotFontStyle));
		n.SetFontWeight(0);
		Test.Assert(n.GetTextStyle().Selection.Weight == 1);
		n.SetFontWeight(5000);
		Test.Assert(n.GetTextStyle().Selection.Weight == 1000);
		n.SetFontWeight(700);
		Test.Assert(n.GetTextStyle().Selection.Weight == 700 && n.IsStylePinned(.SlotFontWeight));
		Test.Assert(n.TextChanges == 10);
	}

	[Test]
	public static void ASheetsTextStyleWritesWithoutPinsOrARestyle()
	{
		let n = new TellingNode();
		defer n.ReleaseRef();
		n.ClearStyleDirty();
		let style = scope UINode.TextStyle();
		style.Set(n.GetTextStyle());
		style.TextColor = Color(0.0f, 1.0f, 0.0f);
		style.FontFamily.Set("Roboto");
		using (Node.StyleWriteScope(n))
		{
			n.ApplyTextStyle(style);
		}
		Test.Assert(n.TextChanges == 1);
		Test.Assert(n.TextColor == Color(0.0f, 1.0f, 0.0f));
		Test.Assert(n.GetTextStyle().FontFamily == "Roboto");
		Test.Assert(n.GetTextStyle() !== style); // a copy
		Test.Assert(!n.IsStylePinned(.SlotColor));
		Test.Assert(!n.IsStyleDirty);
		n.ApplyTextStyle(style); // the same
		Test.Assert(n.TextChanges == 1);
	}

	[Test]
	public static void ATextStylesLineHeightIsPixelsOrAMultipleOfItsFontSize()
	{
		let style = scope UINode.TextStyle();
		style.FontSize = 20.0f;
		style.LineHeight = 1.5f;
		Test.Assert(style.LineHeightPixels == 1.5f);
		style.LineHeightFactor = true;
		Test.Assert(style.LineHeightPixels == 30.0f);

		let copy = scope UINode.TextStyle();
		Test.Assert(!copy.Equals(style));
		copy.Set(style);
		Test.Assert(copy.Equals(style));
		copy.Selection.Weight = 700;
		Test.Assert(!copy.Equals(style) && (style.Selection.Weight == 400)); // deep
	}

	[Test]
	public static void TheUnstyledTextIsCapturedOnce()
	{
		let n = new UINode();
		defer n.ReleaseRef();
		n.TextColor = Color(1.0f, 0.0f, 0.0f);
		Test.Assert(n.CaptureUnstyledText().TextColor == Color(1.0f, 0.0f, 0.0f));
		n.TextColor = Color(0.0f, 0.0f, 1.0f);
		Test.Assert(n.CaptureUnstyledText().TextColor == Color(1.0f, 0.0f, 0.0f)); // the first
	}

	[Test]
	public static void ASharedTextStyleGivesTheFontAndColourWithoutPins()
	{
		let parent = new UINode();
		defer parent.ReleaseRef();
		parent.TextColor = Color(1.0f, 0.0f, 0.0f);
		parent.SetFontWeight(700);
		let part = new TellingNode();
		defer part.ReleaseRef();
		parent.ShareTextStyle(part);
		Test.Assert(part.TextColor == Color(1.0f, 0.0f, 0.0f));
		Test.Assert(part.GetTextStyle().Selection.Weight == 700);
		Test.Assert(!part.IsStylePinned(.SlotColor) && !part.IsStyleWriting);
		Test.Assert(part.TextChanges == 1);

		let uncoloured = new UINode();
		defer uncoloured.ReleaseRef();
		parent.ShareTextStyle(uncoloured, false);
		Test.Assert(uncoloured.TextColor == Color.White);
		Test.Assert(uncoloured.GetTextStyle().Selection.Weight == 700);
	}

	[Test]
	public static void ItsTextIsToldWhenTheWayItRunsChanges()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let n = new TellingNode();
		root.AddChild(n);
		n.ReleaseRef();
		n.OnDirectionChange(); // left to right, as it was
		Test.Assert(n.TextChanges == 0);
		root.SetLayoutDirection(.RightToLeft);
		Test.Assert(n.TextChanges == 1);
		Test.Assert(n.TextDirectionFor() == ParagraphDirection(.RightToLeft, false));
		n.OnDirectionChange(); // told again, running the same way
		Test.Assert(n.TextChanges == 1);
		n.SetLayoutDirection(.Auto);
		Test.Assert(n.TextDirectionFor() == ParagraphDirection(.Auto, true)); // each paragraph as it reads; none, as it runs
		Test.Assert(n.TextChanges == 2);
	}

	// === Inline style, motion and parts ===

	[Test]
	public static void AnInlineDeclarationReplacesOneOfItsNameAndRestylesOnlyOnAChange()
	{
		let n = new UINode();
		defer n.ReleaseRef();
		n.ClearStyleDirty();
		n.SetInlineStyle("width", "10px");
		Test.Assert(n.InlineStyle.Length == 1 && n.IsStyleDirty && !n.IsStyleSubtreeDirty);
		n.ClearStyleDirty();
		n.SetInlineStyle("width", "10px");
		Test.Assert(!n.IsStyleDirty);
		n.SetInlineStyle("width", "20px");
		Test.Assert(n.IsStyleDirty);
		Test.Assert(n.InlineStyle.Length == 1 && n.InlineStyle[0].Value == "20px");
		n.SetInlineStyle("opacity", "0.5");
		Test.Assert(n.InlineStyle.Length == 2);
		n.RemoveInlineStyle("width");
		Test.Assert(n.InlineStyle.Length == 1 && n.InlineStyle[0].Name == "opacity");
		n.ClearStyleDirty();
		n.RemoveInlineStyle("width");
		Test.Assert(!n.IsStyleDirty);
	}

	[Test]
	public static void TheAnimatedLayerKeepsOneValuePerProperty()
	{
		let n = new UINode();
		defer n.ReleaseRef();
		Test.Assert(!n.HasMotion);
		let value = scope MotionValue();
		value.Property.Set("opacity");
		value.To.Number = 0.5f;
		n.ClearStyleDirty();
		let stored = n.SetMotion(value);
		Test.Assert(stored !== value); // a copy
		Test.Assert(n.IsStyleMotionDirty && !n.IsStyleDirty); // applied again, not resolved anew
		Test.Assert(n.HasMotion && (n.FindMotion("opacity") == stored));
		Test.Assert(stored.To.Number == 0.5f);
		value.Progress = 0.25f;
		Test.Assert(n.SetMotion(value) == stored); // replaced in place
		Test.Assert(stored.Progress == 0.25f && n.MotionValues.Length == 1);
		Test.Assert(n.FindMotion("width") == null);
		Test.Assert(n.RemoveMotion("opacity"));
		Test.Assert(!n.RemoveMotion("opacity"));
		Test.Assert(!n.HasMotion);
	}

	[Test]
	public static void APartsStyleIsKeptByNameAndTheNodeIsToldAndRedrawn()
	{
		let n = new TellingNode();
		defer n.ReleaseRef();
		n.ClearNeedsRedraw();
		let style = scope PartStyle();
		style.Opacity = 0.5f;
		n.SetPartStyle("thumb", style);
		Test.Assert(n.PartChanges == 1 && n.LastPart == "thumb");
		Test.Assert(n.NeedsRedraw);
		n.SetPartStyle("thumb", style); // replaced
		Test.Assert(n.PartChanges == 2);
		n.SetPartStyle("track", style);
		Test.Assert(n.PartChanges == 3 && n.LastPart == "track");
		let parts = scope List<StringView>();
		n.CollectStyleParts(parts);
		Test.Assert(parts.IsEmpty); // a plain node paints none of its own
		Test.Assert(!n.SetMarkupAttribute("prefix", "$"));
		Test.Assert(!n.SetMarkupTemplate("row", "<Label/>"));
	}

	[Test]
	public static void AMarkupChildHostHandsEachChildOnAndIsNotDisplayed()
	{
		let target = new Node();
		defer target.ReleaseRef();
		let host = new MarkupChildHost(new [&](node) =>
			{
				while (node.ChildCount != 0)
					target.AddChild(node.GetChildAt(0));
			});
		defer host.ReleaseRef();
		Test.Assert(!host.Displayed);
		let item = new Node();
		host.AddChild(item);
		item.ReleaseRef();
		Test.Assert(host.ChildCount == 0);
		Test.Assert(target.ChildCount == 1 && item.Parent == target);
	}

	// === Directional navigation ===

	[Test]
	public static void AnOverlappingNeighbourBeatsADiagonallyNearerOneAndTheTraceSaysWhy()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		root.Size = .(400.0f, 400.0f);
		let from = Cell(root, "from", 100.0f, 100.0f);
		let diagonal = Cell(root, "diagonal", 150.0f, 130.0f); // nearer, but off the row
		let row = Cell(root, "row", 260.0f, 100.0f); // farther, on the row
		Cell(root, "behind", 20.0f, 100.0f);
		let trace = scope NavTrace();
		Test.Assert(PickInDirection(root, from, from.ScreenBounds, .Right, trace) == row);
		Test.Assert(trace.Candidates.Count == 3); // not the focused widget itself
		Test.Assert(trace.Candidates[0].Name == "UIWidget #diagonal");
		Test.Assert(trace.Candidates[0].Verdict == .Beaten);
		Test.Assert(trace.Candidates[0].Score == NavTrace.cNoOverlapTier + 10.0f + 20.0f); // along 10, 10 apart across
		Test.Assert(trace.Candidates[1].Verdict == .Chosen);
		Test.Assert(trace.Candidates[1].Score == 120.0f);
		Test.Assert(trace.Candidates[1].Bounds == Rect(260.0f, 100.0f, 40.0f, 20.0f));
		Test.Assert(trace.Candidates[2].Verdict == .Behind && trace.Candidates[2].Score < 0.0f);

		// Irregular: with nothing on the row, the nearest beyond wins.
		row.Visible = false;
		Test.Assert(NavigateFrom(root, from, .Right, trace) == diagonal);
		Test.Assert(trace.Any && (trace.Direction == .Right) && (trace.From == from.ScreenBounds));
		Test.Assert(!trace.Overridden && !trace.Wrapped);
	}

	[Test]
	public static void HiddenDisabledAndClippedAwayWidgetsAreSkipped()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		root.Size = .(400.0f, 400.0f);
		let from = Cell(root, "from", 10.0f, 10.0f);
		Cell(root, "hidden", 10.0f, 40.0f).Visible = false;
		Cell(root, "disabled", 10.0f, 70.0f).Enabled = false;
		let clipper = Area(root, 0.0f, 100.0f, 60.0f, 30.0f);
		clipper.ClipChildren = true;
		Cell(clipper, "clipped", 10.0f, 200.0f); // outside its parent's clip
		let target = Cell(root, "target", 10.0f, 160.0f);
		let trace = scope NavTrace();
		Test.Assert(NavigateFrom(root, from, .Down, trace) == target);
		Test.Assert(trace.Candidates.Count == 2); // the hidden and the disabled are not weighed
		Test.Assert(trace.Candidates[0].Name == "UIWidget #clipped" && trace.Candidates[0].Verdict == .Clipped);
		Test.Assert(trace.Candidates[1].Verdict == .Chosen && trace.Candidates[1].Score == 130.0f);
	}

	[Test]
	public static void WithNothingFocusedNavigationEntersAtTheFirstNavigableWidget()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let backdrop = Area(root, 0.0f, 0.0f, 400.0f, 400.0f);
		let first = Cell(root, "first", 100.0f, 100.0f);
		Cell(root, "second", 100.0f, 160.0f);
		let trace = scope NavTrace();
		Test.Assert(NavigateFrom(root, null, .Up, trace) == first);
		Test.Assert(trace.Any && (trace.Direction == .Up));
		Test.Assert(NavigateFrom(root, backdrop, .Down) == first); // focus on what takes none
		let elsewhere = new UIWidget();
		defer elsewhere.ReleaseRef();
		elsewhere.TabFocusable = true;
		Test.Assert(NavigateFrom(root, elsewhere, .Down) == first); // focus outside the root
	}

	[Test]
	public static void AnOverrideComesFirstNoneStopsAndAnIdNotThereFallsBackToThePicker()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let a = Cell(root, "a", 10.0f, 10.0f);
		let b = Cell(root, "b", 10.0f, 40.0f);
		let c = Cell(root, "c", 300.0f, 300.0f);
		a.NavDown = "c"; // geometry would say b
		let trace = scope NavTrace();
		Test.Assert(NavigateFrom(root, a, .Down, trace) == c);
		Test.Assert(trace.Overridden);
		b.NavRight = "none";
		bool stop = false;
		Test.Assert(FollowOverride(root, b, .NavOverrideRight, out stop) == null && stop);
		Test.Assert(NavigateFrom(root, b, .Right) == null);
		a.NavDown = "nowhere";
		Test.Assert(NavigateFrom(root, a, .Down, trace) == b);
		Test.Assert(!trace.Overridden);
		a.NavDown = "auto";
		Test.Assert(NavigateFrom(root, a, .Down) == b);
		a.NavDown = "c";
		c.Enabled = false; // there, but taking no focus: the picker
		Test.Assert(NavigateFrom(root, a, .Down) == b);
	}

	[Test]
	public static void AWrapScopeWrapsRoundItsEdges()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let menu = Area(root, 0.0f, 0.0f, 100.0f, 200.0f);
		menu.NavScope = .Wrap;
		let one = Cell(menu, "one", 10.0f, 10.0f);
		Cell(menu, "two", 10.0f, 40.0f);
		let three = Cell(menu, "three", 10.0f, 70.0f);
		Cell(root, "side", 200.0f, 40.0f); // outside the menu, to its right
		let trace = scope NavTrace();
		Test.Assert(NavigateFrom(root, three, .Down, trace) == one);
		Test.Assert(trace.Wrapped);
		Test.Assert(trace.Candidates.Count == 3); // measured from past the top: the focused one too
		Test.Assert(trace.Candidates[0].Score == 11.0f); // from y -21, 20 high: 10 - (-1)
		Test.Assert(NavigateFrom(root, one, .Up) == three);
		Test.Assert(NavigateFrom(root, one, .Left) == one); // across the line it wraps onto itself
	}

	[Test]
	public static void APassScopeHandsItsEdgeOnAndComingBackReturnsToTheRememberedWidget()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let menu = Area(root, 0.0f, 0.0f, 100.0f, 200.0f);
		menu.NavScope = .Pass;
		Cell(menu, "one", 10.0f, 10.0f);
		let two = Cell(menu, "two", 10.0f, 40.0f);
		let three = Cell(menu, "three", 10.0f, 70.0f);
		let side = Cell(root, "side", 200.0f, 40.0f);
		Test.Assert(NavigateFrom(root, two, .Right) == side); // nothing to the right inside the menu
		Test.Assert(NavigateFrom(root, side, .Left) == two); // no memory: the picked widget
		RememberInScopes(three);
		Test.Assert(menu.RememberedFocus == three);
		Test.Assert(NavigateFrom(root, side, .Left) == three); // the remembered one, not the nearest

		menu.NavScope = .Contain;
		Test.Assert(NavigateFrom(root, two, .Right) == null); // a dialog's edge
		Test.Assert(ContainingScopeOf(two) == menu);
		Test.Assert(ContainingScopeOf(side) == null);
	}

	[Test]
	public static void EnteringAScopeWithNoMemoryTakesItsDefaultFocusOrAGroupsCurrentMember()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let start = Cell(root, "start", 10.0f, 10.0f);
		let panel = Area(root, 0.0f, 100.0f, 300.0f, 100.0f);
		panel.NavScope = .Pass;
		panel.DefaultFocusId = "ok";
		let cancel = Cell(panel, "cancel", 10.0f, 10.0f); // nearest from above
		let ok = Cell(panel, "ok", 200.0f, 10.0f);
		Test.Assert(NavigateFrom(root, start, .Down) == ok);
		panel.DefaultFocusId = "missing";
		Test.Assert(NavigateFrom(root, start, .Down) == cancel);

		let group = Area(root, 0.0f, 300.0f, 300.0f, 50.0f);
		group.FocusGroup = true; // a scope that wraps, unless it says otherwise
		Test.Assert(group.NavScope == .Wrap);
		let first = new GroupMember();
		first.TabFocusable = true;
		group.AddChild(first);
		first.ReleaseRef();
		let current = new GroupMember();
		current.TabFocusable = true;
		current.Current = true;
		group.AddChild(current);
		current.ReleaseRef();
		Test.Assert(EntryInto(group, first) == current);
		current.Current = false;
		Test.Assert(EntryInto(group, first) == first);
	}

	[Test]
	public static void FocusingAPageByProgramLandsOnItsEntry()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let page = Area(root, 0.0f, 0.0f, 300.0f, 300.0f);
		page.NavScope = .Pass;
		let first = Cell(page, "first", 10.0f, 10.0f);
		let second = Cell(page, "second", 10.0f, 40.0f);
		Test.Assert(FocusTargetOf(first) == first); // it takes focus itself
		Test.Assert(FocusTargetOf(page) == first);
		page.DefaultFocusId = "second";
		Test.Assert(FocusTargetOf(page) == second);
		RememberInScopes(first);
		Test.Assert(FocusTargetOf(page) == first); // what was last focused there
		let empty = Area(root, 0.0f, 0.0f, 10.0f, 10.0f);
		Test.Assert(FocusTargetOf(empty) == null);
	}

	// === Accessibility types ===

	[Test]
	public static void AccessRolesHaveTheNamesMarkupWritesAndLeavesReadWhole()
	{
		Test.Assert(AccessRoleName(.None) == "none");
		Test.Assert(AccessRoleName(.RadioButton) == "radio");
		Test.Assert(AccessRoleName(.ProgressIndicator) == "progress");
		Test.Assert(AccessRoleName(.TextInput) == "textbox");
		Test.Assert(AccessRoleName(.MultilineTextInput) == "textarea");
		Test.Assert(AccessRoleName(.ScrollBar) == "scrollbar");
		for (int i = 0; i < (int)AccessRole.Count; i++)
		{
			AccessRole named = .None;
			Test.Assert(AccessRoleNamed(AccessRoleName((AccessRole)i), out named) && (named == (AccessRole)i));
		}
		AccessRole role = .Button;
		Test.Assert(!AccessRoleNamed("bogus", out role));

		Test.Assert(IsLeafRole(.Button) && IsLeafRole(.Row) && IsLeafRole(.ScrollBar) && IsLeafRole(.Label));
		Test.Assert(!IsLeafRole(.None) && !IsLeafRole(.List) && !IsLeafRole(.Window) && !IsLeafRole(.ScrollView));
	}

	[Test]
	public static void AnAccessNodesStatesAndActionsAreOneBitEach()
	{
		Test.Assert(AccessFocusable == 1 && AccessCollapsed == 128 && AccessOffscreen == 512);
		Test.Assert(AccessActionBit(.Focus) == 1 && AccessActionBit(.Expand) == 64 && AccessActionBit(.Collapse) == 128);
		let node = scope AccessNode();
		node.States = AccessChecked | AccessFocused;
		node.Actions = AccessActionBit(.Activate);
		Test.Assert(node.Has(AccessChecked) && node.Has(AccessFocused) && !node.Has(AccessMixed));
		Test.Assert(node.Takes(.Activate) && !node.Takes(.SetValue));
		Test.Assert(IsAccessItemId(cAccessItemIdBit | 5) && !IsAccessItemId(5));
	}

	[Test]
	public static void AnUpdateFindsItsNodesAndCopiesDeeply()
	{
		let update = scope AccessTreeUpdate();
		update.Root = 1;
		let node = new AccessNode();
		node.Id = 7;
		node.Name.Set("Save");
		node.Children.Add(9);
		update.Nodes.Add(node);
		Test.Assert(update.Find(7) == node && update.Find(8) == null);

		let bridge = scope RecordingBridge();
		IAccessibilityBridge asBridge = bridge;
		Test.Assert(asBridge.IsListening);
		asBridge.Update(update);
		asBridge.Announce("Level loaded", .Polite);
		node.Name.Set("Changed");
		node.Children.Add(10);
		let kept = bridge.Updates[0].Find(7);
		Test.Assert(kept != null && kept !== node);
		Test.Assert(kept.Name == "Save" && kept.Children.Count == 1 && bridge.Updates[0].Root == 1);
		Test.Assert(bridge.Spoken.Count == 1 && bridge.Spoken[0] == "Level loaded");
	}

	/// A neighbour that touches or overlaps a little is still beyond, within a quarter of the
	/// smaller one's size; one that overlaps more is not.
	[Test]
	public static void ANeighbourOverlappingALittleIsStillBeyondButNotOneOverlappingMore()
	{
		let from = Rect(0.0f, 0.0f, 100.0f, 40.0f);
		Test.Assert(NavigationDetail.Score(from, Rect(0.0f, 35.0f, 100.0f, 40.0f), .Down) >= 0.0f, "5 px over, inside the 10 px slack");
		Test.Assert(NavigationDetail.Score(from, Rect(0.0f, 25.0f, 100.0f, 40.0f), .Down) < 0.0f, "15 px over, past it");
		Test.Assert(NavigationDetail.Score(from, Rect(0.0f, 50.0f, 100.0f, 40.0f), .Down) >= 0.0f);
		Test.Assert(NavigationDetail.Score(from, Rect(0.0f, 50.0f, 100.0f, 40.0f), .Up) < 0.0f, "behind");
	}
}
