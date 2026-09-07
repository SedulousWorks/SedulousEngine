using Sedulous.Core;

namespace Sedulous.RHI;

/// The colour attachments of one render pass, held INLINE.
///
/// Inline rather than a heap list because a pass descriptor is built per pass, often per
/// frame, and the bound is small and fixed.
typealias ColorAttachmentList = FixedList<ColorAttachment, const RhiLimits.MaxColorAttachments>;
