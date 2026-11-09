using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Net.Replication;
using Sedulous.Engine.Render;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// One guest of the ball. On a guest's entity, which carries a navigation agent and an Instance
/// Member of its costume's instanced mesh (the Guests entity's: one draw for everyone in that
/// costume); what the guest is doing is its Activity, which is also the clip it plays.
///
/// The orchestra's cue (CueChanged, from the Orchestra) says what the ball does:
/// - Stroll: wander from place to place (the children of Spots), stopping a while at each to
///   stand or to talk; mostly somewhere near, now and then across the ball.
/// - Gather: go to the nearest place and talk there until the cue changes.
/// - Dance: dance, there and then, wherever the guest is (the music calls everyone).
///
/// A bot hunter is a guest too (the Ball hunts for it): it wears its costume on a child, one of six
/// looks, so the clip goes to whichever it wears, and the Ball calls Approach (walk to someone, a
/// little brisk) and Resume (back to the ball). A guest standing in a player's way steps aside, as
/// people at a ball do, then back to its group (walking guests already steer round). Activity is
/// replicated: the host decides it, and every peer's guest plays it.
[Behaviour("masquerade.guest")]
[DisplayName("Guest"), Category("Masquerade")]
[Description("Wanders, talks and dances to the orchestra's cues, and steps out of a player's way; a bot hunter walks up to whom the Ball says.")]
class Guest : Behaviour
{
	[Description("The places guests wander to: its children")]
	public EntityRef Spots = .();
	[Description("The players guests make way for: its children")]
	public EntityRef Players = .();
	[Description("How near a player coming at a standing guest makes it step aside (m)")]
	public float MakeWayRange = 1.3f;
	[Description("Walking speed (m/s): the Walk clip's")]
	public float WalkSpeed = 1.0f;
	[Description("How far from a place a guest stands (m), so groups spread round it")]
	public float Spread = 2.0f;
	[Description("Shortest stop at a place (s)")]
	public float StayMin = 8.0f;
	[Description("Longest stop at a place (s)")]
	public float StayMax = 24.0f;
	[Description("How often the next place is a near one (0 to 1)")]
	public float NearChance = 0.85f;
	[Description("What the guest is doing (0 idle, 1 walk, 2 talk, 3 dance): the clip it plays"), Replicated]
	public int32 Activity = 0;

	private int32 mCue = Cues.Stroll;
	private bool mGoing = false;
	private float mStay = 0.0f;
	/// What to do on arriving.
	private int32 mSettle = Clips.Idle;
	private float mYaw = 0.0f;
	/// The middle of where it is going: a group faces it.
	private Float3 mPlace = .(0.0f, 0.0f, 0.0f);
	private bool mHasPlace = false;
	/// The spot by the place it is walking to.
	private Float3 mTarget = .(0.0f, 0.0f, 0.0f);
	/// Where it was at the last progress check.
	private Float3 mLast = .(0.0f, 0.0f, 0.0f);
	/// Until the next progress check.
	private float mCheck = 0.0f;
	/// Seconds on the way.
	private float mWalked = 0.0f;
	private List<EntityHandle> mSpots = new .() ~ delete _;
	/// The entity Players names in this scene, found as it starts.
	private EntityHandle mPlayers = .Invalid;
	/// A bot walking to someone it means to tag.
	private bool mApproaching = false;
	/// A client's guest, its agent stopped for the host's transforms.
	private bool mHandedOver = false;
	/// Stepping out of a player's way.
	private bool mAside = false;
	private float mAsideFor = 0.0f;
	/// What it was doing, to go back to.
	private int32 mAsideActivity = 0;
	/// Until the next look for a player coming.
	private float mWayCheck = 0.0f;

	protected override void OnStart()
	{
		Listen<CueChanged>(new [=this] (evt) => OnCue(evt.Cue));
		GatherChildren(Scene.FindEntity(Spots.Id), mSpots);
		mPlayers = Scene.FindEntity(Players.Id);
		let random = Random;
		mYaw = Pieces.Range(random, -3.14159f, 3.14159f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
		// Start mid-evening: some walking, some standing, some talking.
		mStay = Pieces.Range(random, 0.0f, StayMax);
		Activity = Pieces.Toss(random) ? Clips.Talk : Clips.Idle;
		mWayCheck = Pieces.Range(random, 0.0f, 0.25f); // not every guest looks on the same frame
	}

	private void OnCue(int32 cue)
	{
		if (cue == mCue)
			return;
		mCue = cue;
		if (Authority && !mApproaching)
		{
			// Not all at once: a guest finishes a sentence before following the music.
			mStay = Pieces.Range(Random, 0.0f, 2.5f);
			if (mGoing)
			{
				if (let agent = Get<NavAgentComponent>())
					agent.Stop();
				mGoing = false;
				Activity = Clips.Idle;
			}
		}
	}

	protected override void OnUpdate(float dt)
	{
		if (Authority && (dt > 0.0f))
		{
			Decide(dt);
		}
		else if (!mHandedOver)
		{
			// Joined: the host moves this guest now, so its own agent (walking since the scene
			// loaded) stops, or it would fight the replicated transform.
			if (let agent = Get<NavAgentComponent>())
				agent.Stop();
			mHandedOver = true;
		}
		PlayClip((uint32)Activity);
		Turn(dt);
	}

	/// A bot's order (the Ball): walk, a little brisk, to `at` (where the one it suspects is now;
	/// ordered again as they move).
	public void Approach(Float3 at)
	{
		mApproaching = true;
		mGoing = false;
		if (let agent = Get<NavAgentComponent>())
			agent.NavigateAt(at, WalkSpeed * 1.3f, 0.3f);
		Activity = Clips.Walk;
	}

	/// A bot's order (the Ball): back to the ball, soon.
	public void Resume()
	{
		mApproaching = false;
		if (let agent = Get<NavAgentComponent>())
			agent.Stop();
		Activity = Clips.Idle;
		mStay = Pieces.Range(Random, 1.0f, 4.0f);
	}

	/// The clip on the guest's own Instance Member, or (a hunter) on each of its looks: only the
	/// one it wears is drawn.
	private void PlayClip(uint32 clip)
	{
		if (let member = Get<InstanceMemberComponent>())
		{
			member.Clip = clip;
			return;
		}
		var child = Scene.GetFirstChild(Entity);
		while (Scene.IsValid(child))
		{
			if (let look = Scene.GetComponent<InstanceMemberComponent>(child))
				look.Clip = clip;
			child = Scene.GetNextSibling(child);
		}
	}

	private void Decide(float d)
	{
		let agent = Get<NavAgentComponent>();
		if (agent == null)
			return;
		if (MakeWay(agent, d))
			return;
		if (mApproaching)
		{
			if (agent.Finished)
				Activity = Clips.Idle; // there; the Ball decides what comes next
			return;
		}
		let random = Random;
		if (mGoing)
		{
			if (Arrived(agent, d))
			{
				agent.Stop();
				mGoing = false;
				Activity = mSettle;
				mStay = (mCue == Cues.Stroll) ? Pieces.Range(random, StayMin, StayMax) : 1.0e9f;
			}
			return;
		}
		mStay -= d;
		if (mStay > 0.0f)
			return;
		if (mCue == Cues.Dance)
		{
			Activity = Clips.Dance; // until the music changes
			mStay = 1.0e9f;
			return;
		}
		// Off to the next place, and what to do there, by the cue.
		if (mSpots.Count == 0)
		{
			mStay = StayMax;
			return;
		}
		let place = (mCue == Cues.Gather) ? Nearest() : Pick();
		let a = Pieces.Range(random, -3.14159f, 3.14159f);
		let r = Spread * Sqrt(Pieces.Range(random, 0.1f, 1.0f));
		mPlace = Scene.GetWorldPosition(place);
		mHasPlace = true;
		let at = Float3(mPlace.X + Sin(a) * r, mPlace.Y, mPlace.Z + Cos(a) * r);
		mTarget = at;
		mLast = Scene.GetWorldPosition(Entity);
		mCheck = 1.0f;
		mWalked = 0.0f;
		if (mCue == Cues.Gather)
			mSettle = Clips.Talk;
		else
			mSettle = (Pieces.Range(random, 0.0f, 1.0f) < 0.6f) ? Clips.Talk : Clips.Idle;
		agent.NavigateAt(at, WalkSpeed, 0.4f);
		Activity = Clips.Walk;
		mGoing = true;
	}

	/// A standing guest a player is coming at steps aside, to the side it already stands on, and
	/// after a moment goes back to what it was doing. True while it is out of the way.
	private bool MakeWay(NavAgentComponent* agent, float d)
	{
		if (mAside)
		{
			mAsideFor -= d;
			if (mAsideFor <= 0.0f)
			{
				mAside = false;
				agent.Stop();
				Activity = mAsideActivity;
			}
			return true;
		}
		if (mGoing || mApproaching || !Scene.IsValid(mPlayers))
			return false;
		mWayCheck -= d;
		if (mWayCheck > 0.0f)
			return false;
		mWayCheck = 0.25f;
		let p = Scene.GetWorldPosition(Entity);
		var player = Scene.GetFirstChild(mPlayers);
		while (Scene.IsValid(player))
		{
			let q = Scene.GetWorldPosition(player);
			let dx = p.X - q.X;
			let dz = p.Z - q.Z;
			let distance = Sqrt(dx * dx + dz * dz);
			let walker = Scene.GetComponent<NavAgentComponent>(player);
			if ((walker != null) && (distance < MakeWayRange) && (distance > 0.01f))
			{
				let v = walker.DesiredVelocity;
				let speed = Sqrt(v.X * v.X + v.Z * v.Z);
				// Coming at it: moving, and this guest ahead of it.
				if ((speed > 0.3f) && ((dx * v.X + dz * v.Z) / (distance * speed) > 0.5f))
				{
					// Out of the line it walks, on the side the guest is already on.
					let side = ((v.X * dz - v.Z * dx) > 0.0f) ? 1.0f : -1.0f;
					let ox = -v.Z / speed * side;
					let oz = v.X / speed * side;
					agent.NavigateAt(.(p.X + ox * 0.9f, p.Y, p.Z + oz * 0.9f), 1.4f, 0.1f);
					mAsideActivity = Activity;
					Activity = Clips.Walk;
					mAside = true;
					mAsideFor = 1.2f;
					return true;
				}
			}
			player = Scene.GetNextSibling(player);
		}
		return false;
	}

	/// There, or as near as the crowd lets it: a place is a group, and its middle is taken. Close
	/// to its spot, or near the place and no longer getting anywhere (the group in the way), or
	/// walking far too long (a spot it cannot reach), it stops where it is.
	private bool Arrived(NavAgentComponent* agent, float d)
	{
		mWalked += d;
		if (agent.Finished)
			return true;
		let p = Scene.GetWorldPosition(Entity);
		if ((Pieces.FlatDistance(p, mTarget) < 0.6f) || (mWalked > 45.0f))
			return true;
		mCheck -= d;
		if (mCheck > 0.0f)
			return false;
		mCheck = 1.0f;
		let stuck = Pieces.FlatDistance(p, mLast) < 0.3f;
		mLast = p;
		return stuck && (Pieces.FlatDistance(p, mPlace) < Spread + 2.5f);
	}

	/// The next place: mostly the nearest of a few picked at random, so most walks are short and
	/// the crowd drifts rather than crossing the ball all the time.
	private EntityHandle Pick()
	{
		let random = Random;
		let last = (int32)mSpots.Count - 1;
		var best = mSpots[Pieces.IntRange(random, 0, last)];
		if (Pieces.Range(random, 0.0f, 1.0f) >= NearChance)
			return best;
		let p = Scene.GetWorldPosition(Entity);
		var bestDistance = Pieces.FlatDistance(p, Scene.GetWorldPosition(best));
		for (int32 k < 3)
		{
			let other = mSpots[Pieces.IntRange(random, 0, last)];
			let distance = Pieces.FlatDistance(p, Scene.GetWorldPosition(other));
			if ((distance < bestDistance) && (distance > 1.0f)) // not the place it is already at
			{
				best = other;
				bestDistance = distance;
			}
		}
		return best;
	}

	private EntityHandle Nearest()
	{
		let p = Scene.GetWorldPosition(Entity);
		var best = mSpots[0];
		var bestDistance = Pieces.FlatDistance(p, Scene.GetWorldPosition(best));
		for (int k = 1; k < mSpots.Count; k++)
		{
			let distance = Pieces.FlatDistance(p, Scene.GetWorldPosition(mSpots[k]));
			if (distance < bestDistance)
			{
				best = mSpots[k];
				bestDistance = distance;
			}
		}
		return best;
	}

	/// Facing where the crowd moves the guest (its own velocity, not positions differenced:
	/// behaviours update before the crowd).
	private void Turn(float d)
	{
		let agent = Get<NavAgentComponent>();
		if ((agent == null) || (d <= 0.0f))
			return;
		let v = agent.DesiredVelocity;
		var vx = v.X;
		var vz = v.Z;
		if (vx * vx + vz * vz < 0.04f)
		{
			if (!mHasPlace || (Activity == Clips.Walk))
				return;
			let p = Scene.GetWorldPosition(Entity); // standing: face the middle of the group
			vx = mPlace.X - p.X;
			vz = mPlace.Z - p.Z;
			if (vx * vx + vz * vz < 0.01f)
				return;
		}
		let want = Atan2(vx, vz); // the model faces +Z
		mYaw += Pieces.Wrap(want - mYaw) * Min(6.0f * d, 1.0f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}

	/// The host decides; a client's guest plays what it is told (offline is the host).
	private bool Authority => !Pieces.IsClient(Run);

	private void GatherChildren(EntityHandle parent, List<EntityHandle> into)
	{
		if (!Scene.IsValid(parent))
			return;
		var child = Scene.GetFirstChild(parent);
		while (Scene.IsValid(child))
		{
			into.Add(child);
			child = Scene.GetNextSibling(child);
		}
	}
}
