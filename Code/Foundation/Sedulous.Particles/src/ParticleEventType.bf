using System;

namespace Sedulous.Particles;

/// When a sub emitter fires.
[Reflect(.StaticFields)] // its cases, by name, for a row to offer
enum ParticleEventType : uint8
{
	case OnBirth;
	case OnDeath;
}
