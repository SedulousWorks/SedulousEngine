using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// One picture under one path, every load counted.
class OnePicture : IResourceProvider
{
	public OwnedImageData Img = WidgetFixtures.MakeImage() ~ delete _;
	public int Loads = 0;

	public override ImageData LoadImage(StringView path)
	{
		++Loads;
		return (path == "pic.png") ? Img : null;
	}

	public override bool LoadText(StringView path, String outText) => false;

	public override SVGDocument LoadSvg(StringView path) => null;
}

/// The simple widgets beyond the ported tests: each element type built by its tag through its GUI
/// table and its reflected properties set by a sheet's CSS names; the reflection's flags and
/// access names and each widget's role; a label's text followed by a binding and its access key
/// underlined only while access keys show; an image's `src` loaded once when first needed; an
/// exponential slider's press and its keys at the ends; a scroll bar's thumb no shorter than its
/// least, dragged from where it was grabbed; a splitter handle's value read and written as a
/// separator's; Node's default tooltip, drop hint and drag preview, and the preview's badge; the
/// disclosure chevron mirrored in right to left.
class SimpleWidgetsTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A new instance of `info`'s type made by its creator, held by the caller; null when it has
	/// none.
	private static Node Make(GuiTypeInfo info) => info.Create() as Node;

	[Test]
	public static void EachElementTypeIsMadeByItsCreatorUnderItsTypesNameTheRestHaveNone()
	{
		GuiTypeInfo[12] elements = .(Label.StaticGuiType, RichText.StaticGuiType, Sedulous.GUI.Image.StaticGuiType, Panel.StaticGuiType,
			ScrollView.StaticGuiType, Separator.StaticGuiType, Spacer.StaticGuiType, Splitter.StaticGuiType, Slider.StaticGuiType,
			ProgressBar.StaticGuiType, ScrollBar.StaticGuiType, ListBox.StaticGuiType);
		String[12] tags = .("Label", "RichText", "Image", "Panel", "ScrollView", "Separator", "Spacer", "Splitter", "Slider",
			"ProgressBar", "ScrollBar", "ListBox");
		String[12] cssTags = .("label", "richtext", "image", "panel", "scrollview", "separator", "spacer", "splitter", "slider",
			"progressbar", "scrollbar", "listbox");
		for (int i = 0; i < elements.Count; i++)
		{
			let info = elements[i];
			Test.Assert(info.Tag == tags[i], scope $"{tags[i]}: tagged {info.Tag}");
			Test.Assert(info.CanCreate);
			let made = Make(info);
			Test.Assert(made != null);
			Test.Assert(made.GetType() == info.Type);
			Test.Assert(made.GuiType == info); // an instance answers for its own type
			Test.Assert((made as UIWidget).Tag == cssTags[i]); // what a sheet selects it by
			made.ReleaseRef();
		}
		// Reflected, but no element: markup builds none of them by a tag.
		Test.Assert(!RangeWidget.StaticGuiType.CanCreate);
		Test.Assert(!SplitterHandle.StaticGuiType.CanCreate);
		Test.Assert(!DragPreview.StaticGuiType.CanCreate);
		Test.Assert(RangeWidget.StaticGuiType.Create() == null);
		// Each answers for its own type, its base's table after it.
		Test.Assert(Slider.StaticGuiType.Is(RangeWidget.StaticGuiType));
		Test.Assert(RichText.StaticGuiType.Is(Label.StaticGuiType));
		Test.Assert(DragPreview.StaticGuiType.Is(Label.StaticGuiType));
		Test.Assert(!Panel.StaticGuiType.Is(Label.StaticGuiType));
	}

	[Test]
	public static void ASheetSetsEachWidgetsReflectedPropertiesByTheirCSSNames()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let label = Make(Label.StaticGuiType) as Label;
		defer label.ReleaseRef();
		let separator = Make(Separator.StaticGuiType) as Separator;
		defer separator.ReleaseRef();
		let spacer = Make(Spacer.StaticGuiType) as Spacer;
		defer spacer.ReleaseRef();
		let splitter = Make(Splitter.StaticGuiType) as Splitter;
		defer splitter.ReleaseRef();
		let slider = Make(Slider.StaticGuiType) as Slider;
		defer slider.ReleaseRef();
		let bar = Make(ProgressBar.StaticGuiType) as ProgressBar;
		defer bar.ReleaseRef();
		let scrollBar = Make(ScrollBar.StaticGuiType) as ScrollBar;
		defer scrollBar.ReleaseRef();
		let list = Make(ListBox.StaticGuiType) as ListBox;
		defer list.ReleaseRef();
		let image = Make(Sedulous.GUI.Image.StaticGuiType) as Sedulous.GUI.Image;
		defer image.ReleaseRef();
		Node[9] all = .(label, separator, spacer, splitter, slider, bar, scrollBar, list, image);
		for (let node in all)
			root.AddChild(node);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles,
			"label { text-overflow: ellipsis-start; line-clamp: 2; } " +
			"separator { thickness: 3; } spacer { size: 8; } " +
			"splitter { axis: vertical; weights: 1 3; } " +
			"slider { min: 10; max: 20; step: 2; page: 4; orientation: vertical; ticks: 5; } " +
			"progressbar { indeterminate: true; max: 4; value: 1; } " +
			"scrollbar { orientation: horizontal; page: 25; } " +
			"listbox { items: One|Two|Three; } " +
			"image { src: pic.png; object-fit: cover; object-position: right top; image-color: #ff000080; }");
		styles.ApplyTree(root);

		Test.Assert(label.TextOverflow == .EllipsisStart);
		Test.Assert(label.TextOverflowName == "ellipsis-start");
		Test.Assert(label.LineClamp == 2);
		Test.Assert(Near(separator.Thickness, 3.0f));
		Test.Assert(Near(spacer.Space, 8.0f));
		Test.Assert(splitter.Axis == .Vertical);
		Test.Assert(splitter.WeightsText == "1 3");
		Test.Assert(Near(slider.Min, 10.0));
		Test.Assert(Near(slider.Max, 20.0));
		Test.Assert(Near(slider.Step, 2.0));
		Test.Assert(Near(slider.Value, 10.0)); // into the new range
		Test.Assert(Near(slider.Page, 4.0));
		Test.Assert(slider.Orientation == .Vertical);
		Test.Assert(slider.Ticks == 5);
		Test.Assert(bar.Indeterminate);
		Test.Assert(Near(bar.Ratio, 0.25));
		Test.Assert(scrollBar.Orientation == .Horizontal);
		Test.Assert(Near(scrollBar.Page, 25.0));
		Test.Assert(Near(scrollBar.ThumbProportion, 1.0f)); // the page passes the range of 1
		Test.Assert(list.ItemCount == 3);
		Test.Assert(list.GetItem(2) == "Three");
		Test.Assert(list.ItemsText == "One|Two|Three");
		Test.Assert(image.Source == "pic.png");
		Test.Assert(image.Fit == .Cover);
		Test.Assert(image.ObjectPositionName == "100% 0%");
		Test.Assert(Near(image.ImageColor.A, 128.0f / 255.0f));

		// The rule gone, each takes back its own.
		WidgetFixtures.UseSheet(styles, "panel { opacity: 1; }");
		styles.ApplyTree(root);
		Test.Assert(label.TextOverflow == .Clip);
		Test.Assert(Near(separator.Thickness, 1.0f));
		Test.Assert(splitter.Axis == .Horizontal);
		Test.Assert(slider.Orientation == .Horizontal);
		Test.Assert(!bar.Indeterminate);
		Test.Assert(image.Fit == .Fill);
		Test.Assert(image.ObjectPositionName == "50% 50%");
	}

	[Test]
	public static void TheReflectionCarriesEachPropertysFlagsAndAccessNameAndEachWidgetItsRole()
	{
		let text = Label.StaticGuiType.Find("text");
		Test.Assert(text != null);
		Test.Assert(text.IsTranslatable);
		Test.Assert(text.Access == "name");
		Test.Assert(Label.StaticGuiType.Find("textColor") != null); // a tween's and a binding's name for it
		Test.Assert(Label.StaticGuiType.FindCss("line-clamp") != null);
		let value = Slider.StaticGuiType.Find("value"); // the range's, through the slider
		Test.Assert(value != null);
		Test.Assert(value.IsTwoWay);
		Test.Assert(value.Access == "value");
		Test.Assert(value.ValueType == typeof(double));
		Test.Assert(Slider.StaticGuiType.FindCss("allow-greater") != null);
		Test.Assert(ProgressBar.StaticGuiType.Find("page") == null); // a progress bar hides its page
		let handleMax = SplitterHandle.StaticGuiType.Find("max");
		Test.Assert(handleMax != null);
		Test.Assert(!handleMax.CanWrite);
		Test.Assert(handleMax.Access == "max");
		Test.Assert(Spacer.StaticGuiType.FindCss("size").Name == "Space");

		UIWidget[12] widgets = .(new Label(), new Sedulous.GUI.Image(), new ScrollView(), new Separator(), new SplitterHandle(),
			new Slider(), new ProgressBar(), new ScrollBar(), new ListBox(), new Panel(), new RichText(), new DragPreview());
		String[12] roles = .("label", "image", "scrollview", "separator", "separator", "slider", "progress", "scrollbar", "list",
			"", "label", "label");
		for (int i = 0; i < widgets.Count; i++)
		{
			Test.Assert(widgets[i].AccessRoleName == roles[i], scope $"{widgets[i].Tag}: {widgets[i].AccessRoleName}");
			widgets[i].ReleaseRef();
		}
	}

	[Test]
	public static void ALabelsTextIsFollowedByABindingAndItsAccessKeyUnderlinedOnlyWhileAccessKeysShow()
	{
		let font = scope CachedFont(new MockFont(), null); // owns and deletes the mock
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		label.Font = font;
		label.Size = .(100.0f, 20.0f);
		root.AddChild(label);

		int runs = 0;
		let seen = scope String();
		let effect = scope Effect(new [&] () =>
			{
				runs++;
				seen.Set(label.Text);
			});
		Test.Assert(runs == 1);
		label.Text = "File";
		Test.Assert(runs == 2); // its read followed it
		Test.Assert(seen == "File");
		label.Text = "File"; // the same text: nothing to follow
		Test.Assert(runs == 2);
		Test.Assert(effect.RunCount == 2);

		label.SetMnemonicRange(0, 1); // the F
		let area = Rect(0.0f, 0.0f, 100.0f, 20.0f);
		WidgetFixtures.DrawnVertices(label);
		Test.Assert(label.GetTextLayout().LayoutFor(area).Underlines.Count == 0); // access keys hidden
		root.EventDispatcher.MnemonicsAlwaysShown = true;
		WidgetFixtures.DrawnVertices(label);
		let shown = label.GetTextLayout().LayoutFor(area);
		Test.Assert(shown.Underlines.Count == 1);
		Test.Assert(Near(shown.Underlines[0].Rect.Width, 6.0f)); // one 6-wide glyph
		label.SetMnemonicRange(0, 0); // none
		Test.Assert(label.GetTextLayout().LayoutFor(area).Underlines.Count == 0);
	}

	[Test]
	public static void AnImagesSrcLoadsThroughTheGUIsResourcesOnceWhenFirstNeeded()
	{
		let resources = scope OnePicture();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		root.Context.ResourceProvider = resources;
		let w = new Sedulous.GUI.Image();
		defer w.ReleaseRef();
		w.Source = "pic.png";
		Test.Assert(resources.Loads == 0); // not yet in a GUI
		Test.Assert(!w.IntrinsicSize.HasValue);
		root.AddChild(w);
		root.UpdateLayout();
		Test.Assert(resources.Loads == 1);
		Test.Assert(Near(w.Size.X, 4.0f));
		Test.Assert(Near(w.Size.Y, 2.0f));
		root.UpdateLayout();
		Test.Assert(resources.Loads == 1); // once
		w.Source = "other.png"; // a path it has none for: no picture, and asked once
		root.UpdateLayout();
		Test.Assert(resources.Loads == 2);
		Test.Assert(w.Drawable == null);
		Test.Assert(Near(w.Size.X, 0.0f));
	}

	[Test]
	public static void AnExponentialSlidersPressGoesByLogarithmAndItsKeysStopAtItsEnds()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let s = new Slider();
		defer s.ReleaseRef();
		s.Size = .(100.0f, 20.0f); // the thumb's centre within x 10 to 90
		s.Min = 1.0;
		s.Max = 100.0;
		s.Exponential = true;
		root.AddChild(s);
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(50.0f, 10.0f), .Left); // half way: the geometric middle
		d.InjectMouseUp(.(50.0f, 10.0f), .Left);
		Test.Assert(Near(s.Value, 10.0, 1.0e-4));
		Test.Assert(Near(s.Ratio, 0.5, 1.0e-4));
		s.RequestFocus();
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.End));
		Test.Assert(Near(s.Value, 100.0));
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.Right)); // at its end: still its key
		Test.Assert(Near(s.Value, 100.0));
		Test.Assert(s.IsFocused);
		d.InjectKeyDown((uint32)KeyCode.Left, KeyModShift); // with a modifier: not its
		Test.Assert(Near(s.Value, 100.0));
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.Home));
		Test.Assert(Near(s.Value, 1.0));
	}

	[Test]
	public static void AScrollBarsThumbIsNoShorterThanItsLeastAndDragsFromWhereItWasGrabbed()
	{
		let root = SceneFixtures.NewScene(300.0f, 100.0f);
		defer root.ReleaseRef();
		let bar = new ScrollBar();
		defer bar.ReleaseRef();
		bar.Orientation = .Horizontal;
		bar.Size = .(200.0f, 12.0f);
		bar.Max = 1000.0;
		bar.Page = 10.0; // a hundredth: 2 pixels, held at 16
		root.AddChild(bar);
		Test.Assert(Near(bar.ThumbProportion, 0.01f));
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(8.0f, 6.0f), .Left); // on the thumb (0 to 16): grabbed, no page
		Test.Assert(Near(bar.Value, 0.0));
		d.InjectMouseMove(.(100.0f, 6.0f)); // 92 of the 184 it travels: half the range less the page
		Test.Assert(Near(bar.Value, 495.0));
		d.InjectMouseUp(.(100.0f, 6.0f), .Left);
		// Beyond the thumb a press pages: by its page, but never less than a key's step (a
		// twentieth of the range).
		d.InjectMouseDown(.(190.0f, 6.0f), .Left);
		Test.Assert(Near(bar.Value, 545.0));
		d.InjectMouseUp(.(190.0f, 6.0f), .Left);
	}

	[Test]
	public static void ASplitterHandleReadsAsASeparatorWhoseValueIsWhereItStandsAndWritingItMovesIt()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let splitter = new Splitter();
		defer splitter.ReleaseRef();
		splitter.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(206.0f); // 200 for the panes, beside one 6-wide handle
				s.Height = LayoutLength.Px(100.0f);
			});
		let a = new Panel();
		defer a.ReleaseRef();
		let b = new Panel();
		defer b.ReleaseRef();
		splitter.AddChild(a);
		splitter.AddChild(b);
		root.AddChild(splitter);
		root.UpdateLayout();
		let handle = splitter.GetHandle(0);
		Test.Assert(handle != null);
		Test.Assert(handle.Index == 0);
		Test.Assert(handle.Splitter == splitter);
		Test.Assert(handle.TabFocusable);
		Test.Assert(handle.HasClass("horizontal"));
		Test.Assert(handle.Cursor == .EwResize);
		Test.Assert(Near(handle.Value, 50.0));
		int resized = 0;
		splitter.SetOnResized(new [&] () => { resized++; });
		handle.Value = 25.0;
		root.UpdateLayout();
		Test.Assert(Near(a.Size.X, 50.0f));
		Test.Assert(Near(b.Size.X, 150.0f));
		Test.Assert(Near(handle.Value, 25.0));
		Test.Assert(resized == 1);
		// Through the reflection, as a screen reader's value change comes.
		var v = System.Variant.Create(75.0);
		defer v.Dispose();
		Test.Assert(SplitterHandle.StaticGuiType.Find("value").Set(handle, v));
		root.UpdateLayout();
		Test.Assert(Near(a.Size.X, 150.0f));
		splitter.Axis = .Vertical;
		Test.Assert(handle.HasClass("vertical"));
		Test.Assert(!handle.HasClass("horizontal"));
		Test.Assert(handle.Cursor == .NsResize);
	}

	[Test]
	public static void NodesDefaultTooltipDropHintAndDragPreviewAreTheWidgetsOnes()
	{
		let font = scope CachedFont(new MockFont(), null);
		let source = new Label();
		defer source.ReleaseRef();
		source.Font = font;

		let tip = source.CreateTooltipContent("Saves the file") as Tooltip;
		Test.Assert(tip != null);
		Test.Assert(tip.Text == "Saves the file");
		Test.Assert(tip.Tag == "tooltip");
		Test.Assert(!tip.HitTestVisible); // never steals pointer events
		Test.Assert(Near(tip.Padding.Left, 6.0f));
		Test.Assert(tip.BoxFills); // its own face
		tip.ReleaseRef();

		let hint = source.CreateDropHint("No room", true) as Tooltip;
		Test.Assert(hint != null);
		Test.Assert(hint.Text == "No room");
		Test.Assert(hint.HasClass("drophint"));
		Test.Assert(hint.HasClass("refused"));
		Test.Assert(hint.Font === font); // in the source's font
		hint.ReleaseRef();
		let taken = source.CreateDropHint("Paint it", false);
		Test.Assert(!(taken as UIWidget).HasClass("refused"));
		taken.ReleaseRef();

		let payload = scope DragPayload();
		payload.Label.Set("Ace of spades");
		let preview = source.CreateDragPreview(payload) as DragPreview;
		Test.Assert(preview != null);
		Test.Assert(preview.Text == "Ace of spades");
		Test.Assert(preview.Tag == "dragpreview");
		Test.Assert(preview.Font === font);
		Test.Assert(preview.Effect == .Move);
		preview.ReleaseRef();

		let plain = new Node(); // no text style to share: the preview keeps its own
		defer plain.ReleaseRef();
		let bare = plain.CreateDragPreview(payload) as DragPreview;
		Test.Assert(bare.Font == null);
		bare.ReleaseRef();
	}

	[Test]
	public static void ADragPreviewsBadgeShowsWhatADropWouldDoAndNothingForAMove()
	{
		let preview = new DragPreview();
		defer preview.ReleaseRef();
		preview.Size = .(120.0f, 24.0f);
		Test.Assert(WidgetFixtures.DrawnVertices(preview) == 0); // a move: no badge (and no text without a font)
		preview.OnDragPreviewEffect(.Copy);
		Test.Assert(preview.Effect == .Copy);
		let copy = WidgetFixtures.DrawnVertices(preview);
		Test.Assert(copy > 0);
		preview.OnDragPreviewEffect(.None);
		Test.Assert(WidgetFixtures.DrawnVertices(preview) > copy); // a barred circle draws more than a plus
		preview.OnDragPreviewEffect(.Move);
		Test.Assert(WidgetFixtures.DrawnVertices(preview) == 0);
	}

	/// How far left, right, up and down the vertices `draw` makes reach (their fringe included).
	private static Rect Extent(delegate void(DrawContext ctx) draw)
	{
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		draw(dc);
		var area = Rect();
		bool first = true;
		for (let v in canvas.GetBatch().Vertices)
		{
			let p = Rect(v.Position.X, v.Position.Y, 0.0f, 0.0f);
			area = first ? p : Rect.Merge(area, p);
			first = false;
		}
		return area;
	}

	[Test]
	public static void TheDisclosureChevronPointsTowardTheInlineEndClosedAndDownOpen()
	{
		let area = Rect(0.0f, 0.0f, 20.0f, 20.0f); // centred on 10, 4 its half size
		let ltr = Extent(scope (ctx) => { DrawDisclosure(ctx, area, false, Color.White, false); });
		let rtl = Extent(scope (ctx) => { DrawDisclosure(ctx, area, false, Color.White, true); });
		let open = Extent(scope (ctx) => { DrawDisclosure(ctx, area, true, Color.White, false); });
		Test.Assert(ltr.Width > 0.0f);
		// Closed, its point (three quarters of a size ahead) reaches further than its back (half one
		// behind): it points right, and in right to left its mirror, left.
		Test.Assert(ltr.Right - 10.0f > 10.0f - ltr.Left);
		Test.Assert(Near(rtl.Left, 20.0f - ltr.Right));
		Test.Assert(Near(rtl.Right, 20.0f - ltr.Left));
		Test.Assert(Near(rtl.Y, ltr.Y));
		// Open, it is as wide as it is across both sides of its centre, and reaches further down
		// (three quarters of a size) than up (a half).
		Test.Assert(Near(open.Left + open.Right, 20.0f));
		Test.Assert(open.Bottom - 10.0f > 10.0f - open.Top);
		Test.Assert(open.Width > ltr.Width);
	}
}
