using System;

namespace Sedulous.Engine.Render;

/// A shared Environment Profile: the values a scene's environment takes while its source is
/// Profile. The loaded asset, so a script's change to it is in memory and seen by every scene
/// of the run that shares it.
class EnvironmentProfile
{
	/// The block's source and profile are unused here: a profile is the source.
	public EnvironmentSettings Values = .();
}

/// A shared Post Process Profile: the values a scene's post settings take while its source is
/// Profile.
class PostProcessProfile
{
	public PostProcessSettings Values = .();
}
