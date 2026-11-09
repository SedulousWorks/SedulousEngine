using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Net.Replication;
using Sedulous.Engine.Render;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// The round. Four hunters, the player and three bots, each hunting another and hunted by a third,
/// among guests who dress as they do. A hunter knows only its target's costume, and several guests
/// wear each one.
///
/// - The round: each hunter gets a costume (one of its six looks shown) and a target, the others in
///   a ring; RoundSeconds later the most points wins.
/// - A tag (Tag, from a Player, or a bot's, here): the nearest person within TagReach in front of
///   the tagger. The target: points, and the target respawns elsewhere in a new costume. Anyone
///   else: points lost, and the tagger's mask flares (its Flare light) for RevealSeconds, there for
///   everyone to see.
/// - The bots: guests (Guest) that this hunts for. A bot grows suspicious of its target when the
///   target stands out near it (sprinting, its mask flaring, not dancing when the music calls,
///   still walking when everyone gathers) and, sure enough, walks up to it and tags it. Now and
///   then it guesses instead: someone in its target's costume, often wrong, and its mask flares.
/// - The game (MasqueradeGame) hears what the player needs: HudReport each quarter second (score,
///   seconds left, the target's costume, the hunter's rank), RoundNote when something happens to
///   the player, RoundOver with the scores, and RoundStarted when the host starts another.
///
/// Over the network the host decides, and every peer's Ball follows its replicated state: each
/// seat's owner (a player id, or -1 for a bot), costume and target, the scores, the time, which
/// masks flare. A joining player takes a bot's seat (the host spawns them a hunter, HunterPrefab,
/// where the bot stands; the bot wanders on as a plain guest) and gives it back on leaving. A
/// client's input and tags come as messages ("input", "tag"); notes go to one player ("note").
/// Entity active flags do not replicate, so every peer shows each hunter's look from the
/// replicated costumes itself.
[Behaviour("masquerade.ball")]
[DisplayName("Ball"), Category("Masquerade")]
[Description("Runs the round: the hunters' costumes and targets, tags, flares, the bots' hunting and the scores, replicated to every peer.")]
class Ball : Behaviour
{
	/// The hunter whose mark you are, nearer than this (m): you hear of it.
	private const float cNearMetres = 6.0f;

	[Description("The player (seat 0)")]
	public EntityRef Player = .();
	[Description("Bot 1 (seat 1)")]
	public EntityRef Bot1 = .();
	[Description("Bot 2 (seat 2)")]
	public EntityRef Bot2 = .();
	[Description("Bot 3 (seat 3)")]
	public EntityRef Bot3 = .();
	[Description("The crowd: a child per costume, in the costume order, its guests under it")]
	public EntityRef Crowd = .();
	[Description("The places guests go: its children (where the tagged reappear)")]
	public EntityRef Spots = .();
	[Description("Seconds in a round")]
	public float RoundSeconds = 240.0f;
	[Description("How near a tag reaches (m)")]
	public float TagReach = 1.6f;
	[Description("Seconds a wrong tag shows the tagger")]
	public float RevealSeconds = 4.0f;
	[Description("Points for tagging your target")]
	public int32 TargetPoints = 100;
	[Description("Points lost for tagging anyone else")]
	public int32 MissPoints = 25;
	[Description("Moving faster than this (m/s) is sprinting")]
	public float SprintSpeed = 1.7f;
	[Description("How far a bot watches for its target standing out (m)")]
	public float WatchRange = 16.0f;
	[Description("Shortest wait before a bot guesses (s)")]
	public float GuessMin = 20.0f;
	[Description("Longest wait before a bot guesses (s)")]
	public float GuessMax = 45.0f;
	[Description("A bot gives up walking up to someone after this (s)")]
	public float ApproachGiveUp = 15.0f;
	[Description("Where players' hunters go (guests make way for its children)")]
	public EntityRef Players = .();
	[Description("The hunter the host spawns for a joining player")]
	public Ref<PrefabResource> HunterPrefab = .(Guid());

	[Description("Seconds left in the round"), Replicated]
	public float TimeLeft = 0.0f;
	[Description("The round is over"), Replicated]
	public bool Over = false;
	[Description("Seat 0's score"), Replicated]
	public int32 Score0 = 0;
	[Description("Seat 1's score"), Replicated]
	public int32 Score1 = 0;
	[Description("Seat 2's score"), Replicated]
	public int32 Score2 = 0;
	[Description("Seat 3's score"), Replicated]
	public int32 Score3 = 0;
	[Description("Seat 0's owner: a player id (0 the host), or -1 for a bot"), Replicated]
	public int32 Owner0 = 0;
	[Description("Seat 1's owner"), Replicated]
	public int32 Owner1 = -1;
	[Description("Seat 2's owner"), Replicated]
	public int32 Owner2 = -1;
	[Description("Seat 3's owner"), Replicated]
	public int32 Owner3 = -1;
	[Description("Seat 0's costume"), Replicated]
	public int32 Costume0 = 0;
	[Description("Seat 1's costume"), Replicated]
	public int32 Costume1 = 0;
	[Description("Seat 2's costume"), Replicated]
	public int32 Costume2 = 0;
	[Description("Seat 3's costume"), Replicated]
	public int32 Costume3 = 0;
	[Description("Seat 0's target seat"), Replicated]
	public int32 Target0 = 1;
	[Description("Seat 1's target seat"), Replicated]
	public int32 Target1 = 2;
	[Description("Seat 2's target seat"), Replicated]
	public int32 Target2 = 3;
	[Description("Seat 3's target seat"), Replicated]
	public int32 Target3 = 0;
	[Description("Which seats' masks flare (a bit a seat)"), Replicated]
	public int32 Flaring = 0;

	/// Each seat's body now: its bot, or the hunter of the player who holds it.
	private EntityHandle[Pieces.Hunters] mHunters;
	/// Each seat's own body when no player has it (seat 0: the host's player).
	private EntityHandle[Pieces.Hunters] mBots;
	/// The costume each seat's body shows now (-1 not yet).
	private int32[Pieces.Hunters] mDressed;
	/// Players' hunters, as they announce themselves (AddHunter).
	private List<EntityHandle> mKnown = new .() ~ delete _;
	private bool mOverTold = false;
	/// The guests in each costume.
	private List<EntityHandle>[Pieces.Costumes] mGroups;
	private List<EntityHandle> mSpots = new .() ~ delete _;
	/// Each hunter's costume.
	private int32[Pieces.Hunters] mCostume;
	/// Each hunter's target seat.
	private int32[Pieces.Hunters] mTarget;
	/// Seconds its mask still flares.
	private float[Pieces.Hunters] mReveal;
	private Float3[Pieces.Hunters] mLastPos;
	/// Measured over the last half second.
	private float[Pieces.Hunters] mSpeed;
	/// A bot's, of its target.
	private float[Pieces.Hunters] mSuspicion;
	private float[Pieces.Hunters] mGuessIn;
	/// Whom a bot is walking up to (invalid: no one).
	private EntityHandle[Pieces.Hunters] mChasing;
	private float[Pieces.Hunters] mChaseFor;
	/// Until a bot's approach order is refreshed.
	private float[Pieces.Hunters] mOrderIn;
	private float mSample = 0.0f;
	private float mHud = 0.0f;
	/// The InReach last posted.
	private bool mReachTold = false;
	/// The HunterNear last posted.
	private bool mNearTold = false;
	private int32 mCue = 0;
	/// A tag's search: the nearest in reach so far.
	private EntityHandle mBest = .Invalid;
	private float mBestDistance = 0.0f;
	/// A flaring mask's pulse.
	private float mPulse = 0.0f;
	/// It registered its network handlers (OnStart), so it takes them off as it goes.
	private bool mListening = false;

	public this()
	{
		for (int h < Pieces.Hunters)
		{
			mHunters[h] = .Invalid;
			mBots[h] = .Invalid;
			mDressed[h] = -1;
			mChasing[h] = .Invalid;
		}
		for (int c < Pieces.Costumes)
			mGroups[c] = new .();
	}

	public ~this()
	{
		for (int c < Pieces.Costumes)
			delete mGroups[c];
	}

	protected override void OnStart()
	{
		mHunters[0] = Scene.FindEntity(Player.Id);
		mHunters[1] = Scene.FindEntity(Bot1.Id);
		mHunters[2] = Scene.FindEntity(Bot2.Id);
		mHunters[3] = Scene.FindEntity(Bot3.Id);
		for (int h < Pieces.Hunters)
		{
			mBots[h] = mHunters[h];
			mDressed[h] = -1;
		}
		// The network's half: the host hears input, tags, joins and leaves; a client its notes (the
		// host's map is the game's: MasqueradeGame). Registered on every peer (a handler that never
		// fires costs nothing).
		if (let net = Pieces.Net(Run))
		{
			net.OnNumber("input", new [=this] (player, value) => OnNetInput(player, value));
			net.On("tag", new [=this] (player) => OnNetTag(player));
			net.OnNumber("note", new [=this] (player, value) => OnNetNote(value));
			net.OnJoin(new [=this] (player) => OnJoined(player));
			net.OnLeave(new [=this] (player) => OnLeft(player));
			mListening = true;
		}
		Listen<CueChanged>(new [=this] (evt) => { mCue = evt.Cue; });
		let crowd = Scene.FindEntity(Crowd.Id);
		int k = 0;
		var group = Scene.IsValid(crowd) ? Scene.GetFirstChild(crowd) : EntityHandle.Invalid;
		while (Scene.IsValid(group) && (k < Pieces.Costumes))
		{
			var guest = Scene.GetFirstChild(group);
			while (Scene.IsValid(guest))
			{
				mGroups[k].Add(guest);
				guest = Scene.GetNextSibling(guest);
			}
			k++;
			group = Scene.GetNextSibling(group);
		}
		let spots = Scene.FindEntity(Spots.Id);
		var spot = Scene.IsValid(spots) ? Scene.GetFirstChild(spots) : EntityHandle.Invalid;
		while (Scene.IsValid(spot))
		{
			mSpots.Add(spot);
			spot = Scene.GetNextSibling(spot);
		}
		if (!Pieces.IsClient(Run))
			StartRound();
	}

	/// The network handlers go with the Ball: its map unloads, and the next map's Ball registers
	/// its own.
	protected override void OnDestroy()
	{
		if (!mListening)
			return;
		mListening = false;
		if (let net = Pieces.Net(Run))
		{
			net.Off("input");
			net.Off("tag");
			net.Off("note");
			net.OffJoin();
			net.OffLeave();
		}
	}

	private void StartRound()
	{
		let random = Random;
		// The targets: a ring through the seats in a random order.
		int32[Pieces.Hunters] order = .(0, 1, 2, 3);
		for (int32 i = Pieces.Hunters - 1; i > 0; i--)
		{
			let j = Pieces.IntRange(random, 0, i);
			let t = order[i];
			order[i] = order[j];
			order[j] = t;
		}
		for (int32 i < Pieces.Hunters)
		{
			mTarget[order[i]] = order[(i + 1) % Pieces.Hunters];
			mCostume[i] = Pieces.IntRange(random, 0, Pieces.Costumes - 1);
			mReveal[i] = 0.0f;
			mSuspicion[i] = 0.0f;
			mGuessIn[i] = Pieces.Range(random, GuessMin, GuessMax);
			mChasing[i] = .Invalid;
			mLastPos[i] = Scene.GetWorldPosition(mHunters[i]);
		}
		Score0 = 0;
		Score1 = 0;
		Score2 = 0;
		Score3 = 0;
		TimeLeft = RoundSeconds;
		Over = false;
		Publish();
	}

	/// The host's seat state into the replicated fields every peer reads.
	private void Publish()
	{
		Costume0 = mCostume[0];
		Costume1 = mCostume[1];
		Costume2 = mCostume[2];
		Costume3 = mCostume[3];
		Target0 = mTarget[0];
		Target1 = mTarget[1];
		Target2 = mTarget[2];
		Target3 = mTarget[3];
	}

	private int32 CostumeOf(int32 seat) => (seat == 0) ? Costume0 : ((seat == 1) ? Costume1 : ((seat == 2) ? Costume2 : Costume3));

	private int32 TargetOf(int32 seat) => (seat == 0) ? Target0 : ((seat == 1) ? Target1 : ((seat == 2) ? Target2 : Target3));

	private int32 OwnerOf(int32 seat) => (seat == 0) ? Owner0 : ((seat == 1) ? Owner1 : ((seat == 2) ? Owner2 : Owner3));

	private void SetOwner(int32 seat, int32 owner)
	{
		if (seat == 0)
			Owner0 = owner;
		else if (seat == 1)
			Owner1 = owner;
		else if (seat == 2)
			Owner2 = owner;
		else
			Owner3 = owner;
	}

	/// The seat a player holds, or -1.
	private int32 SeatOfPlayer(int32 who)
	{
		for (int32 h < Pieces.Hunters)
		{
			if (OwnerOf(h) == who)
				return h;
		}
		return -1;
	}

	/// Every peer: each seat's body (its bot, or the hunter of the player who holds it), dressed in
	/// the seat's replicated costume.
	private void FollowSeats()
	{
		for (int32 h < Pieces.Hunters)
		{
			var body = mBots[h];
			let owner = OwnerOf(h);
			if (owner > 0)
			{
				body = .Invalid;
				for (let known in mKnown)
				{
					if (!Scene.IsValid(known))
						continue;
					let network = Scene.GetComponent<NetworkComponent>(known);
					if ((network != null) && ((int32)network.Owner == owner))
						body = known;
				}
				if (!Scene.IsValid(body))
					continue; // its hunter has not reached this peer yet
			}
			if (body != mHunters[h])
			{
				mHunters[h] = body;
				mDressed[h] = -1;
			}
			if (mDressed[h] != CostumeOf(h))
				Dress(h, CostumeOf(h));
		}
	}

	/// A player's hunter announcing itself (a Player, on every peer), so the seats can find it.
	public void AddHunter(EntityHandle hunter)
	{
		mKnown.Add(hunter);
	}

	/// The host: another round in the same scene (MasqueradeGame, hosting), the players kept.
	public void Restart()
	{
		if (!Pieces.IsClient(Run))
			StartRound();
	}

	/// A tag by a player (the host's own Player gives its player id; a client's comes as a
	/// message).
	public void Tag(int32 who)
	{
		let seat = SeatOfPlayer(who);
		if (Pieces.IsClient(Run) || Over || (seat < 0) || (seat >= Pieces.Hunters))
			return;
		let found = InReachOf(seat);
		if (Scene.IsValid(found))
			Resolve(seat, found);
	}

	/// Whether the hunter whose target `seat` is stands within cNearMetres of it.
	private bool IsHunterNear(int32 seat)
	{
		let p = Scene.GetWorldPosition(mHunters[seat]);
		for (int32 h < Pieces.Hunters)
		{
			if ((h == seat) || (TargetOf(h) != seat))
				continue;
			let q = Scene.GetWorldPosition(mHunters[h]);
			let dx = q.X - p.X;
			let dz = q.Z - p.Z;
			if (dx * dx + dz * dz < cNearMetres * cNearMetres)
				return true;
		}
		return false;
	}

	/// Whom a tag by `seat` would reach: the nearest person within TagReach in front of its hunter
	/// (or right beside it), else none. A tag's search, and the HUD's Tag prompt while it finds one.
	private EntityHandle InReachOf(int32 seat)
	{
		let tagger = mHunters[seat];
		let p = Scene.GetWorldPosition(tagger);
		let ahead = RotateVector(Scene.GetWorldRotation(tagger), .(0.0f, 0.0f, 1.0f));
		mBest = .Invalid;
		mBestDistance = TagReach;
		for (int c < Pieces.Costumes)
		{
			for (let guest in mGroups[c])
				Consider(guest, p, ahead);
		}
		for (int32 h < Pieces.Hunters)
		{
			if (h != seat)
				Consider(mHunters[h], p, ahead);
		}
		return mBest;
	}

	/// Someone in reach and in front (or right beside), nearer than the best so far (mBest).
	private void Consider(EntityHandle person, Float3 p, Float3 ahead)
	{
		let q = Scene.GetWorldPosition(person);
		let dx = q.X - p.X;
		let dz = q.Z - p.Z;
		let distance = Sqrt(dx * dx + dz * dz);
		if (distance >= mBestDistance)
			return;
		if ((distance > 0.7f) && ((dx * ahead.X + dz * ahead.Z) / distance < 0.3f))
			return; // behind or well to the side
		mBest = person;
		mBestDistance = distance;
	}

	private void Resolve(int32 seat, EntityHandle tagged)
	{
		let victim = SeatOf(tagged);
		if (victim == mTarget[seat])
		{
			AddScore(seat, TargetPoints);
			Respawn(victim);
			NoteTo(seat, .GotTarget);
			NoteTo(victim, .Tagged);
			return;
		}
		AddScore(seat, -MissPoints);
		mReveal[seat] = RevealSeconds;
		NoteTo(seat, .Missed);
		for (int32 h < Pieces.Hunters) // everyone else sees the flare
		{
			if (h != seat)
				NoteTo(h, .Flare);
		}
	}

	/// A note to the player at a seat: the host's own as an event here, a client's as a message, a
	/// bot's nowhere.
	private void NoteTo(int32 seat, NoteKind what)
	{
		let owner = OwnerOf(seat);
		if (owner == 0)
			Post(RoundNote(what));
		else if (owner > 0)
		{
			if (let net = Pieces.Net(Run))
				net.RpcNumberTo(owner, "note", (double)(int32)what);
		}
	}

	private void Respawn(int32 seat)
	{
		let random = Random;
		// Somewhere well away from whoever hunts it, in a costume it was not wearing.
		let hunter = mHunters[HunterOf(seat)];
		var at = Scene.GetWorldPosition(mHunters[seat]);
		for (int tries = 0; (tries < 12) && (mSpots.Count > 0); tries++)
		{
			let candidate = Scene.GetWorldPosition(mSpots[Pieces.IntRange(random, 0, (int32)mSpots.Count - 1)]);
			at = candidate;
			if (Pieces.FlatDistance(candidate, Scene.GetWorldPosition(hunter)) > 14.0f)
				break;
		}
		if (let agent = Scene.GetComponent<NavAgentComponent>(mHunters[seat]))
			agent.Warp(at);
		mCostume[seat] = (mCostume[seat] + Pieces.IntRange(random, 1, Pieces.Costumes - 1)) % Pieces.Costumes;
		Publish(); // every peer dresses it (FollowSeats)
		mReveal[seat] = 0.0f;
		mLastPos[seat] = at;
		let hunterSeat = HunterOf(seat);
		mSuspicion[hunterSeat] = 0.0f;
		StopChase(hunterSeat);
		if (seat != 0)
			StopChase(seat);
	}

	/// A hunter's costume: the one look of its six shown (on this peer: active flags do not
	/// replicate).
	private void Dress(int32 seat, int32 costume)
	{
		mDressed[seat] = costume;
		int32 k = 0;
		var child = Scene.GetFirstChild(mHunters[seat]);
		while (Scene.IsValid(child))
		{
			if (Scene.GetComponent<InstanceMemberComponent>(child) != null)
			{
				Scene.SetActive(child, k == costume);
				k++;
			}
			child = Scene.GetNextSibling(child);
		}
	}

	protected override void OnUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		FollowSeats();
		Flares(dt);
		Tell(dt);
		if (Pieces.IsClient(Run) || Over)
			return;
		TimeLeft -= dt;
		if (TimeLeft <= 0.0f)
		{
			TimeLeft = 0.0f;
			Over = true; // every peer tells its game (Tell)
			return;
		}
		mSample -= dt;
		if (mSample <= 0.0f)
		{
			mSample = 0.5f;
			for (int h < Pieces.Hunters)
			{
				let now = Scene.GetWorldPosition(mHunters[h]);
				mSpeed[h] = Pieces.FlatDistance(now, mLastPos[h]) / 0.5f;
				mLastPos[h] = now;
			}
		}
		for (int32 b = 1; b < Pieces.Hunters; b++)
		{
			if (OwnerOf(b) < 0) // a seat a player holds hunts for itself
				Hunt(b, dt);
		}
		int32 mask = 0;
		for (int32 h < Pieces.Hunters)
		{
			if (mReveal[h] > 0.0f)
			{
				mReveal[h] = Max(mReveal[h] - dt, 0.0f);
				mask |= (int32)1 << h;
			}
		}
		Flaring = mask;
	}

	/// Every peer: the game hears this peer's player's seat (the HUD four times a second) and the
	/// round's end, from the replicated state.
	private void Tell(float d)
	{
		let seat = SeatOfPlayer(Pieces.LocalPlayer(Run));
		// Someone to tag in front of this peer's hunter: the game shows Tag's prompt while there is.
		let reach = !Over && (seat >= 0) && Scene.IsValid(InReachOf(seat));
		if (reach != mReachTold)
		{
			mReachTold = reach;
			Post(InReach(reach));
		}
		// The hunter whose mark you are, near: the game says so, quietly.
		let near = !Over && (seat >= 0) && IsHunterNear(seat);
		if (near != mNearTold)
		{
			mNearTold = near;
			Post(HunterNear(near));
		}
		mHud -= d;
		if ((mHud <= 0.0f) && (seat >= 0))
		{
			mHud = 0.25f;
			Post(HudReport(ScoreOf(seat), TimeLeft, CostumeOf(TargetOf(seat)), Rank(seat)));
		}
		if (!Over && mOverTold)
		{
			mOverTold = false;
			Post(RoundStarted(TimeLeft)); // a new round: the host started another
		}
		if (Over && !mOverTold)
		{
			mOverTold = true;
			// The player's own score first, then the others' in seat order.
			int32[Pieces.Hunters - 1] others = .(0, 0, 0);
			int32 count = 0;
			for (int32 h < Pieces.Hunters)
			{
				if ((h != seat) && (count < Pieces.Hunters - 1))
					others[count++] = ScoreOf(h);
			}
			Post(RoundOver((seat >= 0) ? ScoreOf(seat) : 0, others[0], others[1], others[2]));
		}
	}

	/// A flaring mask: its light pulses while the seat's flare bit is set, on every peer.
	private void Flares(float d)
	{
		mPulse += d;
		for (int32 h < Pieces.Hunters)
		{
			if (!Scene.IsValid(mHunters[h]))
				continue;
			let on = (Flaring & ((int32)1 << h)) != 0;
			Glow(mHunters[h], on);
			let flare = Scene.FindChildByName(mHunters[h], "Flare");
			if (!Scene.IsValid(flare))
				continue;
			if (let light = Scene.GetComponent<LightComponent>(flare))
				light.Intensity = on ? (6.0f + 4.0f * Sin(mPulse * 12.0f)) : 0.0f;
		}
	}

	/// A flaring mask glows (Mask.hlsl: the instance's tint alpha below 1 is the glow; the cloth,
	/// drawn with the same tint, keeps its colour). Every look of the hunter, so the one shown does.
	private void Glow(EntityHandle hunter, bool on)
	{
		var child = Scene.GetFirstChild(hunter);
		while (Scene.IsValid(child))
		{
			if (let look = Scene.GetComponent<InstanceMemberComponent>(child))
				look.Tint = .(1.0f, 1.0f, 1.0f, on ? 0.0f : 1.0f);
			child = Scene.GetNextSibling(child);
		}
	}

	// ---- the network ----

	/// The host: a client's stick, sprint and dance (a Player packs them in one number), to the
	/// hunter that player holds.
	private void OnNetInput(int32 sender, double packed)
	{
		let seat = SeatOfPlayer(sender);
		if (Pieces.IsClient(Run) || (seat < 0) || !Scene.IsValid(mHunters[seat]))
			return;
		var v = (int32)packed;
		let flags = v % 4;
		v /= 4;
		let z = (float)(v % 201) / 100.0f - 1.0f;
		let x = (float)(v / 201) / 100.0f - 1.0f;
		Pieces.PlayerOn(Scene, mHunters[seat])?.RemoteInput(.(x, z, ((flags & 1) != 0) ? 1.0f : 0.0f, ((flags & 2) != 0) ? 1.0f : 0.0f));
	}

	private void OnNetTag(int32 sender)
	{
		if (!Pieces.IsClient(Run))
			Tag(sender);
	}

	/// A client: a note for its player, from the host.
	private void OnNetNote(double what)
	{
		if (Pieces.IsClient(Run))
			Post(RoundNote((NoteKind)(int32)what));
	}

	/// The host: a player has joined. They take a bot's seat with a score of their own, from zero:
	/// a hunter spawned for them where the bot stands, in its costume; the bot wanders on as a plain
	/// guest. No bot seat left: they watch.
	private void OnJoined(int32 who)
	{
		let net = Pieces.Net(Run);
		if ((net == null) || net.IsClient)
			return;
		net.RpcTextTo(who, "map", Scene.Name);
		for (int32 h = 1; h < Pieces.Hunters; h++)
		{
			if (OwnerOf(h) >= 0)
				continue;
			StopChase(h);
			let hunter = net.SpawnFor(who, HunterPrefab.Id, Scene.GetWorldPosition(mBots[h]));
			if (!Scene.IsValid(hunter))
				return;
			let players = Scene.FindEntity(Players.Id);
			if (Scene.IsValid(players))
				Scene.SetParent(hunter, players, true); // guests make way for it
			mKnown.Add(hunter);
			SetOwner(h, who);
			AddScore(h, -ScoreOf(h)); // the player starts at nothing, not at the bot's score
			return;
		}
		net.RpcNumberTo(who, "note", (double)(int32)NoteKind.Full);
	}

	/// The host: a player has left. Their seat goes back to its bot, keeping the score they made,
	/// and their hunter goes.
	private void OnLeft(int32 who)
	{
		if (Pieces.IsClient(Run))
			return;
		let seat = SeatOfPlayer(who);
		if (seat <= 0)
			return;
		let hunter = mHunters[seat];
		SetOwner(seat, -1);
		mHunters[seat] = mBots[seat];
		mDressed[seat] = -1;
		mSuspicion[seat] = 0.0f;
		mGuessIn[seat] = Pieces.Range(Random, GuessMin, GuessMax);
		if (Scene.IsValid(hunter) && (hunter != mBots[seat]))
			Scene.DestroyEntity(hunter);
	}

	/// One bot's hunt: watch its target for standing out, walk up to it when sure, or guess.
	private void Hunt(int32 b, float d)
	{
		let t = mTarget[b];
		let bot = mHunters[b];
		let target = mHunters[t];
		if (Scene.IsValid(mChasing[b]))
		{
			mChaseFor[b] += d;
			let distance = Pieces.FlatDistance(Scene.GetWorldPosition(bot), Scene.GetWorldPosition(mChasing[b]));
			if (distance <= TagReach)
			{
				let tagged = mChasing[b];
				StopChase(b);
				Resolve(b, tagged);
				return;
			}
			if (mChaseFor[b] > ApproachGiveUp)
			{
				StopChase(b);
				return;
			}
			mOrderIn[b] -= d;
			if (mOrderIn[b] <= 0.0f)
			{
				mOrderIn[b] = 0.5f;
				Pieces.GuestOn(Scene, bot)?.Approach(Scene.GetWorldPosition(mChasing[b]));
			}
			return;
		}
		if (Pieces.FlatDistance(Scene.GetWorldPosition(bot), Scene.GetWorldPosition(target)) < WatchRange)
			mSuspicion[b] += StandingOut(t) * d;
		mSuspicion[b] = Max(mSuspicion[b] - 0.03f * d, 0.0f);
		if (mSuspicion[b] >= 1.0f)
		{
			Chase(b, target);
			return;
		}
		mGuessIn[b] -= d;
		if (mGuessIn[b] <= 0.0f)
		{
			mGuessIn[b] = Pieces.Range(Random, GuessMin, GuessMax);
			let guess = SomeoneDressedAs(mCostume[t], b);
			if (Scene.IsValid(guess))
				Chase(b, guess);
		}
	}

	/// How much a hunter stands out right now (suspicion a second): sprinting, its mask flaring,
	/// not dancing when the music calls, walking when everyone gathers.
	private float StandingOut(int32 seat)
	{
		float amount = 0.0f;
		if (mSpeed[seat] > SprintSpeed)
			amount += 0.8f;
		if (mReveal[seat] > 0.0f)
			amount += 2.0f;
		let clip = ClipOf(seat);
		if ((mCue == Cues.Dance) && (clip != Clips.Dance))
			amount += 0.4f;
		else if ((mCue == Cues.Gather) && (clip == Clips.Walk))
			amount += 0.15f;
		return amount;
	}

	/// A guess: someone near the bot in the costume, a guest or a hunter (not the bot itself).
	private EntityHandle SomeoneDressedAs(int32 costume, int32 b)
	{
		let p = Scene.GetWorldPosition(mHunters[b]);
		let nearby = scope List<EntityHandle>();
		for (let guest in mGroups[costume])
		{
			if (Pieces.FlatDistance(p, Scene.GetWorldPosition(guest)) < WatchRange)
				nearby.Add(guest);
		}
		for (int32 h < Pieces.Hunters)
		{
			if ((h != b) && (mCostume[h] == costume) && (Pieces.FlatDistance(p, Scene.GetWorldPosition(mHunters[h])) < WatchRange))
				nearby.Add(mHunters[h]);
		}
		if (nearby.Count == 0)
			return .Invalid;
		return nearby[Pieces.IntRange(Random, 0, (int32)nearby.Count - 1)];
	}

	private void Chase(int32 b, EntityHandle person)
	{
		mChasing[b] = person;
		mChaseFor[b] = 0.0f;
		mOrderIn[b] = 0.0f;
	}

	private void StopChase(int32 b)
	{
		if ((b <= 0) || !Scene.IsValid(mChasing[b]))
			return;
		mChasing[b] = .Invalid;
		Pieces.GuestOn(Scene, mHunters[b])?.Resume();
	}

	/// The clip the hunter's shown look plays.
	private int32 ClipOf(int32 seat)
	{
		var child = Scene.GetFirstChild(mHunters[seat]);
		while (Scene.IsValid(child))
		{
			if (Scene.IsActive(child))
			{
				if (let look = Scene.GetComponent<InstanceMemberComponent>(child))
					return (int32)look.Clip;
			}
			child = Scene.GetNextSibling(child);
		}
		return 0;
	}

	private int32 SeatOf(EntityHandle person)
	{
		for (int32 h < Pieces.Hunters)
		{
			if (mHunters[h] == person)
				return h;
		}
		return -1;
	}

	private int32 HunterOf(int32 seat)
	{
		for (int32 h < Pieces.Hunters)
		{
			if (mTarget[h] == seat)
				return h;
		}
		return seat;
	}

	private void AddScore(int32 seat, int32 points)
	{
		if (seat == 0)
			Score0 += points;
		else if (seat == 1)
			Score1 += points;
		else if (seat == 2)
			Score2 += points;
		else
			Score3 += points;
	}

	private int32 ScoreOf(int32 seat) => (seat == 0) ? Score0 : ((seat == 1) ? Score1 : ((seat == 2) ? Score2 : Score3));

	/// 1 for the lead (ties share it).
	private int32 Rank(int32 seat)
	{
		int32 r = 1;
		for (int32 h < Pieces.Hunters)
		{
			if (ScoreOf(h) > ScoreOf(seat))
				r++;
		}
		return r;
	}
}
