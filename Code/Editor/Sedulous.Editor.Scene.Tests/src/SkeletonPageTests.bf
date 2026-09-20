using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation;
using Sedulous.Render;

namespace Sedulous.Editor.Scene.Tests;

/// The skeleton page's headless halves: the stats, the tree snapshot and the wireframe.
class SkeletonPageTests
{
	/// Root -> Spine -> Head, plus a second root; the spine rises one unit per bone.
	private static Skeleton Rig()
	{
		let skeleton = new Skeleton(4);
		skeleton.Bones[0].Name.Set("Root");
		skeleton.Bones[1].Name.Set("Spine");
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.Bones[1].LocalBindPose.Position = .(0, 1, 0);
		skeleton.Bones[2].Name.Set("Head");
		skeleton.Bones[2].ParentIndex = 1;
		skeleton.Bones[2].LocalBindPose.Position = .(0, 1, 0);
		skeleton.Bones[3].Name.Set("Prop");
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		return skeleton;
	}

	[Test]
	public static void StatsReportBonesRootsAndDepth()
	{
		let skeleton = Rig();
		defer delete skeleton;
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		SkeletonStats.Lines(skeleton, lines);
		// No name: three entries.
		Test.Assert(lines.Count == 3);
		Test.Assert(lines[0] == "4 bones");
		Test.Assert(lines[1] == "2 roots");
		Test.Assert(lines[2] == "depth 2");
	}

	[Test]
	public static void TheTreeSnapshotMirrorsTheHierarchy()
	{
		let skeleton = Rig();
		defer delete skeleton;
		let snapshot = scope SkeletonTreeSnapshot();
		snapshot.Rebuild(skeleton);
		Test.Assert(snapshot.Nodes.Count == 4);
		Test.Assert(snapshot.Roots.Count == 2);
		Test.Assert((snapshot.Roots[0] == 0) && (snapshot.Roots[1] == 3));
		Test.Assert(snapshot.Nodes[0].Children.Count == 1 && snapshot.Nodes[0].Children[0] == 1);
		Test.Assert(snapshot.Nodes[1].Children.Count == 1 && snapshot.Nodes[1].Children[0] == 2);
		Test.Assert(snapshot.Nodes[2].Depth == 2);
		Test.Assert(snapshot.Nodes[3].Depth == 0);
		Test.Assert(snapshot.InRange(3) && !snapshot.InRange(4) && !snapshot.InRange(-1));

		// The adapter walks it: roots at -1, children by index, never reorderable.
		let adapter = scope SkeletonTreeAdapter(snapshot);
		adapter.SetSkeleton(skeleton);
		Test.Assert(adapter.GetChildCount(-1) == 2);
		Test.Assert(adapter.GetChildId(-1, 1) == 3);
		Test.Assert(adapter.GetChildId(0, 0) == 1);
		Test.Assert(adapter.GetChildId(0, 1) == -1);
		Test.Assert(adapter.HasChildren(1) && !adapter.HasChildren(2));
		Test.Assert(!adapter.CanMove(0, 1));

		// No product: an empty table.
		snapshot.Rebuild(null);
		Test.Assert(snapshot.Nodes.IsEmpty && snapshot.Roots.IsEmpty);
	}

	[Test]
	public static void TheWireframeDrawsOneLinePerChildBoneAtWorldJoints()
	{
		let skeleton = Rig();
		defer delete skeleton;
		let poses = scope List<BoneTransform>();
		for (let bone in skeleton.Bones)
			poses.Add(bone.LocalBindPose);
		let world = scope List<Float4x4>();
		let draw = scope DebugDraw();
		SkeletonWireframe.Draw(draw, skeleton, poses, world);

		Test.Assert(world.Count == 4);
		// Head sits two units up: the spine's unit plus its own.
		let head = SkeletonWireframe.JointPosition(world[2]);
		Test.Assert(Math.Abs(head.Y - 2.0f) < 1e-4f);
		// Two child bones give two lines; every joint a cross of three lines.
		Test.Assert(draw.LineVertices.Length == (2 + 4 * 3) * 2);

		// Too few poses: nothing drawn.
		draw.Clear();
		SkeletonWireframe.Draw(draw, skeleton, .(poses.Ptr, 2), world);
		Test.Assert(!draw.HasAnyDraws);
	}
}
