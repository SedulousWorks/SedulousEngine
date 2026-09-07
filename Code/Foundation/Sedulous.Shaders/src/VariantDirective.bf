namespace Sedulous.Shaders;

/// What a stage's `// variants:` line declared.
///
/// Present is separate from a zero mask: a stage that declares nothing and a stage with no
/// directive at all both canonicalize to None, but only the first said so on purpose, and
/// the cook reports them differently.
struct VariantDirective
{
	/// The OR of every flag the directive named.
	public ShaderFlags Mask = .None;
	/// Whether a `variants:` line was found at all.
	public bool Present = false;

	public this() {}
}
