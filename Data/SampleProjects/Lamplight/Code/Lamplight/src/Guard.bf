using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Render;
using Sedulous.Engine.GUI;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// What a guard is doing.
enum GuardState : uint8
{
	/// Walking his round.
	case Patrol = 0;
	/// Stopped, turned to look: half aware of the thief.
	case Suspicious = 1;
	/// Running at the thief.
	case Chase = 2;
	/// Gone to a place to look round: where the thief was last seen, or a noise.
	case Search = 3;
}

/// Walks a round with a lantern, and sees and hears the thief. On the guard's entity, which carries
/// a navigation agent and the model (its graph: Speed, Searching); the lantern's spot light is a
/// child, and what it lights is what he sees.
///
/// - Patrol: the route's points (the children of Route) in turn, round and round.
/// - Seeing: the thief inside the lantern's cone and range, nothing between his eye and the thief's
///   chest (a ray that ignores the guards' own group), fills awareness by how lit the thief is (the
///   light at his chest, his own lantern included) and faster the nearer; unseen, it drains.
/// - Within Touch he notices the thief whatever the light (bumped into).
/// - A shut door in his way he opens (Door.Knock; he has the keys).
/// - Suspicious at half: he stops and turns to look. Chase when full (ThiefSpotted): he runs at the
///   thief and catches him within CatchDistance (ThiefCaught: the thief to his checkpoint, the
///   guards to their rounds). Lose him, or hear a Noise within its reach: Search, go there and look
///   round, then back to the round.
[Behaviour("lamplight.guard")]
[DisplayName("Guard"), Category("Lamplight")]
[Description("Walks a round with a lantern, sees the thief by how lit he is, hears noises, opens doors, and chases and catches him.")]
class Guard : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();
	[Description("The round: its children are the points walked in turn")]
	public EntityRef Route = .();
	[Description("The lantern's spot light (a child): its cone and range are what he sees")]
	public EntityRef Lantern = .();
	[Description("The meter over his head (a GUI billboard: a mark and a bar)")]
	public EntityRef Meter = .();
	[Description("Walking speed (m/s): the Walk clip's")]
	public float WalkSpeed = 1.2f;
	[Description("Running speed (m/s): the Run clip's")]
	public float RunSpeed = 4.0f;
	[Description("Eye height (m)")]
	public float EyeHeight = 1.6f;
	[Description("Seconds to see a fully lit thief at arm's length")]
	public float NoticeSeconds = 1.2f;
	[Description("The light (luminance) that counts as half lit")]
	public float HalfLight = 0.15f;
	[Description("How fast awareness drains, unseen (per second)")]
	public float Forget = 0.4f;
	[Description("Catches the thief within this (m)")]
	public float CatchDistance = 1.0f;
	[Description("How far away a noise of loudness 1 is heard (m)")]
	public float Hearing = 14.0f;
	[Description("Seconds spent looking round at a searched place")]
	public float SearchSeconds = 4.0f;
	[Description("Within this (m) he feels the thief, cone or no cone: bumped into, he notices")]
	public float Touch = 1.2f;
	[Description("Seconds after a catch the guards leave the thief be (he is back at his checkpoint)")]
	public float Grace = 3.0f;
	[Description("The guards' collision group: their own rays look past it")]
	public int32 Group = 2;

	private GuardState mState = .Patrol;
	/// How aware of the thief he is, 0 to 1: half is suspicious, full a chase.
	private float mAwareness = 0.0f;
	/// The entities the references name in this scene, found as it starts.
	private EntityHandle mThief = .Invalid;
	private EntityHandle mRoute = .Invalid;
	private EntityHandle mLantern = .Invalid;
	private EntityHandle mMeter = .Invalid;
	/// The round's point he walks to.
	private EntityHandle mPoint = .Invalid;
	/// Where he last saw the thief.
	private Float3 mSpot = .(0.0f, 0.0f, 0.0f);
	/// Seconds left looking round a searched place.
	private float mTimer = 0.0f;
	/// Radians; 0 faces +Z.
	private float mYaw = 0.0f;
	/// The model's skinned mesh, which carries the graph: Guard (the instance) / GuardRig / Guard.
	private EntityHandle mFigure = .Invalid;
	/// After a catch: not looking for the thief yet.
	private float mCalm = 0.0f;
	/// The last noise he went to look at.
	private Float3 mHeard = .(0.0f, 0.0f, 0.0f);
	/// Until the next look for a door in his way.
	private float mKnockIn = 0.0f;

	protected override void OnStart()
	{
		Listen<Noise>(new [=this] (evt) => Heard(evt.At, evt.Loudness));
		// The thief caught, by any guard: back to the round, forgetting him for a while.
		Listen<ThiefCaught>(new [=this] (evt) => StandDown());
		mThief = Scene.FindEntity(Thief.Id);
		mRoute = Scene.FindEntity(Route.Id);
		mLantern = Scene.FindEntity(Lantern.Id);
		mMeter = Scene.FindEntity(Meter.Id);
		Patrol();
	}

	protected override void OnUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		See(dt);
		let agent = Get<NavAgentComponent>();
		if (agent == null)
			return;
		switch (mState)
		{
		case .Patrol:
			if (mAwareness >= 0.5f)
			{
				mState = .Suspicious;
				agent.Stop();
			}
			else if (agent.Finished)
			{
				Next();
			}
		case .Suspicious:
			Face(Scene.GetWorldPosition(mThief), dt);
			if (mAwareness >= 1.0f)
			{
				mState = .Chase;
				Post(ThiefSpotted(Entity)); // the game counts it, the alarm rings
			}
			else if (mAwareness < 0.25f)
			{
				Search(mSpot);
			}
		case .Chase:
			let at = Scene.GetWorldPosition(mThief);
			agent.NavigateAt(at, RunSpeed, 0.5f);
			if (Pieces.FlatDistance(Scene.GetWorldPosition(Entity), at) <= CatchDistance)
			{
				// Caught: once (stand down now; the event reaches everyone at the frame's end).
				Post(ThiefCaught(Scene.GetWorldPosition(Entity)));
				StandDown();
			}
			else if (mAwareness < 0.5f)
			{
				Search(mSpot); // lost him: where he was last seen
			}
		case .Search:
			if (mAwareness >= 0.5f)
			{
				mState = .Suspicious;
				agent.Stop();
			}
			else if (agent.Finished)
			{
				mTimer -= dt;
				if (mTimer <= 0.0f)
					Patrol();
			}
		}
		Animate(dt);
		Show();
		Knock(dt);
	}

	/// A shut door in his way (a guard has the keys): what is just ahead of him at the waist, told
	/// to open (the Door on its hinge, the collider's parent). The navigation runs through doorways
	/// whether their doors are open or not, so without this he would walk into one and stop.
	private void Knock(float dt)
	{
		mKnockIn -= dt;
		if (mKnockIn > 0.0f)
			return;
		mKnockIn = 0.25f;
		let physics = Scene.GetSystem<PhysicsSceneSystem>();
		if (physics == null)
			return;
		let p = Scene.GetWorldPosition(Entity);
		let ahead = Float3(Sin(mYaw), 0.0f, Cos(mYaw)); // the model faces +Z
		let hit = physics.RayCast(.(p.X, p.Y + 1.0f, p.Z), ahead, 1.2f, Pieces.MaskWithout(Group));
		if (!hit.Hit || !Scene.IsValid(hit.Entity))
			return;
		let hinge = Scene.GetParent(hit.Entity);
		if (!Scene.IsValid(hinge))
			return;
		if (let door = Pieces.DoorOn(Scene, hinge))
			door.Knock(p);
	}

	/// The meter over his head: hidden while he has seen nothing, then the bar fills with his
	/// awareness under a "?", and a "!" once he is after the thief.
	private void Show()
	{
		if (!Scene.IsValid(mMeter))
			return;
		let board = Scene.GetComponent<GuiBillboardComponent>(mMeter);
		if (board == null)
			return;
		let shown = (mAwareness > 0.02f) || (mState == .Chase);
		board.Visible = shown;
		if (!shown)
			return;
		let panel = board.Root;
		if (panel == null)
			return; // not built yet
		if (let bar = panel.FindElement("meter") as ProgressBar)
			bar.Value = (mState == .Chase) ? 1.0f : mAwareness;
		Hud.SetText(panel.FindElement("mark"), (mState == .Chase) ? "!" : "?");
	}

	/// A noise at `at`: heard within its reach, it is searched (unless he is already after the
	/// thief).
	private void Heard(Float3 at, float loudness)
	{
		if ((mState == .Chase) || (mState == .Suspicious))
			return;
		if (Pieces.FlatDistance(Scene.GetWorldPosition(Entity), at) <= Hearing * loudness)
		{
			mHeard = at;
			Search(mHeard);
		}
	}

	private void StandDown()
	{
		mAwareness = 0.0f;
		mCalm = Grace;
		if (let agent = Get<NavAgentComponent>())
			agent.Stop();
		Patrol();
	}

	/// How much of the thief this guard sees this frame, into awareness.
	private void See(float dt)
	{
		var rate = -Forget;
		if (mCalm > 0.0f)
		{
			mCalm -= dt;
			mAwareness = 0.0f;
			return;
		}
		let cone = Scene.IsValid(mLantern) ? Scene.GetComponent<LightComponent>(mLantern) : null;
		if (Scene.IsValid(mThief) && (cone != null))
		{
			var eye = Scene.GetWorldPosition(Entity);
			eye = .(eye.X, eye.Y + EyeHeight, eye.Z);
			let t = Scene.GetWorldPosition(mThief);
			let chest = Float3(t.X, t.Y + 0.4f, t.Z);
			let to = Float3(chest.X - eye.X, chest.Y - eye.Y, chest.Z - eye.Z);
			let dist = Sqrt(to.X * to.X + to.Y * to.Y + to.Z * to.Z);
			let ahead = RotateVector(Scene.GetWorldRotation(mLantern), .(0.0f, 0.0f, -1.0f));
			let cosAngle = (dist > 0.001f) ? (to.X * ahead.X + to.Y * ahead.Y + to.Z * ahead.Z) / dist : 1.0f;
			let mask = Pieces.MaskWithout(Group);
			let physics = Scene.GetSystem<PhysicsSceneSystem>();
			if ((physics != null) && (dist < cone.Range) && (cosAngle >= Cos(cone.OuterAngle)))
			{
				let hit = physics.RayCast(eye, .(to.X / dist, to.Y / dist, to.Z / dist), dist, mask);
				if (!hit.Hit)
				{
					let lum = Pieces.Luminance(RenderExtract.LightAt(Scene, chest, mask));
					let lit = lum / (lum + HalfLight);
					let nearness = 1.0f - dist / cone.Range;
					rate = lit * (0.4f + 0.6f * nearness) / NoticeSeconds;
					mSpot = t;
				}
			}
		}
		if (Scene.IsValid(mThief) && (Pieces.FlatDistance(Scene.GetWorldPosition(Entity), Scene.GetWorldPosition(mThief)) <= Touch))
		{
			rate = 2.0f; // too close to miss
			mSpot = Scene.GetWorldPosition(mThief);
		}
		mAwareness = Clamp(mAwareness + rate * dt, 0.0f, 1.0f);
	}

	private void Patrol()
	{
		mState = .Patrol;
		if (!Scene.IsValid(mPoint))
			mPoint = Scene.IsValid(mRoute) ? Scene.GetFirstChild(mRoute) : .Invalid;
		Go(mPoint, WalkSpeed);
	}

	private void Next()
	{
		if (Scene.IsValid(mPoint))
			mPoint = Scene.GetNextSibling(mPoint);
		if (!Scene.IsValid(mPoint) && Scene.IsValid(mRoute))
			mPoint = Scene.GetFirstChild(mRoute);
		Go(mPoint, WalkSpeed);
	}

	private void Go(EntityHandle point, float speed)
	{
		if (!Scene.IsValid(point))
			return;
		if (let agent = Get<NavAgentComponent>())
			agent.NavigateAt(Scene.GetWorldPosition(point), speed, 0.3f);
	}

	private void Search(Float3 at)
	{
		mState = .Search;
		mTimer = SearchSeconds;
		if (let agent = Get<NavAgentComponent>())
			agent.NavigateAt(at, WalkSpeed, 0.6f);
	}

	/// The body faces where it goes, or (suspicious) the thief; the graph follows the speed.
	private void Animate(float dt)
	{
		let p = Scene.GetWorldPosition(Entity);
		// The crowd's own velocity for him, not his positions differenced: behaviours update
		// before the crowd, so a position here is last frame's, and dividing its change by this
		// frame's time swings the speed (and the graph's blend) with every uneven frame.
		let agent = Get<NavAgentComponent>();
		let v = (agent != null) ? agent.DesiredVelocity : Float3(0.0f, 0.0f, 0.0f);
		let speed = Sqrt(v.X * v.X + v.Z * v.Z);
		if ((speed > 0.2f) && (mState != .Suspicious))
			Face(.(p.X + v.X, p.Y, p.Z + v.Z), dt);
		if (!Scene.IsValid(mFigure))
			mFigure = Pieces.Figure(Scene, Entity, "Guard", "GuardRig");
		if (Scene.IsValid(mFigure))
		{
			Pieces.SetFloat(Scene, mFigure, "Speed", speed);
			Pieces.SetBool(Scene, mFigure, "Searching", ((mState == .Search) && (speed < 0.2f)) || (mState == .Suspicious));
		}
	}

	private void Face(Float3 at, float dt)
	{
		let p = Scene.GetWorldPosition(Entity);
		let delta = Pieces.Wrap(Atan2(at.X - p.X, at.Z - p.Z) - mYaw); // the model faces +Z
		mYaw += delta * Min(8.0f * dt, 1.0f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}
}
