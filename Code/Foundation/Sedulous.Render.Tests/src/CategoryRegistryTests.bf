using System;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The category registry.
class CategoryRegistryTests
{
	/// The built ins are registered at their WELL KNOWN ids, which is what keeps the
	/// constants beside them true.
	[Test]
	public static void TheBuiltInsSitAtTheirConstants()
	{
		let registry = scope CategoryRegistry();

		Test.Assert(registry.Count == RenderCategories.BuiltinCount);
		Test.Assert(registry.Name(RenderCategories.Opaque) == "Opaque");
		Test.Assert(registry.Name(RenderCategories.Transparent) == "Transparent");
		Test.Assert(registry.Name(RenderCategories.WorldUI) == "WorldUI");
	}

	[Test]
	public static void EachBuiltInCarriesItsSortAndPass()
	{
		let registry = scope CategoryRegistry();

		Test.Assert(registry.Sort(RenderCategories.Opaque) == .FrontToBack);
		Test.Assert(registry.Affinity(RenderCategories.Opaque) == .Opaque);

		Test.Assert(registry.Sort(RenderCategories.Transparent) == .BackToFront);
		Test.Assert(registry.Affinity(RenderCategories.Transparent) == .Blended);

		// A light is a shading input rather than something drawn.
		Test.Assert(registry.Affinity(RenderCategories.Light) == .None);
		Test.Assert(registry.Affinity(RenderCategories.Sky) == .None);

		Test.Assert(registry.Affinity(RenderCategories.WorldUI) == .PostTonemap);
	}

	/// An extension registers a category of its own without editing anything here.
	[Test]
	public static void AnExtensionCanRegisterItsOwn()
	{
		let registry = scope CategoryRegistry();

		let id = registry.Register("Ribbons", .BackToFront, .Blended);
		Test.Assert(id == RenderCategories.BuiltinCount);
		Test.Assert(registry.Count == RenderCategories.BuiltinCount + 1);
		Test.Assert(registry.Sort(id) == .BackToFront);
		Test.Assert(registry.Name(id) == "Ribbons");
	}

	/// Registration is IDEMPOTENT by name, so two subsystems asking for the same category get
	/// the same id rather than two that sort apart.
	[Test]
	public static void RegisteringAKnownNameAnswersItsId()
	{
		let registry = scope CategoryRegistry();

		let first = registry.Register("Ribbons", .BackToFront, .Blended);
		let second = registry.Register("Ribbons", .FrontToBack, .Opaque);

		Test.Assert(first == second);
		Test.Assert(registry.Count == RenderCategories.BuiltinCount + 1);
		Test.Assert(registry.Sort(first) == .BackToFront, "the first registration stands");
	}

	/// An unknown category answers the safe defaults rather than reading past the table.
	[Test]
	public static void AnUnknownCategoryAnswersSafely()
	{
		let registry = scope CategoryRegistry();
		let unknown = RenderCategories.MaxCategories - 1;

		Test.Assert(registry.Sort(unknown) == .FrontToBack);
		Test.Assert(registry.Affinity(unknown) == .None);
		Test.Assert(registry.Name(unknown).IsEmpty);
	}

	/// A full table REFUSES rather than overflowing.
	[Test]
	public static void AFullRegistryRefuses()
	{
		let registry = scope CategoryRegistry();

		// The names are BORROWED, so they have to outlive the registry rather than the loop
		// iteration that made them.
		for (int i = registry.Count; i < RenderCategories.MaxCategories; i++)
			registry.Register(scope:: $"Extra{i}", .FrontToBack, .None);

		Test.Assert(registry.Count == RenderCategories.MaxCategories);
		Test.Assert(registry.Register("OneTooMany", .FrontToBack, .None)
			== RenderCategories.MaxCategories);
	}

	/// The shared registry is ONE instance: two copies would disagree about the ids, which
	/// sorts a draw into the wrong pass rather than failing.
	[Test]
	public static void TheSharedRegistryIsShared()
	{
		Test.Assert(CategoryRegistry.Instance == CategoryRegistry.Instance);
		Test.Assert(CategoryRegistry.Instance.Name(RenderCategories.Opaque) == "Opaque");
	}
}
