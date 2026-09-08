using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The transform hierarchy: the sibling links, world matrix composition, the dirty
/// cascade, the previous frame snapshot, recursive destruction and the cycle guard.
class TransformTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void ParentingLinksTheSiblingList()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity("p");
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");

		Test.Assert(scene.GetParent(a) == EntityHandle.Invalid, "created as roots");

		scene.SetParent(a, parent);
		scene.SetParent(b, parent);

		Test.Assert(scene.GetParent(a) == parent);
		Test.Assert(scene.GetParent(b) == parent);
		Test.Assert(scene.GetChildCount(parent) == 2);
		Test.Assert(scene.GetFirstChild(parent) == a);
		Test.Assert(scene.GetNextSibling(a) == b);
		Test.Assert(scene.GetNextSibling(b) == EntityHandle.Invalid);

		scene.SetParent(b, EntityHandle.Invalid);
		Test.Assert(scene.GetParent(b) == EntityHandle.Invalid);
		Test.Assert(scene.GetChildCount(parent) == 1);
		Test.Assert(scene.GetNextSibling(a) == EntityHandle.Invalid);
	}

	[Test]
	public static void AWorldMatrixComposesTheLocalWithItsParent()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();
		scene.SetLocalPosition(parent, .(10, 0, 0));
		scene.SetLocalPosition(child, .(5, 0, 0));
		scene.SetParent(child, parent);

		scene.UpdateTransforms();

		Test.Assert(Near(scene.GetWorldPosition(parent).X, 10.0f));
		Test.Assert(Near(scene.GetWorldPosition(child).X, 15.0f), "the parent's ten and its own five");
		Test.Assert(scene.IsTransformUpdatedThisFrame(child));
		Test.Assert(scene.TransformsUpdatedThisFrame.Length == 2);
	}

	/// Moving a parent recomputes its descendants and NOTHING ELSE. That selectivity is
	/// the whole reason for the dirty flag: a scene recomputing everything every frame
	/// would not need one.
	[Test]
	public static void TheDirtyCascadeRecomputesDescendantsAndNothingElse()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();
		let other = scene.CreateEntity();
		scene.SetParent(child, parent);
		scene.UpdateTransforms();

		// A frame where nothing moved recomputes nothing at all.
		scene.UpdateTransforms();
		Test.Assert(scene.TransformsUpdatedThisFrame.Length == 0);

		scene.SetLocalPosition(parent, .(0, 7, 0));
		scene.UpdateTransforms();
		Test.Assert(scene.IsTransformUpdatedThisFrame(parent));
		Test.Assert(scene.IsTransformUpdatedThisFrame(child));
		Test.Assert(!scene.IsTransformUpdatedThisFrame(other));
		Test.Assert(Near(scene.GetWorldPosition(child).Y, 7.0f));
	}

	/// The previous world matrix is what a motion vector is computed from, so it has to
	/// hold LAST frame's value while something moves, and catch up the frame after it
	/// stops. Otherwise a stopped object smears forever.
	[Test]
	public static void ThePreviousWorldMatrixSnapshotsThePriorFrame()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		scene.SetLocalPosition(entity, .(1, 0, 0));
		scene.UpdateTransforms();
		Test.Assert(Near(scene.GetWorldPosition(entity).X, 1.0f));

		scene.SetLocalPosition(entity, .(4, 0, 0));
		scene.UpdateTransforms();
		Test.Assert(Near(scene.GetWorldPosition(entity).X, 4.0f));
		Test.Assert(Near(scene.GetPrevWorldMatrix(entity).M[3][0], 1.0f), "last frame's");

		// The frame it stops: previous catches up to current.
		scene.UpdateTransforms();
		Test.Assert(Near(scene.GetPrevWorldMatrix(entity).M[3][0], 4.0f));
	}

	[Test]
	public static void DestroyingAParentDestroysItsWholeSubtree()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();
		let grandchild = scene.CreateEntity();
		let bystander = scene.CreateEntity();
		scene.SetParent(child, parent);
		scene.SetParent(grandchild, child);
		Test.Assert(scene.EntityCount == 4);

		scene.DestroyEntity(parent);

		Test.Assert(!scene.IsValid(parent));
		Test.Assert(!scene.IsValid(child));
		Test.Assert(!scene.IsValid(grandchild));
		Test.Assert(scene.IsValid(bystander));
		Test.Assert(scene.EntityCount == 1);
	}

	/// A reparent that would form a cycle is REFUSED, not half applied. A cycle would make
	/// the transform walk recurse forever, so this guard is what keeps the update total.
	[Test]
	public static void AReparentUnderItsOwnDescendantIsRefused()
	{
		let scene = scope Scene();
		let a = scene.CreateEntity();
		let b = scene.CreateEntity();
		let c = scene.CreateEntity();
		scene.SetParent(b, a);
		scene.SetParent(c, b);

		scene.SetParent(a, c);
		Test.Assert(scene.GetParent(a) == EntityHandle.Invalid, "a stays a root");
		Test.Assert(scene.GetParent(c) == b, "the tree is intact");

		// And a normal move still works afterwards, without the update looping.
		scene.SetParent(a, EntityHandle.Invalid);
		scene.UpdateTransforms();
		Test.Assert(scene.GetChildCount(a) == 1);
	}

	[Test]
	public static void DestroyingAChildSplicesItOutOfTheSiblingList()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let a = scene.CreateEntity();
		let b = scene.CreateEntity();
		let c = scene.CreateEntity();
		scene.SetParent(a, parent);
		scene.SetParent(b, parent);
		scene.SetParent(c, parent);
		Test.Assert(scene.GetChildCount(parent) == 3);

		// The MIDDLE child, which is the case that needs both back and forward links.
		scene.DestroyEntity(b);

		Test.Assert(scene.GetChildCount(parent) == 2);
		Test.Assert(scene.GetFirstChild(parent) == a);
		Test.Assert(scene.GetNextSibling(a) == c);
	}

	/// The editor's reparent: the entity stays exactly where it is in the world, and its
	/// LOCAL transform absorbs the difference.
	[Test]
	public static void AKeepWorldReparentLeavesTheEntityWhereItIs()
	{
		let scene = scope Scene();
		let parentA = scene.CreateEntity("A");
		let parentB = scene.CreateEntity("B");
		let child = scene.CreateEntity("child");

		var transformA = Transform();
		transformA.Position = .(10.0f, 0.0f, 0.0f);
		transformA.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.7f);
		scene.SetLocalTransform(parentA, transformA);

		var transformB = Transform();
		transformB.Position = .(-5.0f, 2.0f, 1.0f);
		transformB.Scale = .(2.0f, 2.0f, 2.0f);
		scene.SetLocalTransform(parentB, transformB);

		var transformChild = Transform();
		transformChild.Position = .(1.0f, 2.0f, 3.0f);
		scene.SetLocalTransform(child, transformChild);
		scene.SetParent(child, parentA);

		let before = scene.ComposeWorldMatrix(child);

		scene.SetParent(child, parentB, true);
		Test.Assert(scene.GetParent(child) == parentB);
		AssertMatricesMatch(scene.ComposeWorldMatrix(child), before);

		// The local DID change: the same place in the world, under a different parent.
		Test.Assert(Math.Abs(scene.GetLocalTransform(child).Position.X - 1.0f) > 0.0001f);

		// Out to the root, where the local becomes the world.
		scene.SetParent(child, EntityHandle.Invalid, true);
		AssertMatricesMatch(scene.ComposeWorldMatrix(child), before);

		// A REFUSED move leaves the local alone: nothing moved, so nothing is rewritten.
		scene.SetParent(parentB, parentB, true);
		Test.Assert(scene.GetParent(parentB) == EntityHandle.Invalid);
	}

	/// A child reparented under a CLEAN parent must still recompute.
	///
	/// The regression this pins: the update once walked only dirty ROOTS, so a freshly
	/// parented child under a settled parent kept its stale matrix until something moved
	/// the parent, and a pasted entity drew at the origin until the scene was reloaded.
	[Test]
	public static void AChildReparentedUnderACleanParentStillRecomputes()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity("parent");
		scene.SetLocalPosition(parent, .(10, 0, 0));
		scene.UpdateTransforms();

		// The paste sequence: create at the root, set the authored local, then parent.
		let child = scene.CreateEntity("child");
		scene.SetLocalPosition(child, .(0, 5, 0));
		scene.SetParent(child, parent);
		scene.UpdateTransforms();

		let world = scene.GetWorldMatrix(child);
		Test.Assert(Near(world.M[3][0], 10.0f), "the parent's offset is composed in");
		Test.Assert(Near(world.M[3][1], 5.0f), "and its own authored local");
	}

	private static void AssertMatricesMatch(Float4x4 actual, Float4x4 expected)
	{
		for (int row < 4)
		{
			for (int column < 4)
				Test.Assert(Math.Abs(actual.M[row][column] - expected.M[row][column]) < 0.001f);
		}
	}
}
