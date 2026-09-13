using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Audio;

/// Registration for the audio settings sections.
///
/// A store LOADS through a registry: an unregistered section is captured verbatim rather than
/// abandoned, so without this call a reload looks like an empty mixer rather than a missing
/// registration.
[SerializableRegistry]
static class AudioSettings
{
}
