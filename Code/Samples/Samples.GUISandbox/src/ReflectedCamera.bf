using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Samples.GUISandbox;

// The Toolkit page's reflected object: a camera rig
// declared with the GUI's reflection and nothing else, which the toolkit's ReflectedPropertySource
// shows: values with ranges and names, an enum, flags by their flag, a Float3, a Quaternion as Euler
// degrees, a Color, an HDR glow (a colour and an intensity in stops), a nested lens, a list of
// stops, a list of effects added by type, a read-only serial, a field shown only for one
// projection, and a sky over the day: Core's gradient stops in bounded lists, which the page
// registers with the source as a gradient. Its text format is the engine's XmlSerializer.
//
// Nothing registers here: a [GuiReflect] table is built on first use, and an effect is made by its
// table's creator.

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

/// A camera's lens: a value struct, a group of its fields on the rig's grid (named apart from the
/// rig's property, as CameraProjection is).
struct CameraLens
{
	[GuiProperty, Range(8.0f, 300.0f, 1.0f)]
	public float FocalLength = 35.0f;
	[GuiProperty, Range(1.0f, 22.0f, 0.1f)]
	public float Aperture = 2.8f;
	[GuiProperty]
	public bool AutoFocus = true;
}

/// The sky's colour over a day, 0 midnight to 1 the next: Core's stops in bounded lists (at most
/// six of each), as a particle effect's colour over life keeps them; the page registers it as a
/// gradient. Its holder owns the lists.
struct SkyGradient
{
	[GuiProperty, GuiList(6)]
	public List<GradientColorStop> Colors;
	[GuiProperty, GuiList(6)]
	public List<GradientAlphaStop> Alphas;
	[GuiProperty]
	public GradientInterpolation Interpolation = .OkLab;
}

/// An effect on a camera: the rig's list holds any of the types below.
[GuiReflect]
class CameraEffect
{
	private float mStrength = 1.0f;

	[GuiProperty, Range(0.0f, 1.0f, 0.05f)]
	public float Strength
	{
		get => mStrength;
		set => mStrength = value;
	}
}

[GuiReflect(true), DisplayName("Bloom")]
class BloomEffect : CameraEffect
{
	private float mThreshold = 0.8f;

	[GuiProperty]
	public float Threshold
	{
		get => mThreshold;
		set => mThreshold = value;
	}
}

[GuiReflect(true), DisplayName("Vignette")]
class VignetteEffect : CameraEffect
{
	private float mRadius = 0.75f;
	private Color mTint = .(0.0f, 0.0f, 0.0f, 1.0f);

	[GuiProperty]
	public float Radius
	{
		get => mRadius;
		set => mRadius = value;
	}

	[GuiProperty("", .NoAlpha)]
	public Color Tint
	{
		get => mTint;
		set => mTint = value;
	}
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
	private CameraLens mLens = .();
	private SkyGradient mSky = .();
	private List<float> mExposureStops = new .() ~ delete _;
	private List<CameraEffect> mEffects = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mSerial = 0;
	private int32 mPriority = 0;

	public this()
	{
		mSky.Colors = new .();
		mSky.Colors.Add(GradientColorStop(0.0f, Color(0.03f, 0.04f, 0.12f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.25f, Color(0.95f, 0.55f, 0.3f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.5f, Color(0.45f, 0.7f, 1.0f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(0.75f, Color(0.9f, 0.4f, 0.35f, 1.0f)));
		mSky.Colors.Add(GradientColorStop(1.0f, Color(0.03f, 0.04f, 0.12f, 1.0f)));
		mSky.Alphas = new .();
		mSky.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
	}

	public ~this()
	{
		delete mSky.Colors;
		delete mSky.Alphas;
	}

	[GuiProperty, Description("What the scene calls it")]
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

	[GuiProperty, Range(10.0f, 120.0f, 0.5f), VisibleWhen("Projection=0")]
	public float FieldOfView
	{
		get => mFieldOfView;
		set => mFieldOfView = value;
	}

	[GuiProperty, VisibleWhen("Projection=1")]
	public float OrthographicSize
	{
		get => mOrthographicSize;
		set => mOrthographicSize = value;
	}

	[GuiProperty, DisplayName("Near")]
	public float NearPlane
	{
		get => mNearPlane;
		set => mNearPlane = value;
	}

	[GuiProperty, DisplayName("Far")]
	public float FarPlane
	{
		get => mFarPlane;
		set => mFarPlane = value;
	}

	[GuiProperty("", .BitFlags), Description("What it draws")]
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

	[GuiProperty, Description("A Quaternion, shown in Euler degrees")]
	public Quaternion Rotation
	{
		get => mRotation;
		set => mRotation = value;
	}

	[GuiProperty, Description("A Color, its sRGB values")]
	public Color Background
	{
		get => mBackground;
		set => mBackground = value;
	}

	[GuiProperty("", .HdrColor), Description("An HDR colour: its colour, and its intensity in exposure stops")]
	public Float4 Glow
	{
		get => mGlow;
		set => mGlow = value;
	}

	[GuiProperty]
	public CameraLens Lens
	{
		get => mLens;
		set => mLens = value;
	}

	[GuiProperty, Description("Its colour over a day: click for the gradient")]
	public SkyGradient Sky
	{
		get => mSky;
		set => mSky = value;
	}

	/// A list, changed in place: no setter.
	[GuiProperty]
	public List<float> ExposureStops => mExposureStops;

	[GuiProperty, GuiList(0, "BloomEffect, VignetteEffect")]
	public List<CameraEffect> Effects => mEffects;

	/// Given by the scene: read only (no setter, so the table has none).
	[GuiProperty, Description("Given by the scene: read only")]
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
