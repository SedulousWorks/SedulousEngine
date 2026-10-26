using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Samples.GUISandbox;

// The Toolkit page's reflected object (T3 of Raptor's gui-lab-evolution-3.md): a camera rig
// declared with the GUI's reflection and nothing else, which the toolkit's ReflectedPropertySource
// shows: values, an enum and flags as their integers, a Float3, a Quaternion as Euler degrees, a
// Color, an HDR glow as a Float4, the lens's values, a read-only serial, and a sky over the day
// (T5): the GUI's ColorGradient, one value. Its text format is the engine's XmlSerializer.
//
// Raptor declares it with Core's run-time reflection, whose records carry more than the GUI's
// [GuiProperty] does here. Still in RaptorCode (ReflectedCamera.cppm, ReflectedCameraImpl.cpp):
//   - the metadata: ranges (fieldOfView 10 to 120, the lens's), descriptions, display names (Near,
//     Far), visibleWhen (fieldOfView on a perspective camera, orthographicSize on an orthographic
//     one), flags by attribute (layers), hdrColor (glow) and noAlpha (a vignette's tint);
//   - an enum's names (projection shows its integer);
//   - the lens as a nested value group (ReflectedPropertySource groups only a Node a property holds,
//     which would bring a node's own rows; here its three values stand on the rig);
//   - the lists: exposureStops, and the polymorphic list of effects (CameraEffect, BloomEffect,
//     VignetteEffect) added by type, which a GUI table cannot hold;
//   - RegisterCameraTypes: a [GuiReflect] table is built on first use, so nothing registers.

enum CameraProjection : uint8
{
	Perspective,
	Orthographic,
}

enum CameraLayers : uint32
{
	None = 0,
	World = 1,
	Characters = 2,
	Effects = 4,
	Interface = 8,
}

/// A camera rig the reflected grid edits: an application's object, reflected for the GUI alone.
[GuiReflect(true)]
class CameraRig
{
	private String mName = new .("Camera") ~ delete _;
	private bool mEnabled = true;
	private CameraProjection mProjection = .Perspective;
	private float mFieldOfView = 60.0f;
	private float mOrthographicSize = 5.0f;
	private float mNearPlane = 0.1f;
	private float mFarPlane = 500.0f;
	private CameraLayers mLayers = (CameraLayers)(1 | 2 | 4 | 8);
	private Float3 mPosition = .(0.0f, 2.0f, -6.0f);
	private Quaternion mRotation = .Identity;
	private Color mBackground = .(0.1f, 0.12f, 0.16f, 1.0f);
	/// An HDR colour: sRGB rgb, a linear intensity in w.
	private Float4 mGlow = .(1.0f, 0.75f, 0.4f, 2.0f);
	private float mLensFocalLength = 35.0f;
	private float mLensAperture = 2.8f;
	private bool mLensAutoFocus = true;
	/// The sky's colour over a day, 0 midnight to 1 the next.
	private ColorGradient mSky = new .() ~ delete _;
	private uint32 mSerial = 0;
	private int32 mPriority = 0;

	public this()
	{
		mSky.Colors.Add(GradientColorStop(0.0f, Color(0.03f, 0.04f, 0.12f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.25f, Color(0.95f, 0.55f, 0.3f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.5f, Color(0.45f, 0.7f, 1.0f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.75f, Color(0.9f, 0.4f, 0.35f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(1.0f, Color(0.03f, 0.04f, 0.12f, 1.0f)));
		mSky.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
		mSky.Interpolation = .OkLab;
	}

	[GuiProperty]
	public StringView Name
	{
		get => mName;
		set => mName.Set(value);
	}

	[GuiProperty]
	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	[GuiProperty]
	public CameraProjection Projection
	{
		get => mProjection;
		set => mProjection = value;
	}

	[GuiProperty]
	public float FieldOfView
	{
		get => mFieldOfView;
		set => mFieldOfView = value;
	}

	[GuiProperty]
	public float OrthographicSize
	{
		get => mOrthographicSize;
		set => mOrthographicSize = value;
	}

	[GuiProperty]
	public float NearPlane
	{
		get => mNearPlane;
		set => mNearPlane = value;
	}

	[GuiProperty]
	public float FarPlane
	{
		get => mFarPlane;
		set => mFarPlane = value;
	}

	/// What it draws: CameraLayers' bits, shown as their integer.
	[GuiProperty]
	public CameraLayers Layers
	{
		get => mLayers;
		set => mLayers = value;
	}

	[GuiProperty]
	public Float3 Position
	{
		get => mPosition;
		set => mPosition = value;
	}

	/// A Quaternion, shown in Euler degrees.
	[GuiProperty]
	public Quaternion Rotation
	{
		get => mRotation;
		set => mRotation = value;
	}

	/// A Color, its sRGB values.
	[GuiProperty]
	public Color Background
	{
		get => mBackground;
		set => mBackground = value;
	}

	[GuiProperty]
	public Float4 Glow
	{
		get => mGlow;
		set => mGlow = value;
	}

	[GuiProperty]
	public float LensFocalLength
	{
		get => mLensFocalLength;
		set => mLensFocalLength = value;
	}

	[GuiProperty]
	public float LensAperture
	{
		get => mLensAperture;
		set => mLensAperture = value;
	}

	[GuiProperty]
	public bool LensAutoFocus
	{
		get => mLensAutoFocus;
		set => mLensAutoFocus = value;
	}

	/// Its colour over a day: the grid's gradient editor.
	[GuiProperty]
	public ColorGradient Sky
	{
		get => mSky;
		set
		{
			if (value != null)
				mSky.Set(value);
		}
	}

	/// Given by the scene: read only (no setter, so the table has none).
	[GuiProperty]
	public uint32 Serial => mSerial;

	[GuiProperty]
	public int32 Priority
	{
		get => mPriority;
		set => mPriority = value;
	}

	/// The scene's serial, which the grid only reads.
	public void SetSerial(uint32 serial)
	{
		mSerial = serial;
	}
}

/// The engine's XmlSerializer as a source's text format (the reflected grid's changes and copies,
/// the graphs' copies).
class XmlTextFormat : IPropertyTextFormat
{
	public void Write(delegate void(ISerializer ar) write, String outText)
	{
		let ar = scope XmlSerializer();
		write(ar);
		if (ar.IsOk)
			ar.GetOutput(outText);
	}

	public bool Read(StringView text, delegate void(ISerializer ar) read)
	{
		let doc = scope XmlDocument();
		if (doc.Parse(text) != .Ok)
			return false;
		let ar = scope XmlSerializer(doc);
		read(ar);
		return ar.IsOk;
	}
}
