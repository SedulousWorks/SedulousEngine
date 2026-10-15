// Ball - the round. Four hunters, the player and three bots, each hunting another and hunted by a
// third, among guests who dress as they do. A hunter knows only its target's costume, and several
// guests wear each one.
//
// - The round: each hunter gets a costume (one of its six looks shown) and a target, the others in
//   a ring; `roundSeconds` later the most points wins.
// - A tag ("Tag" from Player.as, or a bot's, here): the nearest person within `tagReach` in front
//   of the tagger. The target: points, and the target respawns elsewhere in a new costume. Anyone
//   else: points lost, and the tagger's mask flares (its Flare light) for `revealSeconds`, there for
//   everyone to see.
// - The bots: guests (Guest.as) that this hunts for. A bot grows suspicious of its target when the
//   target stands out near it (sprinting, its mask flaring, not dancing when the music calls, still
//   walking when everyone gathers) and, sure enough, walks up to it and tags it. Now and then it
//   guesses instead: someone in its target's costume, often wrong, and its mask flares.
// - The game (Masquerade.as) hears what the player needs: "Hud" each quarter second (score,
//   seconds left, the target's costume, the hunter's rank), "Note" when something happens to the
//   player, "RoundOver" with the scores, and "RoundStart" when the host starts another.
//
// Over the network the host decides, and every peer's Ball follows its replicated state: each
// seat's owner (a player id, or -1 for a bot), costume and target, the scores, the time, which masks
// flare. A joining player takes a bot's seat (the host spawns them a hunter, `hunterPrefab`, where
// the bot stands; the bot wanders on as a plain guest) and gives it back on leaving. A client's
// input and tags come by RPC ("input", "tag"); notes go to one player ("note"). Entity active flags
// do not replicate, so every peer shows each hunter's look from the replicated costumes itself.
//
// Its globals carry its name where another script has the same: every behaviour compiles into one
// module here, and Guest.as and Orchestra.as name the clips and the cues too.

const int kHunters = 4;
const int kCostumes = 6;
const int kBallDanceClip = 3;
const int kBallWalkClip = 1;
const int kBallGather = 1;
const int kBallDanceCue = 2;

// Notes for the game (Masquerade.as): what happened, from the player's side.
const int kNoteGotTarget = 1;  // you tagged your target
const int kNoteMissed = 2;     // you tagged the wrong person: your mask flares
const int kNoteTagged = 3;     // your hunter tagged you: a new costume, somewhere else
const int kNoteFlare = 4;      // someone's mask flares: a hunter, there
const int kNoteWrongMap = 5;   // the host is at another map: you have left
const int kNoteFull = 6;       // every seat is a player's: you watch

class Ball
{
	Entity self;
	Scene@ scene;

	[null, "The player (seat 0)"] Entity player;
	[null, "Bot 1 (seat 1)"] Entity bot1;
	[null, "Bot 2 (seat 2)"] Entity bot2;
	[null, "Bot 3 (seat 3)"] Entity bot3;
	[null, "The crowd: a child per costume, in the costume order, its guests under it"] Entity crowd;
	[null, "The places guests go: its children (where the tagged reappear)"] Entity spots;
	[240.0, "Seconds in a round"] float roundSeconds;
	[1.6, "How near a tag reaches (m)"] float tagReach;
	[4.0, "Seconds a wrong tag shows the tagger"] float revealSeconds;
	[100, "Points for tagging your target"] int targetPoints;
	[25, "Points lost for tagging anyone else"] int missPoints;
	[1.7, "Moving faster than this (m/s) is sprinting"] float sprintSpeed;
	[16.0, "How far a bot watches for its target standing out (m)"] float watchRange;
	[20.0, "Shortest wait before a bot guesses (s)"] float guessMin;
	[45.0, "Longest wait before a bot guesses (s)"] float guessMax;
	[15.0, "A bot gives up walking up to someone after this (s)"] float approachGiveUp;
	[null, "Where players' hunters go (guests make way for its children)"] Entity players;
	["asset:Prefab", "The hunter the host spawns for a joining player"] Guid hunterPrefab;

	[0.0, "Seconds left in the round", replicated] float timeLeft;
	[false, "The round is over", replicated] bool over;
	[0, "Seat 0's score", replicated] int score0;
	[0, "Seat 1's score", replicated] int score1;
	[0, "Seat 2's score", replicated] int score2;
	[0, "Seat 3's score", replicated] int score3;
	[0, "Seat 0's owner: a player id (0 the host), or -1 for a bot", replicated] int owner0;
	[-1, "Seat 1's owner", replicated] int owner1;
	[-1, "Seat 2's owner", replicated] int owner2;
	[-1, "Seat 3's owner", replicated] int owner3;
	[0, "Seat 0's costume", replicated] int costume0;
	[0, "Seat 1's costume", replicated] int costume1;
	[0, "Seat 2's costume", replicated] int costume2;
	[0, "Seat 3's costume", replicated] int costume3;
	[1, "Seat 0's target seat", replicated] int target0;
	[2, "Seat 1's target seat", replicated] int target1;
	[3, "Seat 2's target seat", replicated] int target2;
	[0, "Seat 3's target seat", replicated] int target3;
	[0, "Which seats' masks flare (a bit a seat)", replicated] int flaring;

	private array<Entity> m_hunters;
	private array<Entity> m_bots;      // each seat's own body when no player has it (seat 0: the host's player)
	private array<int> m_dressed;      // the costume each seat's body shows now (-1 not yet)
	private array<Entity> m_known;     // players' hunters, as they announce themselves ("Hunter")
	private bool m_overTold = false;
	private array<array<Entity>> m_groups; // the guests in each costume
	private array<Entity> m_spots;
	private array<int> m_costume;   // each hunter's
	private array<int> m_target;    // each hunter's target seat
	private array<float> m_reveal;  // seconds its mask still flares
	private array<Float3> m_lastPos;
	private array<float> m_speed;   // measured over the last half second
	private array<float> m_suspicion; // a bot's, of its target
	private array<float> m_guessIn;
	private array<Entity> m_chasing; // whom a bot is walking up to (invalid: no one)
	private array<float> m_chaseFor;
	private array<float> m_orderIn; // until a bot's approach order is refreshed
	private float m_sample = 0.0f;
	private float m_hud = 0.0f;
	private int m_cue = 0;
	private Entity m_best;          // a tag's search: the nearest in reach so far
	private float m_bestDistance = 0.0f;

	void onStart()
	{
		m_hunters.insertLast(player);
		m_hunters.insertLast(bot1);
		m_hunters.insertLast(bot2);
		m_hunters.insertLast(bot3);
		for (int h = 0; h < kHunters; ++h)
		{
			m_bots.insertLast(m_hunters[h]);
			m_dressed.insertLast(-1);
		}
		// The network's half: the host hears input, tags, joins and leaves; a client its notes and
		// the host's map. Registered on every peer (a handler that never fires costs nothing).
		Net.OnNumber("input", NetNumberHandler(this.onNetInput));
		Net.On("tag", NetHandler(this.onNetTag));
		Net.OnNumber("note", NetNumberHandler(this.onNetNote));
		Net.OnText("map", NetTextHandler(this.onNetMap));
		Net.OnJoin(NetHandler(this.onJoined));
		Net.OnLeave(NetHandler(this.onLeft));
		m_groups.resize(kCostumes);
		int k = 0;
		Entity group = crowd.IsValid() ? crowd.GetFirstChild() : Entity::Invalid;
		while (group.IsValid() && k < kCostumes)
		{
			Entity guest = group.GetFirstChild();
			while (guest.IsValid())
			{
				m_groups[k].insertLast(guest);
				guest = guest.GetNextSibling();
			}
			++k;
			group = group.GetNextSibling();
		}
		Entity spot = spots.IsValid() ? spots.GetFirstChild() : Entity::Invalid;
		while (spot.IsValid())
		{
			m_spots.insertLast(spot);
			spot = spot.GetNextSibling();
		}
		m_costume.resize(kHunters);
		m_target.resize(kHunters);
		m_reveal.resize(kHunters);
		m_lastPos.resize(kHunters);
		m_speed.resize(kHunters);
		m_suspicion.resize(kHunters);
		m_guessIn.resize(kHunters);
		m_chasing.resize(kHunters);
		m_chaseFor.resize(kHunters);
		m_orderIn.resize(kHunters);
		if (!Net.IsClient)
			startRound();
	}

	private void startRound()
	{
		// The targets: a ring through the seats in a random order.
		array<int> order = {0, 1, 2, 3};
		for (int i = kHunters - 1; i > 0; --i)
		{
			int j = Random.IntRange(0, i);
			int t = order[i];
			order[i] = order[j];
			order[j] = t;
		}
		for (int i = 0; i < kHunters; ++i)
		{
			m_target[order[i]] = order[(i + 1) % kHunters];
			m_costume[i] = Random.IntRange(0, kCostumes - 1);
			m_reveal[i] = 0.0f;
			m_suspicion[i] = 0.0f;
			m_guessIn[i] = Random.Range(guessMin, guessMax);
			m_chasing[i] = Entity::Invalid;
			m_lastPos[i] = m_hunters[i].GetWorldPosition();
		}
		score0 = 0;
		score1 = 0;
		score2 = 0;
		score3 = 0;
		timeLeft = roundSeconds;
		over = false;
		publish();
	}

	// The host's seat state into the replicated properties every peer reads.
	private void publish()
	{
		costume0 = m_costume[0];
		costume1 = m_costume[1];
		costume2 = m_costume[2];
		costume3 = m_costume[3];
		target0 = m_target[0];
		target1 = m_target[1];
		target2 = m_target[2];
		target3 = m_target[3];
	}

	private int costumeOf(int seat)
	{
		return seat == 0 ? costume0 : (seat == 1 ? costume1 : (seat == 2 ? costume2 : costume3));
	}

	private int targetOf(int seat)
	{
		return seat == 0 ? target0 : (seat == 1 ? target1 : (seat == 2 ? target2 : target3));
	}

	private int ownerOf(int seat)
	{
		return seat == 0 ? owner0 : (seat == 1 ? owner1 : (seat == 2 ? owner2 : owner3));
	}

	private void setOwner(int seat, int owner)
	{
		if (seat == 0) owner0 = owner;
		else if (seat == 1) owner1 = owner;
		else if (seat == 2) owner2 = owner;
		else owner3 = owner;
	}

	// The seat a player holds, or -1.
	private int seatOfPlayer(int who)
	{
		for (int h = 0; h < kHunters; ++h)
		{
			if (ownerOf(h) == who)
				return h;
		}
		return -1;
	}

	// The player this peer plays as: 0 the host (and offline), else the id the host gave it.
	private int localPlayer()
	{
		int me = Net.LocalPlayer;
		return me < 0 ? 0 : me;
	}

	// Every peer: each seat's body (its bot, or the hunter of the player who holds it), dressed in
	// the seat's replicated costume.
	private void follow()
	{
		for (int h = 0; h < kHunters; ++h)
		{
			Entity body = m_bots[h];
			int owner = ownerOf(h);
			if (owner > 0)
			{
				body = Entity::Invalid;
				for (uint k = 0; k < m_known.length(); ++k)
				{
					if (!m_known[k].IsValid())
						continue;
					NetworkComponent@ net = NetworkComponent::of(m_known[k]);
					if (net !is null && int(net.Owner) == owner)
						body = m_known[k];
				}
				if (!body.IsValid())
					continue; // its hunter has not reached this peer yet
			}
			if (body != m_hunters[h])
			{
				m_hunters[h] = body;
				m_dressed[h] = -1;
			}
			if (m_dressed[h] != costumeOf(h))
				dress(h, costumeOf(h));
		}
	}

	// A player's hunter announcing itself (Player.as, on every peer), so the seats can find it.
	void onHunter(Entity hunter)
	{
		m_known.insertLast(hunter);
	}

	void onCue(int cue) { m_cue = cue; }

	// The host: another round in the same scene (Masquerade.as, hosting), the players kept.
	void onRestart(int unused)
	{
		if (!Net.IsClient)
			startRound();
	}

	// A tag by a player (the host's own Player.as sends its player id; a client's comes by RPC).
	void onTag(int who)
	{
		int seat = seatOfPlayer(who);
		if (Net.IsClient || over || seat < 0 || seat >= kHunters)
			return;
		Entity tagger = m_hunters[seat];
		Float3 p = tagger.GetWorldPosition();
		Float3 ahead = RotateVector(tagger.GetWorldRotation(), Float3(0.0f, 0.0f, 1.0f));
		m_best = Entity::Invalid;
		m_bestDistance = tagReach;
		for (int c = 0; c < kCostumes; ++c)
		{
			for (uint g = 0; g < m_groups[c].length(); ++g)
				consider(m_groups[c][g], p, ahead);
		}
		for (int h = 0; h < kHunters; ++h)
		{
			if (h != seat)
				consider(m_hunters[h], p, ahead);
		}
		if (m_best.IsValid())
			resolve(seat, m_best);
	}

	// Someone in reach and in front (or right beside), nearer than the best so far (m_best).
	private void consider(Entity person, Float3 p, Float3 ahead)
	{
		Float3 q = person.GetWorldPosition();
		float dx = q.X - p.X;
		float dz = q.Z - p.Z;
		float distance = Sqrt(dx * dx + dz * dz);
		if (distance >= m_bestDistance)
			return;
		if (distance > 0.7f && (dx * ahead.X + dz * ahead.Z) / distance < 0.3f)
			return; // behind or well to the side
		m_best = person;
		m_bestDistance = distance;
	}

	private void resolve(int seat, Entity tagged)
	{
		int victim = seatOf(tagged);
		if (victim == m_target[seat])
		{
			addScore(seat, targetPoints);
			respawn(victim);
			note(seat, kNoteGotTarget);
			note(victim, kNoteTagged);
			return;
		}
		addScore(seat, -missPoints);
		m_reveal[seat] = revealSeconds;
		note(seat, kNoteMissed);
		for (int h = 0; h < kHunters; ++h) // everyone else sees the flare
		{
			if (h != seat)
				note(h, kNoteFlare);
		}
	}

	// A note to the player at a seat: the host's own as an event here, a client's by RPC, a bot's
	// nowhere.
	private void note(int seat, int what)
	{
		int owner = ownerOf(seat);
		if (owner == 0)
			scene.Scripts.Emit("Note", what);
		else if (owner > 0)
			Net.RpcNumberTo(owner, "note", double(what));
	}

	private void respawn(int seat)
	{
		// Somewhere well away from whoever hunts it, in a costume it was not wearing.
		Entity hunter = m_hunters[hunterOf(seat)];
		Float3 at = m_hunters[seat].GetWorldPosition();
		for (int tries = 0; tries < 12 && m_spots.length() > 0; ++tries)
		{
			Float3 candidate = m_spots[Random.IntRange(0, int(m_spots.length()) - 1)].GetWorldPosition();
			at = candidate;
			if (flat(candidate, hunter.GetWorldPosition()) > 14.0f)
				break;
		}
		NavAgentComponent::of(m_hunters[seat]).Warp(at);
		m_costume[seat] = (m_costume[seat] + Random.IntRange(1, kCostumes - 1)) % kCostumes;
		publish(); // every peer dresses it (follow)
		m_reveal[seat] = 0.0f;
		m_lastPos[seat] = at;
		int hunterSeat = hunterOf(seat);
		m_suspicion[hunterSeat] = 0.0f;
		stopChase(hunterSeat);
		if (seat != 0)
			stopChase(seat);
	}

	// A hunter's costume: the one look of its six shown (on this peer: active flags do not replicate).
	private void dress(int seat, int costume)
	{
		m_dressed[seat] = costume;
		int k = 0;
		Entity child = m_hunters[seat].GetFirstChild();
		while (child.IsValid())
		{
			if (InstanceMemberComponent::of(child) !is null)
			{
				child.SetActive(k == costume);
				++k;
			}
			child = child.GetNextSibling();
		}
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		follow();
		flares(dt);
		tell(dt);
		if (Net.IsClient || over)
			return;
		timeLeft -= dt;
		if (timeLeft <= 0.0f)
		{
			timeLeft = 0.0f;
			over = true; // every peer tells its game (tell)
			return;
		}
		m_sample -= dt;
		if (m_sample <= 0.0f)
		{
			m_sample = 0.5f;
			for (int h = 0; h < kHunters; ++h)
			{
				Float3 now = m_hunters[h].GetWorldPosition();
				m_speed[h] = flat(now, m_lastPos[h]) / 0.5f;
				m_lastPos[h] = now;
			}
		}
		for (int b = 1; b < kHunters; ++b)
		{
			if (ownerOf(b) < 0) // a seat a player holds hunts for itself
				hunt(b, dt);
		}
		int mask = 0;
		for (int h = 0; h < kHunters; ++h)
		{
			if (m_reveal[h] > 0.0f)
			{
				m_reveal[h] = Max(m_reveal[h] - dt, 0.0f);
				mask |= 1 << h;
			}
		}
		flaring = mask;
	}

	// Every peer: the game hears this peer's player's seat (the HUD four times a second) and the
	// round's end, from the replicated state.
	private void tell(float d)
	{
		int seat = seatOfPlayer(localPlayer());
		m_hud -= d;
		if (m_hud <= 0.0f && seat >= 0)
		{
			m_hud = 0.25f;
			scene.Scripts.Emit("Hud", Float4(float(scoreOf(seat)), timeLeft, float(costumeOf(targetOf(seat))),
			                                 float(rank(seat))));
		}
		if (!over && m_overTold)
		{
			m_overTold = false;
			scene.Scripts.Emit("RoundStart", 0); // a new round: the host started another
		}
		if (over && !m_overTold)
		{
			m_overTold = true;
			// The player's own score first, then the others' in seat order.
			array<float> others;
			for (int h = 0; h < kHunters; ++h)
			{
				if (h != seat)
					others.insertLast(float(scoreOf(h)));
			}
			scene.Scripts.Emit("RoundOver", Float4(float(seat >= 0 ? scoreOf(seat) : 0), others[0], others[1],
			                                       others[2]));
		}
	}

	// A flaring mask: its light pulses while the seat's flare bit is set, on every peer.
	private float m_pulse = 0.0f;
	private void flares(float d)
	{
		m_pulse += d;
		for (int h = 0; h < kHunters && h < int(m_hunters.length()); ++h)
		{
			if (!m_hunters[h].IsValid())
				continue;
			Entity flare = m_hunters[h].FindChildByName("Flare");
			if (!flare.IsValid())
				continue;
			LightComponent@ light = LightComponent::of(flare);
			if (light !is null)
			{
				bool on = (flaring & (1 << h)) != 0;
				light.Intensity = on ? 6.0f + 4.0f * Sin(m_pulse * 12.0f) : 0.0f;
			}
		}
	}

	// ---- the network ----

	// The host: a client's stick, sprint and dance (Player.as packs them in one number), to the
	// hunter that player holds.
	void onNetInput(int sender, double packed)
	{
		int seat = seatOfPlayer(sender);
		if (Net.IsClient || seat < 0 || !m_hunters[seat].IsValid())
			return;
		int v = int(packed);
		int flags = v % 4;
		v /= 4;
		float z = float(v % 201) / 100.0f - 1.0f;
		float x = float(v / 201) / 100.0f - 1.0f;
		m_hunters[seat].Send("Input", Float4(x, z, (flags & 1) != 0 ? 1.0f : 0.0f, (flags & 2) != 0 ? 1.0f : 0.0f));
	}

	void onNetTag(int sender)
	{
		if (!Net.IsClient)
			onTag(sender);
	}

	// A client: a note for its player, from the host.
	void onNetNote(int sender, double what)
	{
		if (Net.IsClient)
			scene.Scripts.Emit("Note", int(what));
	}

	// A client: the host's map, on joining. At another map, it leaves and says why.
	void onNetMap(int sender, const string &in name)
	{
		if (Net.IsClient && name != scene.Name)
		{
			Net.Disconnect();
			scene.Scripts.Emit("Note", kNoteWrongMap);
		}
	}

	// The host: a player has joined. They take a bot's seat: a hunter spawned for them where the
	// bot stands, in its costume; the bot wanders on as a plain guest. No bot seat left: they watch.
	void onJoined(int who)
	{
		if (Net.IsClient)
			return;
		Net.RpcTextTo(who, "map", scene.Name);
		for (int h = 1; h < kHunters; ++h)
		{
			if (ownerOf(h) >= 0)
				continue;
			stopChase(h);
			Entity hunter = Net.SpawnFor(who, hunterPrefab, m_bots[h].GetWorldPosition());
			if (!hunter.IsValid())
				return;
			if (players.IsValid())
				hunter.SetParent(players, true); // guests make way for it
			m_known.insertLast(hunter);
			setOwner(h, who);
			return;
		}
		Net.RpcNumberTo(who, "note", double(kNoteFull));
	}

	// The host: a player has left. Their seat goes back to its bot, and their hunter goes.
	void onLeft(int who)
	{
		if (Net.IsClient)
			return;
		int seat = seatOfPlayer(who);
		if (seat <= 0)
			return;
		Entity hunter = m_hunters[seat];
		setOwner(seat, -1);
		m_hunters[seat] = m_bots[seat];
		m_dressed[seat] = -1;
		m_suspicion[seat] = 0.0f;
		m_guessIn[seat] = Random.Range(guessMin, guessMax);
		if (hunter.IsValid() && hunter != m_bots[seat])
			hunter.Destroy();
	}

	// One bot's hunt: watch its target for standing out, walk up to it when sure, or guess.
	private void hunt(int b, float d)
	{
		int t = m_target[b];
		Entity bot = m_hunters[b];
		Entity target = m_hunters[t];
		if (m_chasing[b].IsValid())
		{
			m_chaseFor[b] += d;
			float distance = flat(bot.GetWorldPosition(), m_chasing[b].GetWorldPosition());
			if (distance <= tagReach)
			{
				Entity tagged = m_chasing[b];
				stopChase(b);
				resolve(b, tagged);
				return;
			}
			if (m_chaseFor[b] > approachGiveUp)
			{
				stopChase(b);
				return;
			}
			m_orderIn[b] -= d;
			if (m_orderIn[b] <= 0.0f)
			{
				m_orderIn[b] = 0.5f;
				bot.Send("Approach", m_chasing[b].GetWorldPosition());
			}
			return;
		}
		if (flat(bot.GetWorldPosition(), target.GetWorldPosition()) < watchRange)
			m_suspicion[b] += standingOut(t) * d;
		m_suspicion[b] = Max(m_suspicion[b] - 0.03f * d, 0.0f);
		if (m_suspicion[b] >= 1.0f)
		{
			chase(b, target);
			return;
		}
		m_guessIn[b] -= d;
		if (m_guessIn[b] <= 0.0f)
		{
			m_guessIn[b] = Random.Range(guessMin, guessMax);
			Entity guess = someoneDressedAs(m_costume[t], b);
			if (guess.IsValid())
				chase(b, guess);
		}
	}

	// How much a hunter stands out right now (suspicion a second): sprinting, its mask flaring,
	// not dancing when the music calls, walking when everyone gathers.
	private float standingOut(int seat)
	{
		float amount = 0.0f;
		if (m_speed[seat] > sprintSpeed)
			amount += 0.8f;
		if (m_reveal[seat] > 0.0f)
			amount += 2.0f;
		int clip = clipOf(seat);
		if (m_cue == kBallDanceCue && clip != kBallDanceClip)
			amount += 0.4f;
		else if (m_cue == kBallGather && clip == kBallWalkClip)
			amount += 0.15f;
		return amount;
	}

	// A guess: someone near the bot in the costume, a guest or a hunter (not the bot itself).
	private Entity someoneDressedAs(int costume, int b)
	{
		Float3 p = m_hunters[b].GetWorldPosition();
		array<Entity> near;
		for (uint g = 0; g < m_groups[costume].length(); ++g)
		{
			if (flat(p, m_groups[costume][g].GetWorldPosition()) < watchRange)
				near.insertLast(m_groups[costume][g]);
		}
		for (int h = 0; h < kHunters; ++h)
		{
			if (h != b && m_costume[h] == costume && flat(p, m_hunters[h].GetWorldPosition()) < watchRange)
				near.insertLast(m_hunters[h]);
		}
		return near.length() > 0 ? near[Random.IntRange(0, int(near.length()) - 1)] : Entity::Invalid;
	}

	private void chase(int b, Entity person)
	{
		m_chasing[b] = person;
		m_chaseFor[b] = 0.0f;
		m_orderIn[b] = 0.0f;
	}

	private void stopChase(int b)
	{
		if (b <= 0 || !m_chasing[b].IsValid())
			return;
		m_chasing[b] = Entity::Invalid;
		m_hunters[b].Send("Resume", 0);
	}

	// The clip the hunter's shown look plays.
	private int clipOf(int seat)
	{
		Entity child = m_hunters[seat].GetFirstChild();
		while (child.IsValid())
		{
			if (child.IsActive())
			{
				InstanceMemberComponent@ look = InstanceMemberComponent::of(child);
				if (look !is null)
					return int(look.Clip);
			}
			child = child.GetNextSibling();
		}
		return 0;
	}

	private int seatOf(Entity person)
	{
		for (int h = 0; h < kHunters; ++h)
		{
			if (m_hunters[h] == person)
				return h;
		}
		return -1;
	}

	private int hunterOf(int seat)
	{
		for (int h = 0; h < kHunters; ++h)
		{
			if (m_target[h] == seat)
				return h;
		}
		return seat;
	}

	private void addScore(int seat, int points)
	{
		if (seat == 0) score0 += points;
		else if (seat == 1) score1 += points;
		else if (seat == 2) score2 += points;
		else score3 += points;
	}

	private int scoreOf(int seat)
	{
		return seat == 0 ? score0 : (seat == 1 ? score1 : (seat == 2 ? score2 : score3));
	}

	// 1 for the lead (ties share it).
	private int rank(int seat)
	{
		int r = 1;
		for (int h = 0; h < kHunters; ++h)
		{
			if (scoreOf(h) > scoreOf(seat))
				++r;
		}
		return r;
	}

	private float flat(Float3 a, Float3 b)
	{
		float dx = a.X - b.X;
		float dz = a.Z - b.Z;
		return Sqrt(dx * dx + dz * dz);
	}
}
