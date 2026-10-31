using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The view tree and the style cascade running over it, end to end: attach, the registry,
/// selector matching and the computed value a control would actually read.
class ViewTreeTests
{
	/// A context with a root attached.
	///
	/// The caller owns the context outright and holds the root's ONE reference: AddRootView
	/// borrows. A view is released rather than deleted, RefCounted asserting in its
	/// destructor that the count reached nought.
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		context.AddRootView(root);
	}

	[Test]
	public static void AddingAChildAttachesItToTheContext()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = new View();
		root.AddView(child);

		Test.Assert(child.Parent == root);
		Test.Assert(child.IsAttached);
		Test.Assert(child.Context == context);
		// Attaching REGISTERS it, so a manager can hold the id rather than the pointer.
		Test.Assert(context.GetViewById(child.Id) == child);
	}

	[Test]
	public static void RemovingAChildDetachesAndUnregistersIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = new View();
		// Kept alive past the removal so the assertions below have something to read.
		child.AddRef();
		defer child.ReleaseRef();

		root.AddView(child);
		let id = child.Id;
		root.RemoveView(child);

		Test.Assert(child.Parent == null);
		Test.Assert(!child.IsAttached);
		// The registry must not keep answering for a view that has left the tree.
		Test.Assert(context.GetViewById(id) == null);
	}

	[Test]
	public static void AttachingAGroupAttachesItsWholeSubtree()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		// Built DETACHED, then attached in one go, which is the usual construction order.
		let group = new ViewGroup();
		let grandchild = new View();
		group.AddView(grandchild);
		Test.Assert(!grandchild.IsAttached);

		root.AddView(group);
		Test.Assert(grandchild.IsAttached);
		Test.Assert(context.GetViewById(grandchild.Id) == grandchild);
	}

	[Test]
	public static void ATypeSelectorResolvesThroughTheCascade()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		UITypeRegistry.Clear();
		UITypeRegistry.Register("View", typeof(View));
		defer UITypeRegistry.Clear();

		let sheet = new StyleSheet();
		sheet.ForType(typeof(View)).Set(StyleProperty.TextColor, Color.Red);
		context.SetStyleSheet(sheet);

		let child = new View();
		root.AddView(child);

		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Red);
	}

	[Test]
	public static void AClassSelectorBeatsATypeSelectorOnSpecificity()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let sheet = new StyleSheet();
		sheet.ForType(typeof(View)).Set(StyleProperty.TextColor, Color.Red);
		sheet.ForClass("accent").Set(StyleProperty.TextColor, Color.Blue);
		context.SetStyleSheet(sheet);

		let child = new View();
		root.AddView(child);
		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Red);

		// A class weighs ten against a type's one, so it wins wherever it applies.
		child.AddClass("accent");
		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Blue);

		child.RemoveClass("accent");
		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Red);
	}

	[Test]
	public static void AnInheritedPropertyReachesADescendant()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let sheet = new StyleSheet();
		sheet.ForType(typeof(RootView)).Set(StyleProperty.TextColor, Color.Blue);
		context.SetStyleSheet(sheet);

		let group = new ViewGroup();
		let leaf = new View();
		group.AddView(leaf);
		root.AddView(group);

		// TextColor inherits, so a leaf with no rule of its own takes the root's computed
		// value rather than the default.
		Test.Assert(leaf.ResolveStyleColor(.TextColor, Color.White) == Color.Blue);
	}

	[Test]
	public static void AnInlineStyleBeatsTheSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let sheet = new StyleSheet();
		sheet.ForType(typeof(View)).Set(StyleProperty.TextColor, Color.Red);
		context.SetStyleSheet(sheet);

		let child = new View();
		root.AddView(child);
		child.SetStyle(.TextColor, Color.Blue);

		// The inline sheet is last in the cascade, so it wins whatever the specificity.
		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Blue);

		child.ClearInlineStyles();
		Test.Assert(child.ResolveStyleColor(.TextColor, Color.White) == Color.Red);
	}

	[Test]
	public static void MovingAChildReordersWithoutDetaching()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let first = new View();
		let second = new View();
		root.AddView(first);
		root.AddView(second);
		Test.Assert(root.GetChildAt(0) == first);

		root.MoveView(second, 0);
		Test.Assert(root.GetChildAt(0) == second);
		Test.Assert(root.GetChildAt(1) == first);
		// A pure reorder, so registration and attachment survive it.
		Test.Assert(second.IsAttached);
		Test.Assert(context.GetViewById(second.Id) == second);
	}
}
