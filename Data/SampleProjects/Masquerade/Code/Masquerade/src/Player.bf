using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Net.Replication;
using Sedulous.Engine.Render;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// A guest someone plays. On a guest's entity like any other (a navigation agent and an Instance
/// Member of a costume), so it looks like one. It moves where the stick points, relative to where
/// the camera looks, by driving its agent at that velocity (no path to wait for): the crowd makes
/// way round it and it round the crowd, as guests do for each other. A guest's stroll by default;
/// Sprint is faster (and marks you, Ball); Dance, held, dances; Tag tells the Ball (which decides
/// who is in reach). It shoulders past guests, at half pace while it is pressed against one
/// (Crowd), so it cannot plough through a group; standing guests step out of its way (Guest). It
/// wears its costume on a child, one of six looks (the Ball picks), so the clip goes to each look.
/// Its Activity is a guest's.
///
/// Over the network the host moves every hunter: a client's own hunter sends its stick, sprint,
/// dance and tags to the host (the "input" and "tag" messages), the host's Ball hands them to the
/// hunter (RemoteInput), and the transform and Activity come back replicated. A spawned hunter (a
/// joining player's) finds the camera, the crowd and the Ball by name, and the client's own tells
/// the camera to follow it.
[Behaviour("masquerade.player")]
[DisplayName("Player"), Category("Masquerade")]
[Description("A guest someone plays: moves relative to the camera, sprints, dances and tags; a client's sends its input to the host.")]
class Player : Behaviour
{
	[Description("The camera whose facing makes forward")]
	public EntityRef Camera = .();
	[Description("The crowd: its children's children are the guests it pushes past")]
	public EntityRef Crowd = .();
	[Description("Nearer than this to a guest (m) is pressing against it")]
	public float PressDistance = 0.55f;
	[Description("Its pace while pressing against a guest (of the full)")]
	public float PressPace = 0.5f;
	[Description("Walking speed (m/s): a guest's, the Walk clip's")]
	public float WalkSpeed = 1.0f;
	[Description("Sprinting speed (m/s)")]
	public float SprintSpeed = 3.0f;
	[Description("What the player is doing (0 idle, 1 walk, 2 talk, 3 dance): the clip it plays"), Replicated]
	public int32 Activity = 0;
	[Description("Sprinting now (a hunter sees it)"), Replicated]
	public bool Sprinting = false;

	/// The camera and the crowd in this scene: the ones Camera and Crowd name, or, for a spawned
	/// hunter that names nothing, the ones named "Camera" and "Crowd".
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mCrowd = .Invalid;
	/// The entity named "Ball", which runs the round.
	private EntityHandle mBall = .Invalid;
	private float mYaw = 0.0f;
	private bool mMoving = false;
	private float mPressCheck = 0.0f;
	private bool mPressed = false;
	/// A remote player's input (the host): the stick's x and z, sprint and dance.
	private Float4 mRemote = .(0.0f, 0.0f, 0.0f, 0.0f);
	private float mRemoteAge = 99.0f;
	/// The input last sent to the host (a client).
	private int32 mSent = -1;
	/// The ring under this hunter shown (it is this peer's).
	private bool mRingShown = false;
	private float mSendIn = 0.0f;
	/// A client's: its agent stopped for the host's transforms.
	private bool mHandedOver = false;

	protected override void OnStart()
	{
		// A spawned hunter (a joining player's) names nothing in the scene: it finds what it needs.
		mCamera = Scene.FindEntity(Camera.Id);
		if (!Scene.IsValid(mCamera))
			mCamera = Scene.FindEntityByName("Camera");
		mCrowd = Scene.FindEntity(Crowd.Id);
		if (!Scene.IsValid(mCrowd))
			mCrowd = Scene.FindEntityByName("Crowd");
		mBall = Scene.FindEntityByName("Ball");
		if (Scene.IsValid(mBall))
			Pieces.BallOn(Scene, mBall)?.AddHunter(Entity); // so the seats can find it, on every peer
		if (Mine && Scene.IsValid(mCamera))
			Pieces.RigOn(Scene, mCamera)?.Track(Entity);
	}

	/// Whose: 0 the host, else the id the host gave a client.
	private int32 Owner
	{
		get
		{
			let network = Get<NetworkComponent>();
			return (network == null) ? 0 : (int32)network.Owner;
		}
	}

	/// Mine when this peer plays it.
	private bool Mine => Owner == Pieces.LocalPlayer(Run);

	/// The host: a remote player's stick (x, z), sprint and dance (above a half, held), from the
	/// Ball.
	public void RemoteInput(Float4 input)
	{
		mRemote = input;
		mRemoteAge = 0.0f;
	}

	protected override void OnUpdate(float dt)
	{
		// The ring on the floor under your own guest (maps.py: hidden on every hunter), once whose
		// this hunter is is known (a joiner's hunter becomes its own as the host's state arrives).
		let own = Mine;
		if (own != mRingShown)
		{
			let ring = Scene.FindChildByName(Entity, "Ring");
			if (Scene.IsValid(ring))
			{
				if (let decal = Scene.GetComponent<DecalComponent>(ring))
				{
					decal.Visible = own;
					mRingShown = own;
				}
			}
		}
		// What the player asks for: the stick as a direction on the floor, sprint, dance, a tag.
		float dx = 0.0f;
		float dz = 0.0f;
		bool sprint = false;
		bool dance = false;
		bool tag = false;
		let client = Pieces.IsClient(Run);
		if (own)
		{
			let input = Pieces.Controls(Run);
			var stick = (input != null) ? input.Value2D("Move") : Float2(0.0f, 0.0f);
			let amount = Sqrt(stick.X * stick.X + stick.Y * stick.Y);
			if ((amount >= 0.1f) && Scene.IsValid(mCamera))
			{
				if (amount > 1.0f)
					stick = .(stick.X / amount, stick.Y / amount);
				// The camera's facing along the floor: forward, and right of it.
				let look = RotateVector(Scene.GetWorldRotation(mCamera), .(0.0f, 0.0f, -1.0f));
				let flat = Max(Sqrt(look.X * look.X + look.Z * look.Z), 0.0001f);
				let forward = Float3(look.X / flat, 0.0f, look.Z / flat);
				let right = Float3(-forward.Z, 0.0f, forward.X);
				dx = forward.X * stick.Y + right.X * stick.X;
				dz = forward.Z * stick.Y + right.Z * stick.X;
			}
			sprint = Pieces.IsDown(Run, "Sprint");
			dance = Pieces.IsDown(Run, "Dance");
			tag = Pieces.WasPressed(Run, "Tag");
		}
		else if (!client)
		{
			mRemoteAge += dt;
			if (mRemoteAge < 0.5f) // a quiet client stands still
			{
				dx = mRemote.X;
				dz = mRemote.Y;
				sprint = mRemote.Z > 0.5f;
				dance = mRemote.W > 0.5f;
			}
		}

		if (client)
		{
			if (!mHandedOver)
			{
				if (let agent = Get<NavAgentComponent>())
					agent.Stop(); // walking since the scene loaded: the host's now
				mHandedOver = true;
			}
			// The host moves every hunter; a client sends its own player's asking, and plays what
			// the host replicates back.
			if (own)
			{
				Send(dx, dz, sprint, dance, dt);
				if (tag)
				{
					if (let net = Pieces.Net(Run))
						net.Rpc("tag");
				}
			}
			PlayClip();
			return;
		}

		let agent = Get<NavAgentComponent>();
		let amount = Sqrt(dx * dx + dz * dz);
		Sprinting = false;
		if (amount >= 0.1f)
		{
			Sprinting = sprint;
			var speed = Sprinting ? SprintSpeed : WalkSpeed;
			mPressCheck -= dt;
			if (mPressCheck <= 0.0f)
			{
				mPressCheck = 0.1f;
				mPressed = Pressing();
			}
			if (mPressed)
				speed *= PressPace;
			if (agent != null)
				agent.Move(dx / amount * Min(amount, 1.0f) * speed, dz / amount * Min(amount, 1.0f) * speed);
			mMoving = true;
			Face(dx, dz, dt);
		}
		else
		{
			if (agent != null)
				agent.Move(0.0f, 0.0f);
			mMoving = false;
		}
		if (tag && Scene.IsValid(mBall))
			Pieces.BallOn(Scene, mBall)?.Tag(Owner); // the Ball finds the seat
		Activity = mMoving ? Clips.Walk : (dance ? Clips.Dance : Clips.Idle);
		PlayClip();
	}

	/// A client: its player's asking, packed in one number (the stick to a hundredth, sprint and
	/// dance as bits), to the host when it changes and five times a second besides.
	private void Send(float dx, float dz, bool sprint, bool dance, float d)
	{
		let ix = (int32)Clamp((dx + 1.0f) * 100.0f + 0.5f, 0.0f, 200.0f);
		let iz = (int32)Clamp((dz + 1.0f) * 100.0f + 0.5f, 0.0f, 200.0f);
		let packed = (ix * 201 + iz) * 4 + (sprint ? 1 : 0) + (dance ? 2 : 0);
		mSendIn -= d;
		if ((packed != mSent) || (mSendIn <= 0.0f))
		{
			if (let net = Pieces.Net(Run))
				net.RpcNumber("input", (double)packed);
			mSent = packed;
			mSendIn = 0.2f;
		}
	}

	/// The clip on each of its looks (only the one it wears is drawn), from its replicated
	/// Activity.
	private void PlayClip()
	{
		var child = Scene.GetFirstChild(Entity);
		while (Scene.IsValid(child))
		{
			if (let look = Scene.GetComponent<InstanceMemberComponent>(child))
				look.Clip = (uint32)Activity;
			child = Scene.GetNextSibling(child);
		}
	}

	/// Pressed against a guest: one of the crowd's within PressDistance.
	private bool Pressing()
	{
		if (!Scene.IsValid(mCrowd))
			return false;
		let p = Scene.GetWorldPosition(Entity);
		let reach = PressDistance * PressDistance;
		var group = Scene.GetFirstChild(mCrowd);
		while (Scene.IsValid(group))
		{
			var guest = Scene.GetFirstChild(group);
			while (Scene.IsValid(guest))
			{
				let q = Scene.GetWorldPosition(guest);
				let dx = q.X - p.X;
				let dz = q.Z - p.Z;
				if (dx * dx + dz * dz < reach)
					return true;
				guest = Scene.GetNextSibling(guest);
			}
			group = Scene.GetNextSibling(group);
		}
		return false;
	}

	/// Face where it goes (the model faces +Z), turning the short way round.
	private void Face(float dx, float dz, float d)
	{
		let want = Atan2(dx, dz);
		mYaw += Pieces.Wrap(want - mYaw) * Min(10.0f * d, 1.0f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}
}
