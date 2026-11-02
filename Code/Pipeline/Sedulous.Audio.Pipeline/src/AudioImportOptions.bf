using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline;

/// What the import window offers for an audio file: its settings, reflected.
///
/// The streaming one is a FORCE rather than the whole story: the import computes a default from
/// the probed file, and this can only turn it on.
[Reflect(.NonStaticFields | .DefaultConstructor)]
class AudioImportOptions : ImportOptions
{
	[DisplayName("Stream"), Description("Decode on the fly at runtime, which anything over ten seconds or two megabytes does anyway")]
	public bool Stream = false;
	[DisplayName("Force mono"), Description("Downmix to one channel at cook, which is what a positioned sound wants")]
	public bool ForceMono = false;
	[DisplayName("Loop"), Description("Loop by default when played. A wave file's own loop points are detected regardless")]
	public bool Loop = false;
	[DisplayName("Trim trailing silence"), Description("Drop the silent tail at cook")]
	public bool TrimTrailingSilence = false;
	[DisplayName("Normalize"), Description("Peak normalise, leaving a decibel of headroom")]
	public bool Normalize = false;
}
