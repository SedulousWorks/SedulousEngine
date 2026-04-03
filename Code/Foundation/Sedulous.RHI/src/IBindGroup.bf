namespace Sedulous.RHI;

using System.Collections;
using System;

/// Defines the layout of resource bindings in a bind group.
/// Each entry describes one binding slot (type, visibility, count).
/// Bind groups created from this layout must provide matching entries.
/// Destroyed via IDevice.DestroyBindGroupLayout().
///
/// Example:
/// ```
/// BindGroupLayoutEntry[?] entries = .(
///     .() { Binding = 0, Type = .UniformBuffer, Visibility = .Vertex | .Fragment },
///     .() { Binding = 1, Type = .Texture, Visibility = .Fragment },
///     .() { Binding = 2, Type = .Sampler, Visibility = .Fragment }
/// );
/// var layout = device.CreateBindGroupLayout(.() { Entries = entries }).Value;
/// defer device.DestroyBindGroupLayout(ref layout);
/// ```
interface IBindGroupLayout
{
	/// The layout entries, in order. Used for positional matching with bind group entries.
	List<BindGroupLayoutEntry> Entries { get; }
}

/// A group of resource bindings matching a bind group layout.
/// Entries must be provided in the same order as the layout entries.
/// Destroyed via IDevice.DestroyBindGroup().
///
/// Example:
/// ```
/// BindGroupEntry[?] entries = .(
///     .() { Buffer = .() { Buffer = uniformBuffer, Size = sizeof(Uniforms) } },
///     .() { TextureView = myTextureView },
///     .() { Sampler = mySampler }
/// );
/// var bindGroup = device.CreateBindGroup(.() {
///     Layout = layout,
///     Entries = entries
/// }).Value;
/// defer device.DestroyBindGroup(ref bindGroup);
///
/// // In a render pass:
/// rp.SetBindGroup(0, bindGroup);
/// ```
///
/// For bindless descriptor arrays, create a layout with a bindless entry type
/// (e.g. `.BindlessTextures`) and update entries dynamically:
/// ```
/// bindGroup.UpdateBindless(.(.() { ArrayIndex = 5, TextureView = newView }));
/// ```
interface IBindGroup
{
	/// The layout this bind group conforms to.
	IBindGroupLayout Layout { get; }

	/// Updates bindless descriptor array entries after creation.
	/// Only valid for bind groups whose layout contains bindless entries.
	void UpdateBindless(Span<BindlessUpdateEntry> entries);
}
