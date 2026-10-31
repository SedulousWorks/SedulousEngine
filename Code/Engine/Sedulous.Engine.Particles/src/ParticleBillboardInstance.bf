using System;
using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// ONE packed billboard, laid out to match the particle shader's instance inputs exactly.
///
/// Eighty bytes. The layout is the contract with the vertex shader rather than anything the
/// simulation cares about, which is why it is packed here and not in the sim: the vertex layout
/// reads it as five float4s at locations nought to four (ParticleRenderer's billboard pipeline),
/// and particle.vs.hlsl unpacks each into the fields named here, so their offsets are the
/// shader's contract.
[CRepr]
struct ParticleBillboardInstance
{
	/// The world centre.
	public Float3 Position = .(0, 0, 0);
	public float Width = 0.0f;
	public float Height = 0.0f;
	/// The camera facing roll, in radians.
	public float Rotation = 0.0f;
	/// The orientation mode's ordinal, as a float (the shader rounds it).
	public float Mode = 0.0f;
	/// The soft particle fade band; nought is off.
	public float SoftDistance = 0.0f;
	/// Linear (decoded from the simulated sRGB colour), with any premultiplication already
	/// done by the simulation.
	public Float4 Color = .(1, 1, 1, 1);
	/// The flipbook cell: the minimum in the first two lanes and the size in the last two.
	public Float4 UvRect = .(0, 0, 1, 1);
	/// The world velocity.
	public Float3 Velocity = .(0, 0, 0);
	/// The stretch scale. Nought is a plain billboard rather than a stretched one.
	public float Stretch = 0.0f;

	public this() {}

	/// A particle's colour as simulated (authored sRGB: the effect's colours, curves and trail
	/// colour, interpolated as entered, so a gradient moves evenly to the eye) decoded to
	/// linear for the renderer. Applied where the colour leaves the simulation: billboards,
	/// trails, mesh tints and particle lights.
	public static Float4 ColorToLinear(Float4 c)
	{
		let l = ToLinear(Sedulous.Core.Color(c.X, c.Y, c.Z, c.W));
		return .(l.R, l.G, l.B, l.A);
	}
}
