using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// English and Portuguese texts, with English's plural rule. The table and the resolver go with
/// it.
class TranslationTexts
{
	public Sedulous.I18N.StringTable Table = new .() ~ delete _;
	public Sedulous.I18N.Localization Loc = new .() ~ delete _;

	public this()
	{
		Test.Assert(Table.Set("menu.play", "en", "Play"));
		Test.Assert(Table.Set("menu.play", "pt", "Jogar"));
		Test.Assert(Table.Set("menu.tip", "en", "Start the game"));
		Test.Assert(Table.Set("field.hint", "en", "Your name"));
		Test.Assert(Table.Set("greet", "en", "Hello, {0}"));
		Test.Assert(Table.SetPluralRule("en", "one: n = 1"));
		Test.Assert(Table.SetPlural("lives", "en", .One, "{0} life"));
		Test.Assert(Table.SetPlural("lives", "en", .Other, "{0} lives"));
		Loc.AddTable(Table);
	}
}

/// A GUI whose markup binds to its data. The root goes with it.
class TranslationBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();

	/// `markup` inflated with the GUI's data model; null when it does not load. The caller releases
	/// what comes back.
	public Node Load(StringView markup)
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		loader.SetDataModel(Root.Context.Data);
		return loader.LoadFromString(markup);
	}

	public void Step()
	{
		Root.Context.Update(SceneFixtures.Seconds(1.0 / 60.0));
	}
}

/// Translation: markup's @key resolves through the context's Localization, follows a language
/// change, takes a plural count and arguments from the GUI's data, waits for a node to join a GUI,
/// stops under auto-translate off; :lang() matches a node's language.
class TranslationTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	private static Node Find(Node node, StringView id) => MarkupFixtures.Find(node, id);

	[Test]
	public static void MarkupsKeyResolvesThroughTheContextsLocalizationAndFollowsALanguageChange()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let page = bed.Load(
			"<Panel>\n" +
			"    <Label id=\"title\" text=\"@menu.play\"/>\n" +
			"    <Button id=\"go\" text=\"@menu.play\" tooltip=\"@menu.tip\"/>\n" +
			"    <TextField id=\"name\" placeholder=\"@field.hint\"/>\n" +
			"    <Label id=\"literal\" text=\"@@home\"/>\n" +
			"    <Label id=\"plain\" text=\"Plain words\"/>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		bed.Step();
		Test.Assert((Find(page, "title") as Label).Text == "Play");
		Test.Assert((Find(page, "go") as Button).Text == "Play");
		Test.Assert((Find(page, "go") as UIWidget).TooltipText == "Start the game");
		Test.Assert((Find(page, "name") as TextField).Placeholder == "Your name");
		Test.Assert((Find(page, "literal") as Label).Text == "@home"); // @@ is a literal @
		Test.Assert((Find(page, "plain") as Label).Text == "Plain words");
		Test.Assert(Find(page, "title").TranslationKey("Text") != null);

		texts.Loc.SetLanguage("pt");
		bed.Step();
		Test.Assert((Find(page, "title") as Label).Text == "Jogar");
		Test.Assert((Find(page, "go") as UIWidget).TooltipText == "Start the game"); // English's, the fallback

		bed.Root.Context.Localization = null; // none: a key shows as itself
		bed.Step();
		Test.Assert((Find(page, "title") as Label).Text == "menu.play");
	}

	[Test]
	public static void ACountAndArgumentsFromTheGUIsDataPickThePluralFormAndFillIt()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let data = bed.Root.Context.Data;
		data.Set("lives", System.Variant.Create((int32)1));
		data.Set("player", System.Variant.Create("Ana"));
		let page = bed.Load(
			"<Panel>\n" +
			"    <Label id=\"lives\" text=\"@lives\" text-count=\"{{lives}}\"/>\n" +
			"    <Label id=\"greet\" text=\"@greet\" text-args=\"{{player}}\"/>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		bed.Step();
		Test.Assert((Find(page, "lives") as Label).Text == "1 life");
		Test.Assert((Find(page, "greet") as Label).Text == "Hello, Ana");
		data.Set("lives", System.Variant.Create((int32)3));
		data.Set("player", System.Variant.Create("Rui"));
		bed.Step();
		Test.Assert((Find(page, "lives") as Label).Text == "3 lives");
		Test.Assert((Find(page, "greet") as Label).Text == "Hello, Rui");
	}

	[Test]
	public static void ANodeMadeBeforeItJoinsAGUIResolvesWhenItJoinsAutoTranslateOffKeepsKeys()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let page = bed.Load(
			"<Panel>\n" +
			"    <Label id=\"title\" text=\"@menu.play\"/>\n" +
			"    <Panel id=\"raw\" auto-translate=\"off\">\n" +
			"        <Label id=\"inside\" text=\"@menu.play\"/>\n" +
			"    </Panel>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		Test.Assert((Find(page, "title") as Label).Text == "menu.play"); // in no GUI yet
		bed.Root.AddChild(page);
		bed.Step();
		Test.Assert((Find(page, "title") as Label).Text == "Play");
		// auto-translate is set by the style pass (an inline style); set it here as that pass would.
		Find(page, "raw").SetAutoTranslate(.Off);
		bed.Step();
		Test.Assert((Find(page, "inside") as Label).Text == "menu.play");
		Find(page, "raw").SetAutoTranslate(.Inherit);
		bed.Step();
		Test.Assert((Find(page, "inside") as Label).Text == "Play");
	}

	[Test]
	public static void APropertyNotMarkedTranslatableTakesAtLiterally()
	{
		let bed = scope TranslationBed();
		let page = bed.Load("<Panel id=\"@not-a-key\"/>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		Test.Assert((page as UIWidget).Id == "@not-a-key");
	}

	[Test]
	public static void LangMatchesANodesLanguageItsOwnOrTheGUIsAndALanguageChangeRestyles()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let page = new Panel();
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		let arabic = new Panel();
		defer arabic.ReleaseRef();
		arabic.Lang = "ar-EG";
		page.AddChild(arabic);
		let inside = new Panel();
		defer inside.ReleaseRef();
		arabic.AddChild(inside);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "panel { opacity: 1; } panel:lang(pt) { opacity: 0.5; } panel:lang(ar) { opacity: 0.25; }");
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(page.Alpha, 1.0f)); // English
		Test.Assert(Near(arabic.Alpha, 0.25f));
		Test.Assert(Near(inside.Alpha, 0.25f)); // inherited
		Test.Assert(inside.Language(.. scope String()) == "ar-EG");
		texts.Loc.SetLanguage("pt-BR");
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(page.Alpha, 0.5f)); // pt-BR under :lang(pt)
		Test.Assert(Near(arabic.Alpha, 0.25f));
	}

	[Test]
	public static void AnAttributeEndingInCountOrArgsIsTheWidgetsOwnUnlessItsPropertyIsAKey()
	{
		let bed = scope TranslationBed();
		let page = bed.Load("<Panel id=\"box\" animation-iteration-count=\"3\" tooltip-args=\"kept\"/>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		let node = page as UINode;
		bool count = false;
		bool args = false;
		for (let d in node.InlineStyle)
		{
			count = count || (d.Name == "animation-iteration-count");
			args = args || (d.Name == "tooltip-args");
		}
		Test.Assert(count); // not taken for a translation's count
		Test.Assert(args); // tooltip is no @key here
	}

	[Test]
	public static void APropertyMarkupNamesByItsCssNameTakesKeyAndBindingByThatName()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		bed.Root.Context.Data.Set("who", System.Variant.Create("Ana"));
		let page = bed.Load(
			"<Panel>\n" +
			"    <Button id=\"go\" aria-label=\"@menu.play\"/>\n" +
			"    <Button id=\"named\" aria-label=\"{{who}}\"/>\n" +
			"</Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		bed.Step();
		Test.Assert((Find(page, "go") as UIWidget).AccessLabel == "Play");
		Test.Assert((Find(page, "named") as UIWidget).AccessLabel == "Ana");
		Test.Assert(Find(page, "go").TranslationKey("AccessLabel") != null); // recorded by its own name
	}

	[Test]
	public static void BindingAPropertyAgainReplacesItsBindingATranslationsIncluded()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let data = bed.Root.Context.Data;
		data.Set("a", System.Variant.Create("first"));
		data.Set("b", System.Variant.Create("second"));
		let label = new Label();
		defer label.ReleaseRef();
		bed.Root.AddChild(label);
		Test.Assert(label.BindTranslation("text", "menu.play", bed.Root.Context.Data));
		let bindings = label.BindingCount;
		Test.Assert(label.BindData("text", bed.Root.Context.Data, "a"));
		Test.Assert(label.BindData("text", bed.Root.Context.Data, "b"));
		bed.Step();
		Test.Assert(label.Text == "second");
		Test.Assert(label.TranslationKey("Text") == null); // no longer translated
		data.Set("a", System.Variant.Create("changed"));
		texts.Loc.SetLanguage("pt");
		bed.Step();
		Test.Assert(label.Text == "second"); // neither the old data binding nor the translation runs
		Test.Assert(label.BindingCount <= bindings + 1); // the data binding, and its write-back at most
	}
}
