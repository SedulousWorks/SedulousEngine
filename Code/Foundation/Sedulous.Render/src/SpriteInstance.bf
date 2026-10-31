using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One sprite's instance record (96 bytes). The vertex layout reads it as six float4s at
/// locations nought to five; sprite.vs.hlsl names each attribute for the fields it carries, so
/// their offsets are the shader's contract.
[CRepr]
struct SpriteInstance
{
	/// The world centre.
	public Float3 Position = .(0, 0, 0);
	public float Width = 1.0f;
	public float Height = 1.0f;
	/// The orientation mode's ordinal, as a float (the shader rounds it).
	public float Orientation = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public Float4 Tint = .(1, 1, 1, 1);
	/// The atlas sub rectangle, as an origin and an extent.
	public Float4 UvRect = .(0, 0, 1, 1);
	/// The oriented case's own right and up axes.
	public Float3 AxisRight = .(1, 0, 0);
	public float Pad2 = 0.0f;
	public Float3 AxisUp = .(0, 1, 0);
	public float Pad3 = 0.0f;

	public this() {}
}
