using System;
using Sedulous.Models;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models.Tests;

class ModelTests
{
	[Test]
	public static void TestModelCreation()
	{
		let model = new Model();
		defer delete model;

		Test.Assert(model.Meshes.Count == 0);
		Test.Assert(model.Materials.Count == 0);
		Test.Assert(model.Bones.Count == 0);
	}

	[Test]
	public static void TestModelAddMesh()
	{
		let model = new Model();
		defer delete model;

		let mesh = new ModelMesh();
		mesh.SetName("TestMesh");

		let index = model.AddMesh(mesh);
		Test.Assert(index == 0);
		Test.Assert(model.Meshes.Count == 1);
		Test.Assert(model.GetMesh("TestMesh") != null);
	}

	[Test]
	public static void TestModelAddMaterial()
	{
		let model = new Model();
		defer delete model;

		let material = new ModelMaterial();
		material.SetName("TestMaterial");
		material.BaseColorFactor = .(1, 0, 0, 1);

		let index = model.AddMaterial(material);
		Test.Assert(index == 0);
		Test.Assert(model.Materials.Count == 1);
		Test.Assert(model.GetMaterial("TestMaterial") != null);
	}

	[Test]
	public static void TestModelAddBone()
	{
		let model = new Model();
		defer delete model;

		let bone = new ModelBone();
		bone.SetName("Root");
		bone.Translation = .(0, 1, 0);

		let index = model.AddBone(bone);
		Test.Assert(index == 0);
		Test.Assert(model.Bones.Count == 1);
		Test.Assert(model.GetBone("Root") != null);
	}

	[Test]
	public static void TestBoneHierarchy()
	{
		let model = new Model();
		defer delete model;

		let root = new ModelBone();
		root.SetName("Root");
		model.AddBone(root);

		let child = new ModelBone();
		child.SetName("Child");
		child.ParentIndex = 0;
		model.AddBone(child);

		model.BuildBoneHierarchy();

		Test.Assert(model.RootBoneIndex == 0);
		Test.Assert(model.Bones[0].Children.Count == 1);
	}
}
