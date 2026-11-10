using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Animation;
using Sedulous.Animation.Pipeline;
using Sedulous.Render;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Animation.Tests;

/// The skeleton page over its markup (Data/Editor/SkeletonPage.xml) and a scratch project, without a
/// host (no preview): the bones a tree under their parents, read from the asset; the chosen bone's
/// facts and the skeleton's, read only; a search keeping a bone found and the bones above it; a
/// rotation said in degrees about an axis. And the bones the previews draw.
class SkeletonPageTests
{
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project holding one skeleton: Hips (Spine, Chest under it; LegL, LegR) and a second
	/// root, Prop.
	private class Bed
	{
		public String Dir = new .("scratch_skeleton_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public SkeletonEditorPage Page;

		public this()
		{
			AnimationPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Rig", typeof(SkeletonAsset).GetFullName(.. scope .()));
			Test.Assert(instance != null);
			let asset = scope SkeletonAsset();
			let source = asset.Source;
			source.Name.Set("rig");
			void Bone(StringView name, int32 parent, Float3 at, Quaternion turn)
			{
				source.BoneName.Add(new String(name));
				source.ParentIndex.Add(parent);
				source.Translation.Add(at);
				source.Rotation.Add(turn);
				source.Scale.Add(.(1.0f, 1.0f, 1.0f));
				source.InverseBindPose.Add(.Identity());
			}
			Bone("Hips", -1, .(0.0f, 1.0f, 0.0f), .Identity);
			Bone("Spine", 0, .(0.0f, 0.2f, 0.0f), Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), Math.PI_f * 0.5f));
			Bone("Chest", 1, .(0.0f, 0.25f, 0.0f), .Identity);
			Bone("LegL", 0, .(0.1f, -0.1f, 0.0f), .Identity);
			Bone("LegR", 0, .(-0.1f, -0.1f, 0.0f), .Identity);
			Bone("Prop", -1, .(0.5f, 1.0f, 0.0f), .Identity);
			Test.Assert(instance.WriteObject(asset) case .Ok);
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new SkeletonEditorPage(Context, services, instance);
			Test.Assert(!Page.LoadFailed);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The copies Row read (GetValue's are owned), let go with the bed.
		private List<Sedulous.GUI.Variant> mRead = new .() ~ { for (var value in _) value.Dispose(); delete _; };

		public StringView Row(StringView path)
		{
			let value = Page.BoneRows.GetValue(path, 0);
			mRead.Add(value);
			return value.AsString;
		}
		public String Tree(String outText)
		{
			Page.Tree(outText);
			return outText;
		}
		public String Fact(StringView name, String outText)
		{
			Page.Fact(name, outText);
			return outText;
		}
	}

	private static String Rotation(Quaternion rotation, String outText)
	{
		SkeletonEditorPage.DescribeRotation(rotation, outText);
		return outText;
	}

	[Test]
	public static void TheBonesATreeUnderTheirParentsReadFromTheAssetItsFactsReadOnly()
	{
		let bed = scope Bed();
		Test.Assert(bed.Page.ShownSkeleton != null);
		Test.Assert(bed.Tree(.. scope .()) == "Hips\n  Spine\n    Chest\n  LegL\n  LegR\nProp", bed.Tree(.. scope .()));
		Test.Assert(bed.Fact("Bones", .. scope .()) == "6");
		Test.Assert(bed.Fact("Roots", .. scope .()) == "2");
		Test.Assert(bed.Fact("Deepest chain", .. scope .()) == "2 below its root");

		// The first bone chosen to start; another chosen, its facts follow.
		Test.Assert(bed.Page.ChosenBone == 0);
		Test.Assert(bed.Row("parent") == "None: a root");
		Test.Assert(bed.Row("children") == "3");
		bed.Page.ChooseBone(1);
		Test.Assert(bed.Row("name") == "Spine");
		Test.Assert(bed.Row("index") == "1");
		Test.Assert(bed.Row("parent") == "Hips");
		Test.Assert(bed.Row("position") == "0, 0.2, 0", scope String(bed.Row("position")));
		Test.Assert(bed.Row("rotation") == "90° about 0, 1, 0", scope String(bed.Row("rotation")));
		Test.Assert(bed.Row("scale") == "1, 1, 1", scope String(bed.Row("scale")));
		bed.Page.ChooseBone(-1);
		Test.Assert(bed.Row("name") == "None chosen");
		Test.Assert(bed.Row("parent").IsEmpty);

		// Read only, every one of them.
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		bed.Page.BoneRows.GetProperties("", rows);
		Test.Assert(rows.Count == 7);
		for (let info in rows)
			Test.Assert(info.ReadOnly);
	}

	[Test]
	public static void ASearchKeepsABoneFoundAndTheBonesAboveIt()
	{
		let bed = scope Bed();
		bed.Page.Search("leg");
		Test.Assert(bed.Tree(.. scope .()) == "Hips\n  LegL\n  LegR");
		bed.Page.Search("chest");
		Test.Assert(bed.Tree(.. scope .()) == "Hips\n  Spine\n    Chest");
		bed.Page.Search("nothing like it");
		Test.Assert(bed.Tree(.. scope .()).IsEmpty);
		bed.Page.Search("  ");
		Test.Assert(bed.Tree(.. scope .()) == "Hips\n  Spine\n    Chest\n  LegL\n  LegR\nProp");
	}

	[Test]
	public static void ARotationSaidInDegreesAboutAnAxis()
	{
		Test.Assert(Rotation(.Identity, .. scope .()) == "None");
		Test.Assert(Rotation(Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), Math.PI_f), .. scope .()) == "180° about 1, 0, 0");
		// The shorter way round: -90 about +Y is 90 about -Y.
		let turned = Rotation(Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), -Math.PI_f * 0.5f), .. scope .());
		Test.Assert(turned == "90° about 0, -1, 0", turned);
	}

	/// Each bone under its parent in the skeleton's order, its node's bone kept; a search keeps a bone
	/// found and the bones above it.
	[Test]
	public static void TheBoneTreeHasEachBoneUnderItsParentAndASearchKeepsWhatItFindsAndTheBonesAboveIt()
	{
		let skeleton = scope Skeleton(5);
		StringView[5] names = .("root", "hips", "spine", "leg_l", "prop");
		int32[5] parents = .(-1, 0, 1, 1, -1); // prop: a second root
		for (int b < 5)
		{
			skeleton.Bones[b].Name.Set(names[b]);
			skeleton.Bones[b].ParentIndex = parents[b];
		}
		let model = scope TreeModel();
		let rows = scope List<int32>();
		AnimationPreview.FillBoneTree(model, rows, skeleton);
		// Depth first under each root, siblings in the skeleton's order: root, hips, spine, leg_l, prop.
		Test.Assert(rows.Count == 5);
		for (int32 b < 5)
			Test.Assert(rows[b] == b);

		AnimationPreview.FillBoneTree(model, rows, skeleton, "LEG");
		Test.Assert(rows.Count == 3, "leg_l and the bones above it, any case");
		Test.Assert((rows[0] == 0) && (rows[1] == 1) && (rows[2] == 3));
	}

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

	// Further cases (the old wireframe test, on the previews' shared drawing).
	[Test]
	public static void TheBonesDrawOneLinePerChildBoneAtWorldJoints()
	{
		let skeleton = Rig();
		defer delete skeleton;
		let poses = scope List<BoneTransform>();
		for (let bone in skeleton.Bones)
			poses.Add(bone.LocalBindPose);
		let world = scope List<Float4x4>();
		let draw = scope DebugDraw();
		AnimationPreview.DrawSkeletonBones(draw, skeleton, poses, world, .Identity());

		Test.Assert(world.Count == 4);
		// Head sits two units up: the spine's unit plus its own.
		let head = AnimationPreview.JointPosition(world[2]);
		Test.Assert(Math.Abs(head.Y - 2.0f) < 1e-4f);
		// Two child bones give two lines; every joint a cross of three lines.
		Test.Assert(draw.LineVertices.Length == (2 + 4 * 3) * 2);

		// Too few poses: nothing drawn.
		draw.Clear();
		AnimationPreview.DrawSkeletonBones(draw, skeleton, .(poses.Ptr, 2), world, .Identity());
		Test.Assert(!draw.HasAnyDraws);
	}
}
