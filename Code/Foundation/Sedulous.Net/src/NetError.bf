namespace Sedulous.Net;

using System;
using System.Net;

public enum NetError
{
	case ConnectionRefused;
	case ConnectionReset;
	case ConnectionClosed;
	case ConnectionAborted;
	case TimedOut;
	case AddressInUse;
	case AddressNotAvailable;
	case HostUnreachable;
	case NetworkUnreachable;
	case NetworkDown;
	case WouldBlock;
	case InvalidArgument;
	case NotConnected;
	case AlreadyConnected;
	case DnsResolutionFailed;
	case SocketError;
	case BufferOverflow;
	case BufferUnderflow;
	case ParseError;
	case InvalidState;
	case NotSupported;
	case ProtocolError;

	public static NetError FromSocketError(Socket.SocketError err)
	{
		switch (err)
		{
		case .ConnectionRefused:   return .ConnectionRefused;
		case .ConnectionReset:     return .ConnectionReset;
		case .ConnectionClosed:    return .ConnectionClosed;
		case .ConnectionAborted:   return .ConnectionAborted;
		case .TimedOut:            return .TimedOut;
		case .AddressInUse:        return .AddressInUse;
		case .AddressUnavailable:  return .AddressNotAvailable;
		case .HostUnreachable:     return .HostUnreachable;
		case .NetworkUnreachable:  return .NetworkUnreachable;
		case .NetworkDown:         return .NetworkDown;
		case .WouldBlock:          return .WouldBlock;
		case .InvalidArgument:     return .InvalidArgument;
		case .NotConnected:        return .NotConnected;
		case .AlreadyConnected:    return .AlreadyConnected;
		default:                   return .SocketError;
		}
	}

	public void GetDescription(String outStr)
	{
		switch (this)
		{
		case .ConnectionRefused:   outStr.Append("Connection refused");
		case .ConnectionReset:     outStr.Append("Connection reset by peer");
		case .ConnectionClosed:    outStr.Append("Connection closed");
		case .ConnectionAborted:   outStr.Append("Connection aborted");
		case .TimedOut:            outStr.Append("Operation timed out");
		case .AddressInUse:        outStr.Append("Address already in use");
		case .AddressNotAvailable: outStr.Append("Address not available");
		case .HostUnreachable:     outStr.Append("Host unreachable");
		case .NetworkUnreachable:  outStr.Append("Network unreachable");
		case .NetworkDown:         outStr.Append("Network is down");
		case .WouldBlock:          outStr.Append("Operation would block");
		case .InvalidArgument:     outStr.Append("Invalid argument");
		case .NotConnected:        outStr.Append("Not connected");
		case .AlreadyConnected:    outStr.Append("Already connected");
		case .DnsResolutionFailed: outStr.Append("DNS resolution failed");
		case .SocketError:         outStr.Append("Socket error");
		case .BufferOverflow:      outStr.Append("Buffer overflow");
		case .BufferUnderflow:     outStr.Append("Buffer underflow");
		case .ParseError:          outStr.Append("Parse error");
		case .InvalidState:        outStr.Append("Invalid state");
		case .NotSupported:        outStr.Append("Operation not supported");
		case .ProtocolError:       outStr.Append("Protocol error");
		}
	}
}
