namespace Sedulous.Shell;

/// A cursor shape, requested by whatever is under the pointer.
enum CursorType : uint32
{
	case Default;
	case Text;
	case Wait;
	case Crosshair;
	case Progress;
	case ResizeNWSE;
	case ResizeNESW;
	case ResizeEW;
	case ResizeNS;
	case ResizeNW;
	case ResizeN;
	case ResizeNE;
	case ResizeE;
	case ResizeSE;
	case ResizeS;
	case ResizeSW;
	case ResizeW;
	case Move;
	case NotAllowed;
	case Pointer;
	case Count;
}
