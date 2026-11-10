using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget from outside the GUI's core (as a toolkit or a game kit adds one): reflected with a
/// creator and registered under a tag of its own.
[GuiReflect(true, "game:HealthBar")]
class HealthBar : UIWidget
{
	public float Health = 1.0f;
}

/// Reflected but with no creator: not an element type.
[GuiReflect]
class Uncreatable : UIWidget
{
}

/// A second type claiming a tag the GUI's Label holds.
[GuiReflect(true, "Label")]
class Impostor : UIWidget
{
}

/// Elements: weak references through a GUI's own element table (one resolves while its element
/// lives and not after, a freed slot taken again answers under a new generation only, and each GUI
/// keeps a table of its own, its references gone with it), a native handle through the same
/// table, the element registry any library adds to, and the element set one GUI may create from,
/// a node adding children by tag through it.
class ElementTests
{
	[Test]
	public static void TheRegistryTakesALibrarysWidgetsAndRefusesWhatIsNotAnElement()
	{
		RegisterGuiElements();
		Test.Assert(ElementTypes.Find("Button") == Button.StaticGuiType);
		Test.Assert(ElementTypes.Find("Panel") == Panel.StaticGuiType);

		// A library's widget under its namespaced tag.
		Test.Assert(ElementTypes.Register(HealthBar.StaticGuiType));
		Test.Assert(ElementTypes.TagOf(HealthBar.StaticGuiType) == "game:HealthBar");
		Test.Assert(ElementTypes.Find("game:HealthBar") == HealthBar.StaticGuiType);
		Test.Assert(ElementTypes.Register(HealthBar.StaticGuiType)); // again: already there, fine

		// No creator, or another type's tag: refused, and the tag keeps its type.
		Test.Assert(!ElementTypes.Register(Uncreatable.StaticGuiType));
		Test.Assert(ElementTypes.Find("Uncreatable") == null);
		Test.Assert(!ElementTypes.Register(Impostor.StaticGuiType));
		Test.Assert(ElementTypes.Find("Label") == Label.StaticGuiType);

		// A library unloading takes its widgets out.
		ElementTypes.Unregister(HealthBar.StaticGuiType);
		Test.Assert(ElementTypes.Find("game:HealthBar") == null);
	}

	[Test]
	public static void AGUIsElementSetDecidesWhatItsMarkupMayCreate()
	{
		RegisterGuiElements();
		Test.Assert(ElementTypes.Register(HealthBar.StaticGuiType));
		defer ElementTypes.Unregister(HealthBar.StaticGuiType);
		let markup = "<Panel><Label text=\"hp\"/><game:HealthBar/><Hp/></Panel>";

		// Everything registered, a library's widget included; an unknown tag is left out.
		{
			let all = scope ElementSet();
			let loader = scope MarkupLoader(all);
			let root = loader.LoadFromString(markup);
			Test.Assert(root != null);
			defer root.ReleaseRef();
			Test.Assert(root.ChildCount == 2);
			Test.Assert(root.GetChildAt(1) is HealthBar);
		}
		// Only what the set allows, under its own aliases.
		{
			let limited = ElementSet.None();
			defer delete limited;
			limited.Allow("Panel");
			limited.Allow("game:HealthBar");
			limited.Alias("Hp", "game:HealthBar");
			let loader = scope MarkupLoader(limited);
			let root = loader.LoadFromString(markup);
			Test.Assert(root != null);
			defer root.ReleaseRef();
			Test.Assert(root.ChildCount == 2); // the Label is not allowed; Hp is a HealthBar
			Test.Assert(root.GetChildAt(0) is HealthBar);
			Test.Assert(root.GetChildAt(1) is HealthBar);
		}
	}

	[Test]
	public static void AFreedSlotTakenByANewElementDoesNotAnswerToTheOldReference()
	{
		let gui = SceneFixtures.NewScene();
		defer gui.ReleaseRef();
		let first = new Label();
		gui.AddChild(first);
		let old = scope Element<Label>(first);
		let firstRef = first.TakeElementRef();
		gui.RemoveChild(first);
		first.ReleaseRef();

		let second = new Label();
		defer second.ReleaseRef();
		gui.AddChild(second);
		let fresh = scope Element<Label>(second);
		let secondRef = second.TakeElementRef();
		Test.Assert(secondRef.Slot == firstRef.Slot); // the slot is reused...
		Test.Assert(secondRef.Generation != firstRef.Generation); // ...under a new generation
		Test.Assert(!old.IsValid);
		Test.Assert(fresh.Get() == second);
	}

	[Test]
	public static void TwoGUIsKeepTheirOwnTablesAndAGUIGoingLeavesItsReferencesGone()
	{
		var a = SceneFixtures.NewScene();
		let b = SceneFixtures.NewScene();
		defer b.ReleaseRef();
		Test.Assert(a.ElementTable != b.ElementTable);
		let inA = new Label();
		defer inA.ReleaseRef();
		let inB = new Label();
		defer inB.ReleaseRef();
		a.AddChild(inA);
		b.AddChild(inB);
		let weakA = scope Element<Label>(inA);
		let weakB = scope Element<Label>(inB);
		Test.Assert(inA.TakeElementRef().Table == a.ElementTable);
		Test.Assert(inB.TakeElementRef().Table == b.ElementTable);

		// A's GUI goes while its label lives on elsewhere and a reference to it is held: the table
		// closes (held alive by the reference), so the reference reads as gone; B is untouched.
		a.ReleaseRef();
		a = null;
		Test.Assert(!weakA.IsValid);
		Test.Assert(weakB.Get() == inB);
	}

	[Test]
	public static void AWeakReferenceResolvesWhileTheElementLivesAndNotAfter()
	{
		let gui = SceneFixtures.NewScene();
		defer gui.ReleaseRef();
		var button = new Button();
		// Detached, an element has no GUI a reference could resolve through.
		Test.Assert(!scope Element<Button>(button).IsValid);
		gui.AddChild(button);
		let weak = scope Element<Button>(button);
		Test.Assert(weak.IsValid);
		Test.Assert(weak.Get() == button);

		button.RemoveFromParent();
		Test.Assert(weak.IsValid); // still alive (the test holds it), so still itself
		button.ReleaseRef();
		button = null;
		Test.Assert(!weak.IsValid); // destroyed: gone, not freed memory
	}

	[Test]
	public static void ANodeAddsChildrenByTagThroughItsGUIsSet()
	{
		RegisterGuiElements();
		let gui = SceneFixtures.NewScene();
		defer gui.ReleaseRef();
		let buttonsOnly = ElementSet.None();
		defer delete buttonsOnly;
		buttonsOnly.Allow("Button");
		gui.Context.ElementSet = buttonsOnly;

		Test.Assert(gui.AddElement("Label") == null); // not in this GUI's set
		Test.Assert(gui.ChildCount == 0);
		let added = gui.AddElement("Button");
		Test.Assert(added is Button);
		Test.Assert(added.Parent == gui);

		// A detached node has no GUI and no set: nothing is created.
		let loose = new Label();
		defer loose.ReleaseRef();
		Test.Assert(loose.AddElement("Button") == null);
		Test.Assert(loose.ChildCount == 0);
	}

	[Test]
	public static void AWidgetBuiltOfPartsAddsByTagIntoItsContentAndTheChildLivesInTheTree()
	{
		RegisterGuiElements();
		let gui = SceneFixtures.NewScene();
		defer gui.ReleaseRef();
		let expander = new Expander();
		defer expander.ReleaseRef();
		gui.AddChild(expander);

		let added = expander.AddElement("Button");
		Test.Assert(added is Button);
		Test.Assert(added.Parent == expander.Content); // where markup's children go
		Test.Assert(added.RefCount == 1); // the tree's: the maker's was let go
		let addedRef = added.TakeElementRef();
		Test.Assert(addedRef.Table.Resolve(addedRef.Slot, addedRef.Generation) === added);

		// Found by id from anywhere above it, the node itself included.
		((Button)added).Id = "ok";
		Test.Assert(gui.FindElement("ok") == added);
		Test.Assert(added.FindElement("ok") == added);
		Test.Assert(gui.FindElement("missing") == null);
	}

	[Test]
	public static void AWeakReferenceResolvesToItsNodeAndReadsNullOnceItOrItsGUIIsGone()
	{
		var gui = SceneFixtures.NewScene();
		let detached = new Label();
		defer detached.ReleaseRef();
		Test.Assert(detached.TakeElementRef().Table == null); // in no GUI: no table to resolve through

		let label = new Label();
		gui.AddChild(label);
		let labelRef = label.TakeElementRef();
		Test.Assert(labelRef.Table != null);
		Test.Assert(labelRef.Table.Resolve(labelRef.Slot, labelRef.Generation) === label);
		let again = label.TakeElementRef(); // one slot, taken once
		Test.Assert((again.Table === labelRef.Table) && (again.Slot == labelRef.Slot) && (again.Generation == labelRef.Generation));

		// Destroyed: null, not freed memory.
		gui.RemoveChild(label);
		label.ReleaseRef();
		Test.Assert(labelRef.Table.Resolve(labelRef.Slot, labelRef.Generation) == null);

		// A reference into a GUI that goes: a holder's own reference keeps the table, closed, so
		// the reference reads null though its node lives on elsewhere.
		let other = new Label();
		defer other.ReleaseRef();
		gui.AddChild(other);
		let otherRef = other.TakeElementRef();
		otherRef.Table.AddRef();
		defer otherRef.Table.ReleaseRef();
		Test.Assert(otherRef.Table.Resolve(otherRef.Slot, otherRef.Generation) === other);
		gui.ReleaseRef();
		gui = null;
		Test.Assert(otherRef.Table.Resolve(otherRef.Slot, otherRef.Generation) == null);
	}
}
