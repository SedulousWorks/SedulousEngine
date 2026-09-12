using System;

namespace Sedulous.Engine.Project;

/// The engine's own version, stamped into every saved project manifest.
///
/// Distinct from a type's data version: this says which ENGINE authored a project, so a
/// launcher or a migration can route on it.
///
/// Raptor derives these from the root CMakeLists' project(VERSION) so the number lives in
/// one place. Beef has no such injection, so THIS FILE is the one place: bump it here and
/// nothing else needs touching.
static class EngineVersion
{
	public const uint32 Major = 0;
	public const uint32 Minor = 1;
	public const uint32 Patch = 0;
	public const String String = "0.1.0";
}
