using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The API a consumer reaches for that the port itself does not happen to call.
///
/// A method nothing internal uses is exactly the one that quietly goes missing, so these are
/// here to keep the surface honest rather than because the machinery below them is in doubt.
class PublicApiTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	// ---- StyleSheet's own resolution ----------------------------------------------------------

	/// A sheet can be asked directly for a view's value, without going through the view.
	///
	/// This sees ONLY this sheet: no inline style, no local sheets, no inheritance. That is
	/// what separates it from View.ResolveStyle, and it is why a tool inspecting one sheet in
	/// isolation wants it.
	[Test]
	public static void ASheetResolvesAViewsValueOnItsOwn()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		let sheet = loader.Load("""
			TestView {
				background-color: #ff0000;
				width: 42;
				padding: 3 4;
				word-wrap: true;
			}
			""");

		let view = new TestView(10, 10);
		root.AddView(view);
		// SetStyleSheet CONSUMES the reference; the context releases it.
		context.SetStyleSheet(sheet);

		// `background-color` stores Background as a raw colour rather than a drawable.
		Test.Assert(sheet.ResolveColor(view, .Background) == Color(1, 0, 0, 1));
		Test.Assert(sheet.ResolveFloat(view, .Width) == 42);
		Test.Assert(sheet.ResolveThickness(view, .Padding) == Thickness(4, 3, 4, 3));

		// A property the sheet says nothing about answers the default it was given.
		Test.Assert(sheet.ResolveFloat(view, .CornerRadius, 7.0f) == 7);
		Test.Assert(sheet.ResolveColor(view, .BorderColor, Color.White) == Color.White);
		Test.Assert(sheet.ResolveBool(view, .WordWrap));
		Test.Assert(sheet.ResolveDrawable(view, .Background) == null, "a colour, not a drawable");
		Test.Assert(sheet.Resolve(view, .BorderWidth) case .None);
	}

	/// It resolves at the view's OWN control state, so a state rule applies once the view is
	/// in that state and not before.
	[Test]
	public static void ASheetResolvesAtTheViewsCurrentState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		let sheet = loader.Load("""
			Button { background-color: #101010; }
			Button:disabled { background-color: #202020; }
			""");

		let button = new Button("Test");
		root.AddView(button);
		context.SetStyleSheet(sheet);

		Test.Assert(sheet.ResolveColor(button, .Background).R == 16 / 255.0f);

		button.IsEnabled = false;
		Test.Assert(sheet.ResolveColor(button, .Background).R == 32 / 255.0f);
	}

	// ---- The built-in type registry -----------------------------------------------------------

	/// Loading a sheet registers every built-in type name, so element selectors resolve without
	/// the host naming its controls one at a time.
	[Test]
	public static void InitializingGlobalsRegistersEveryBuiltInType()
	{
		UITypeRegistry.Clear();
		StyleSheetLoader.InitializeGlobals();

		// The base, a layout, a layout's short alias, a control, and an overlay.
		Test.Assert(UITypeRegistry.Resolve("View") == typeof(View));
		Test.Assert(UITypeRegistry.Resolve("FlexLayout") == typeof(FlexLayout));
		Test.Assert(UITypeRegistry.Resolve("Flex") == typeof(FlexLayout), "markup reads better short");
		Test.Assert(UITypeRegistry.Resolve("EditText") == typeof(EditText));
		Test.Assert(UITypeRegistry.Resolve("ContextMenu") == typeof(ContextMenu));
		Test.Assert(UITypeRegistry.Resolve("Dialog") == typeof(Dialog));

		Test.Assert(UITypeRegistry.Resolve("NotAControl") == null);
	}

	/// It is idempotent, so a host calling it per sheet load does not pay for it twice.
	[Test]
	public static void RegisteringTheBuiltInsTwiceIsHarmless()
	{
		UITypeRegistry.Clear();
		UITypeRegistry.RegisterBuiltins();
		let countAfterFirst = UITypeRegistry.Count;

		UITypeRegistry.RegisterBuiltins();

		Test.Assert(UITypeRegistry.Count == countAfterFirst);
	}

	/// Clearing forgets the guard too, or a cleared registry could never be repopulated. Tests
	/// clear between runs, so this is the difference between isolated and broken.
	[Test]
	public static void ClearingTheRegistryLetsTheBuiltInsBackIn()
	{
		UITypeRegistry.RegisterBuiltins();
		UITypeRegistry.Clear();
		Test.Assert(UITypeRegistry.Resolve("Button") == null);

		UITypeRegistry.RegisterBuiltins();
		Test.Assert(UITypeRegistry.Resolve("Button") == typeof(Button));
	}

	/// A registered type name is what an element selector matches on, end to end.
	[Test]
	public static void AnElementSelectorMatchesARegisteredTypeName()
	{
		UITypeRegistry.Clear();
		StyleSheetLoader.InitializeGlobals();

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		let sheet = loader.Load("Button { width: 123; }");
		context.SetStyleSheet(sheet);

		let button = new Button("Test");
		root.AddView(button);

		Test.Assert(sheet.ResolveFloat(button, .Width) == 123);
	}
}
