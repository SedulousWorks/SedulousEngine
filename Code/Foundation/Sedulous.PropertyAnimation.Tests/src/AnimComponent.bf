using System;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation.Tests;

/// A component shaped object with animatable leaf and nested properties.
[Reflect(.All)]
class AnimComponent
{
	public Float3 Position = .(0.0f, 0.0f, 0.0f);
	public Quaternion Rotation = .Identity;
	public float Intensity = 0.0f;
	public AnimLight Light = .();
}
