using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The mesh shaders' layout contract.
///
/// Each of these mirrors a block the shader declares. A field reordered or resized on one
/// side and not the other reads the wrong bytes and shows up as geometry in the wrong place,
/// which is a long way from the cause. These pin the sizes so the drift is caught here.
class MeshGpuLayoutTests
{
	[Test]
	public static void TheObjectBlockIsWhatTheShaderDeclares()
	{
		Test.Assert(sizeof(MeshObjectData) == 160);
	}

	[Test]
	public static void TheInstanceElementIsWhatTheShaderDeclares()
	{
		Test.Assert(sizeof(MeshInstanceData) == 144);
	}

	[Test]
	public static void TheShadowViewBlockIsOneMatrix()
	{
		Test.Assert(sizeof(MeshShadowViewData) == 64);
		Test.Assert(sizeof(MeshPickViewData) == 80); // cbuffer PickView in pick_ids.vs
	}

	/// The instance stepped attribute is one vector of four, which is what a normalised
	/// unsigned integer vertex format reads.
	[Test]
	public static void TheOffsetsAttributeIsFourWords()
	{
		Test.Assert(sizeof(MeshDataOffsets) == 16);
	}

	/// Every block has to sit on a sixteen byte boundary, since that is what a constant
	/// buffer's own packing rules assume throughout.
	[Test]
	public static void EveryBlockIsSixteenByteAligned()
	{
		Test.Assert((sizeof(MeshViewData) % 16) == 0);
		Test.Assert((sizeof(MeshObjectData) % 16) == 0);
		Test.Assert((sizeof(MeshInstanceData) % 16) == 0);
		Test.Assert((sizeof(MeshShadowViewData) % 16) == 0);
		Test.Assert((sizeof(MeshPickViewData) % 16) == 0);
		Test.Assert((sizeof(MeshDataOffsets) % 16) == 0);
	}

	/// The view block is handed out of a ring whose slot is a fixed size, so it must fit.
	[Test]
	public static void TheViewBlockFitsItsRingSlot()
	{
		Test.Assert(sizeof(MeshViewData) <= 1024);
	}

	/// The object block is handed out at a dynamic offset, whose alignment is the slot size.
	[Test]
	public static void TheObjectBlockFitsItsDynamicSlot()
	{
		Test.Assert(sizeof(MeshObjectData) <= 256);
		Test.Assert(sizeof(MeshShadowViewData) <= 256);
		Test.Assert(sizeof(MeshPickViewData) <= 256);
	}

	/// The probe record is four vectors of four, which the probe system's own buffer stride
	/// and the shading's declaration both assume.
	[Test]
	public static void TheProbeRecordIsFourVectors()
	{
		Test.Assert(sizeof(GpuProbe) == 64);
	}

	/// The push blocks stay within the portable limit, which is the smallest any backend
	/// guarantees.
	[Test]
	public static void ThePushBlocksStayWithinThePortableLimit()
	{
		Test.Assert(sizeof(SsgiPush) <= 128);
		Test.Assert(sizeof(SsgiDownPush) <= 128);
		Test.Assert(sizeof(SsgiBlurPush) <= 128);
		Test.Assert(sizeof(SsgiResolvePush) <= 128);
		Test.Assert(sizeof(SsrPush) <= 128);
		Test.Assert(sizeof(SsrResolvePush) <= 128);
		Test.Assert(sizeof(DebugBlitPush) <= 128);
		Test.Assert(sizeof(IblPush) <= 128);
		Test.Assert(sizeof(ProbePrefilterPush) <= 128);
	}

	/// The decal's constants are read as a uniform block rather than a push, being far too
	/// large for one, so only their alignment matters here.
	[Test]
	public static void TheDecalBlockIsSixMatricesAndVectors()
	{
		Test.Assert(sizeof(DecalUniforms) == 240);
	}

	/// A sprite's instance record is six vectors of four, which the vertex layout's six
	/// attributes step over.
	[Test]
	public static void TheSpriteInstanceIsSixVectors()
	{
		Test.Assert(sizeof(SpriteInstance) == 96);
	}
}
