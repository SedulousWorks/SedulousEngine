namespace Sedulous.Particles;

/// How a system's particles are drawn.
///
/// A TAG the render extractor branches on rather than a polymorphic module, because the
/// branch happens once per system and a virtual call would happen once per particle.
enum ParticleRenderMode : uint8
{
	case Billboard;
	/// Stretched along its own velocity, which is what makes a spark look fast.
	case StretchedBillboard;
	case HorizontalBillboard;
	case VerticalBillboard;
	case Mesh;
	case Trail;
	/// Contributes a point light per particle to the clustered light list, and draws the glow
	/// as well.
	case Light;
}
