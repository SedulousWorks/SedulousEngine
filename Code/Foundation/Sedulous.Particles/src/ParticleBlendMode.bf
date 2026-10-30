using System;

namespace Sedulous.Particles;

[Reflect(.StaticFields)] // its cases, by name, for a row to offer
enum ParticleBlendMode : uint8
{
	case Alpha;
	case Additive;
	case Premultiplied;
	case Multiply;
}
