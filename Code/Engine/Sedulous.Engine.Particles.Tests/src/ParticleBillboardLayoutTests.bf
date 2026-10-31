using System;
using Sedulous.Engine.Particles;

namespace Sedulous.Engine.Particles.Tests;

/// The billboard instance's layout is particle.vs.hlsl's contract: the vertex layout reads it as
/// five float4s, and the shader unpacks each into the fields named here, so every offset is
/// fixed. The view block is checked against the compiled shader in Integration.ShaderBlocks.
class ParticleBillboardLayoutTests
{
	[Test]
	public static void TheBillboardInstanceKeepsTheShadersOffsets()
	{
		Test.Assert(sizeof(ParticleBillboardInstance) == 80);
		Test.Assert(offsetof(ParticleBillboardInstance, Position) == 0);
		Test.Assert(offsetof(ParticleBillboardInstance, Width) == 12);
		Test.Assert(offsetof(ParticleBillboardInstance, Height) == 16);
		Test.Assert(offsetof(ParticleBillboardInstance, Rotation) == 20);
		Test.Assert(offsetof(ParticleBillboardInstance, Mode) == 24);
		Test.Assert(offsetof(ParticleBillboardInstance, SoftDistance) == 28);
		Test.Assert(offsetof(ParticleBillboardInstance, Color) == 32);
		Test.Assert(offsetof(ParticleBillboardInstance, UvRect) == 48);
		Test.Assert(offsetof(ParticleBillboardInstance, Velocity) == 64);
		Test.Assert(offsetof(ParticleBillboardInstance, Stretch) == 76);
	}
}
