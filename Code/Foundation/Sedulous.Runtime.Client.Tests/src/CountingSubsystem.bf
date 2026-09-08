using Sedulous.Runtime;

namespace Sedulous.Runtime.Client.Tests;

/// Counts the frame phases the host drives into the context.
///
/// No fixed update: there is no context level fixed lane. The host's accumulator drives
/// ONLY the application's OnFixedUpdate hook, which the test applications count, and fixed
/// rate engine work belongs to a scene.
class CountingSubsystem : Subsystem
{
	public int Begin = 0;
	public int Updates = 0;
	public int Post = 0;
	public int End = 0;
	public int Inits = 0;
	public int Shutdowns = 0;

	public override void BeginFrame(float deltaTime) { Begin++; }
	public override void Update(float deltaTime) { Updates++; }
	public override void PostUpdate(float deltaTime) { Post++; }
	public override void EndFrame() { End++; }

	protected override void OnInit() { Inits++; }
	protected override void OnShutdown() { Shutdowns++; }
}
