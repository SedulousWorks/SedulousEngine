// Footsteps - the thief's steps: one each stride (the clips' strides, blender/thief.py), the sound
// of what the foot lands on (the physical material under it, PhysicsHit.Material) and a Noise for
// whoever listens (the guards, P2): a Float4 of where it was and how loud, 0 to 1. Sneaking is
// silent; a run is louder than a walk, and gravel louder than boards, grass softer.
class Footsteps
{
	Entity self;
	Scene@ scene;

	["asset:PhysicalMaterial", "Boards (Surfaces/Wood)"] Guid wood;
	["asset:PhysicalMaterial", "Flags (Surfaces/Stone)"] Guid stone;
	["asset:PhysicalMaterial", "Surfaces/Gravel"] Guid gravel;
	["asset:PhysicalMaterial", "Surfaces/Grass"] Guid grass;
	[0.6, "Metres a step, sneaking"] float sneakStride;
	[0.8, "Metres a step, walking"] float walkStride;
	[1.35, "Metres a step, running"] float runStride;
	[3.0, "Faster than this (m/s) is a run"] float runSpeed;
	[0.4, "How loud a walking step is (0..1, on boards)"] float walkNoise;
	[1.0, "How loud a running step is (0..1, on boards)"] float runNoise;
	[0.9, "From the thief's centre down to the floor (m)"] float footDrop;

	private float m_travel = 0.0f;
	private int m_take = 0;
	private string m_surface = ""; // the last step's, and how many: what a playtest reads
	private int m_steps = 0;
	private int m_heard = 0; // steps whose sound started

	void onUpdate(float dt)
	{
		Float3 v = CharacterComponent::of(self).Velocity;
		float speed = Sqrt(v.X * v.X + v.Z * v.Z);
		if (speed < 0.2f)
		{
			m_travel = 0.0f; // stood still: the next step is a whole stride away
			return;
		}
		bool sneaking = Input.IsDown("Sneak");
		bool running = !sneaking && speed > runSpeed;
		float stride = sneaking ? sneakStride : (running ? runStride : walkStride);
		m_travel += speed * dt;
		if (m_travel < stride)
		{
			return;
		}
		m_travel -= stride;
		if (!sneaking)
		{
			step(running ? runNoise : walkNoise);
		}
	}

	// A step: what is underfoot, its sound at the foot, and the noise it makes.
	private void step(float noise)
	{
		Float3 at = self.GetWorldPosition();
		PhysicsHit hit = scene.Physics.RayCast(at, Float3(0.0f, -1.0f, 0.0f), footDrop + 0.3f);
		if (!hit.Hit)
		{
			return; // in the air
		}
		Guid under = hit.Material;
		string surface = "Wood";
		float loudness = 1.0f;
		if (!stone.IsNil && under == stone) { surface = "Stone"; loudness = 0.9f; }
		else if (!gravel.IsNil && under == gravel) { surface = "Gravel"; loudness = 1.4f; }
		else if (!grass.IsNil && under == grass) { surface = "Grass"; loudness = 0.4f; }
		m_take = m_take % 3 + 1;
		m_surface = surface;
		m_steps++;
		Float3 foot = hit.Position;
		if (Audio.PlayOneShot3DPath("Audio/Step" + surface + m_take, foot).IsValid)
		{
			m_heard++;
		}
		float level = noise * loudness;
		scene.Scripts.Emit("Noise", Float4(foot.X, foot.Y, foot.Z, Min(level, 1.0f)));
	}
}
