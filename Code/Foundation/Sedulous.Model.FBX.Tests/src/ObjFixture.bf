using System;
using System.IO;

namespace Sedulous.Model.FBX.Tests;

/// Writes a Wavefront OBJ, and its material library, to a scratch file.
///
/// OBJ rather than FBX because it is TEXT: a fixture can be written in the test and read
/// by eye, where an FBX would have to be a checked in binary nobody can diff. ufbx reads
/// both through the same path, so the geometry, material and node handling under test are
/// the same ones an FBX exercises. What OBJ cannot reach is skinning and animation, which
/// it has no way to express.
class ObjFixture
{
	private String mPath = new .() ~ delete _;
	private String mMaterialPath = new .() ~ delete _;

	public this(StringView name, StringView contents, StringView materialLibrary = "")
	{
		mPath.AppendF("scratch_fbx_{}.obj", name);

		// The mtllib line is written HERE rather than in the fixture text, so the reference
		// and the file it names cannot drift apart. They did: a fixture said one name while
		// the library was written under another, and the material simply never loaded,
		// which looks exactly like a loader that drops materials.
		let document = scope String();
		if (!materialLibrary.IsEmpty)
		{
			mMaterialPath.AppendF("scratch_fbx_{}.mtl", name);
			File.WriteAllText(mMaterialPath, materialLibrary).IgnoreError();
			document.AppendF("mtllib {}\n", mMaterialPath);
		}
		document.Append(contents);
		File.WriteAllText(mPath, document).IgnoreError();
	}

	public ~this()
	{
		// Braced, because `defer a.B().C()` in Beef runs a.B() immediately; the same trap
		// applies to writing it as one expression anywhere it must happen last.
		File.Delete(mPath).IgnoreError();
		if (!mMaterialPath.IsEmpty)
			File.Delete(mMaterialPath).IgnoreError();
	}

	public StringView Path => mPath;
}
