namespace Sedulous.Editor.Scene;

/// What a row in the particle effect tree stands for.
enum ParticleNodeKind : uint8
{
	Effect,
	System,
	Emitter,
	InitializersFolder,
	BehaviorsFolder,
	Initializer,
	Behavior
}
