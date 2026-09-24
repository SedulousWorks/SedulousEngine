using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.FBX;

namespace Sedulous.Model.FBX.Tests;

/// Finding the image a model points at.
///
/// Content is authored on machines whose separator is the BACKSLASH, and the recorded
/// relative name keeps it, so on a POSIX host every path join built from that name names
/// a file that cannot exist. The absolute name ufbx resolves is what lands then, and
/// without it a whole model imports untextured: Bistro's 405 textures all missed.
class FbxTexturePathTests
{
	/// A model whose material points at a texture through a BACKSLASH separated relative
	/// path, with the file itself in a subdirectory beside the model.
	private class BackslashFixture
	{
		public String Dir = new .() ~ delete _;
		public String ModelPath = new .() ~ delete _;

		public this(StringView name)
		{
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), scope $"scratch_fbx_{name}", Dir);
			RemoveDirectoryRecursive(Dir);
			CreateDirectory(Dir);
			let textureDir = scope String();
			PathJoin(Dir, "Textures", textureDir);
			CreateDirectory(textureDir);

			// A DDS is taken by its magic without decoding, so four bytes and a header's
			// worth of zeroes is a file the loader accepts.
			let ddsPath = scope String();
			PathJoin(textureDir, "brick.dds", ddsPath);
			uint8[128] dds = .();
			dds[0] = (uint8)'D'; dds[1] = (uint8)'D'; dds[2] = (uint8)'S'; dds[3] = (uint8)' ';
			File.WriteAll(ddsPath, .(&dds[0], dds.Count)).IgnoreError();

			// The material names the texture the way a Windows authored file does.
			let mtlPath = scope String();
			PathJoin(Dir, "brick.mtl", mtlPath);
			File.WriteAllText(mtlPath, """
				newmtl brick
				Kd 1.0 1.0 1.0
				map_Kd Textures\\brick.dds
				""").IgnoreError();

			PathJoin(Dir, "cube.obj", ModelPath);
			File.WriteAllText(ModelPath, """
				mtllib brick.mtl
				v 0 0 0
				v 1 0 0
				v 0 1 0
				vt 0 0
				vt 1 0
				vt 0 1
				usemtl brick
				f 1/1 2/2 3/3
				""").IgnoreError();
		}

		public ~this() { RemoveDirectoryRecursive(Dir); }
	}

	[Test]
	public static void ABackslashRelativePathStillFindsItsTexture()
	{
		let fixture = scope BackslashFixture("backslash_texture");
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.ModelPath, model) == .Ok);

		Test.Assert(model.Textures.Length == 1);
		let texture = model.Textures[0];
		// Resolved: a DDS records its path rather than decoding, so SourceFile is the proof.
		Test.Assert(!texture.SourceFile.IsEmpty, "the backslash relative path resolved");
		Test.Assert(texture.SourceFile.EndsWith("brick.dds"));
		Test.Assert(!texture.Uri.IsEmpty);
	}
}
