using System;
using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// ONE packed billboard, laid out to match the particle shader's instance inputs exactly.
///
/// Eighty bytes, five vectors. The layout is the contract with the vertex shader rather than
/// anything the simulation cares about, which is why it is packed here and not in the sim.
[CRepr]
struct ParticleBillboardInstance
{
	/// The world centre, with the width in the fourth lane.
	public Float4 PositionSize = .(0, 0, 0, 0);
	/// The height, the rotation in radians, the orientation mode, and one spare lane.
	public Float4 SizeRotMode = .(0, 0, 0, 0);
	/// Linear, with any premultiplication already done by the simulation.
	public Float4 Color = .(1, 1, 1, 1);
	/// The flipbook cell: the minimum in the first two lanes and the size in the last two.
	public Float4 UvRect = .(0, 0, 1, 1);
	/// The world velocity, with the stretch scale in the fourth lane. Nought is a plain
	/// billboard rather than a stretched one.
	public Float4 Velocity = .(0, 0, 0, 0);

	public this() {}
}
