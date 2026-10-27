using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Samples.GUISandbox;

// What the editor mock's inspectors show (X0 of Raptor's Specs/editor-gui.md): an entity with
// three components and a scene's settings, reflected as the engine's are, standing in for them.
// Plain data: nothing here runs.
//
// Raptor registers these with Core's reflection (RegisterMockTypes, called before the first
// inspector fills); a [GuiReflect] table is built on first use, so nothing registers here. The
// components are value structs, their [GuiProperty] fields a group each, as CameraRig's lens is.

enum MockMotion : uint8
{
	Dynamic,
	Kinematic,
	Static,
}

enum MockTonemap : uint8
{
	/// Named as the inspector shows it: a case's name is its choice's text.
	ACES,
	AgX,
	Neutral,
}

struct MockTransform
{
	[GuiProperty]
	public Float3 Position = .(2.0f, 0.5f, -1.0f);
	[GuiProperty]
	public Quaternion Rotation = .Identity;
	[GuiProperty]
	public Float3 Scale = .(1.0f, 1.0f, 1.0f);
}

/// Its texts are its holder's (MockEntity makes and deletes them), written in place by the grid.
struct MockMeshRenderer
{
	[GuiProperty]
	public String Mesh;
	[GuiProperty]
	public String Material;
	[GuiProperty]
	public bool CastShadows = true;
	[GuiProperty]
	public bool ReceiveShadows = true;
}

struct MockRigidBody
{
	[GuiProperty]
	public MockMotion Motion = .Dynamic;
	[GuiProperty, Range(0.0f, 1000.0f, 0.1f)]
	public float Mass = 12.0f;
	[GuiProperty, Range(0.0f, 1.0f, 0.01f)]
	public float LinearDamping = 0.05f;
	[GuiProperty, Range(0.0f, 1.0f, 0.01f)]
	public float Friction = 0.6f;
	[GuiProperty]
	public bool StartAsleep = false;
}

/// An entity: its name and the components it has.
[GuiReflect(true)]
class MockEntity
{
	private String mName = new .("Crate") ~ delete _;
	private bool mEnabled = true;
	private MockTransform mTransform = .();
	private MockMeshRenderer mMeshRenderer = .();
	private MockRigidBody mRigidBody = .();

	public this()
	{
		mMeshRenderer.Mesh = new .("Crate");
		mMeshRenderer.Material = new .("Wood");
	}

	public ~this()
	{
		delete mMeshRenderer.Mesh;
		delete mMeshRenderer.Material;
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
	public MockTransform Transform
	{
		get => mTransform;
		set => mTransform = value;
	}

	[GuiProperty]
	public MockMeshRenderer MeshRenderer
	{
		get => mMeshRenderer;
		set => mMeshRenderer = value;
	}

	[GuiProperty]
	public MockRigidBody RigidBody
	{
		get => mRigidBody;
		set => mRigidBody = value;
	}
}

struct MockEnvironment
{
	[GuiProperty]
	public Color SkyColor = .(0.42f, 0.6f, 0.9f, 1.0f);
	[GuiProperty, Range(0.0f, 4.0f, 0.05f)]
	public float AmbientIntensity = 0.8f;
	[GuiProperty]
	public bool Fog = true;
	[GuiProperty, Range(0.0f, 0.2f, 0.001f), VisibleWhen("Fog=1")]
	public float FogDensity = 0.02f;
}

struct MockRendering
{
	[GuiProperty, Range(-8.0f, 8.0f, 0.1f)]
	public float Exposure = 0.0f;
	[GuiProperty]
	public MockTonemap Tonemap = .AgX;
	[GuiProperty]
	public bool Shadows = true;
	[GuiProperty, Range(1.0f, 500.0f, 1.0f)]
	public float ShadowDistance = 60.0f;
}

struct MockPhysics
{
	[GuiProperty]
	public Float3 Gravity = .(0.0f, -9.81f, 0.0f);
	[GuiProperty, Range(1.0f, 8.0f, 1.0f)]
	public int32 Substeps = 2;
}

struct MockAudio
{
	[GuiProperty, Range(0.0f, 1.0f, 0.01f)]
	public float MasterVolume = 0.9f;
	[GuiProperty, Range(0.0f, 4.0f, 0.05f)]
	public float DopplerScale = 1.0f;
}

/// A scene's own settings: what its inspector shows when the scene itself is selected.
[GuiReflect(true)]
class MockScene
{
	private MockEnvironment mEnvironment = .();
	private MockRendering mRendering = .();
	private MockPhysics mPhysics = .();
	private MockAudio mAudio = .();

	[GuiProperty]
	public MockEnvironment Environment
	{
		get => mEnvironment;
		set => mEnvironment = value;
	}

	[GuiProperty]
	public MockRendering Rendering
	{
		get => mRendering;
		set => mRendering = value;
	}

	[GuiProperty]
	public MockPhysics Physics
	{
		get => mPhysics;
		set => mPhysics = value;
	}

	[GuiProperty]
	public MockAudio Audio
	{
		get => mAudio;
		set => mAudio = value;
	}
}
