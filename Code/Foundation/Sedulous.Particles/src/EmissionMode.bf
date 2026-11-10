using System;
using Sedulous.Core;

namespace Sedulous.Particles;

/// How an emitter releases particles.
[Reflect(.StaticFields)] // its cases, by name, for a row to offer
enum EmissionMode : uint8
{
	case Continuous;
	case Burst;
	case ContinuousAndBurst;
}
