using System;
/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
	 claim that you wrote the original software. If you use this software
	 in a product, an acknowledgment in the product documentation would be
	 appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/**
 * # CategoryAtomic
 *
 * Atomic operations.
 *
 * IMPORTANT: If you are not an expert in concurrent lockless programming, you
 * should not be using any functions in this file. You should be protecting
 * your data structures with full mutexes instead.
 *
 * ***Seriously, here be dragons!***
 *
 * You can find out a little more about lockless programming and the subtle
 * issues that can arise here:
 * https://learn.microsoft.com/en-us/windows/win32/dxtecharts/lockless-programming
 *
 * There's also lots of good information here:
 *
 * - https://www.1024cores.net/home/lock-free-algorithms
 * - https://preshing.com/
 *
 * These operations may or may not actually be implemented using processor
 * specific atomic operations. When possible they are implemented as true
 * processor specific atomic operations. When that is not possible the are
 * implemented using locks that *do* use the available atomic operations.
 *
 * All of the atomic operations that modify memory are full memory barriers.
 */

namespace SDL3;

/**
 * An atomic spinlock.
 *
 * The atomic locks are efficient spinlocks using CPU instructions, but are
 * vulnerable to starvation and can spin forever if a thread holding a lock
 * has been terminated. For this reason you should minimize the code executed
 * inside an atomic lock and never do expensive things like API or system
 * calls while holding them.
 *
 * They are also vulnerable to starvation if the thread holding the lock is
 * lower priority than other threads and doesn't get scheduled. In general you
 * should use mutexes instead, since they have better performance and
 * contention behavior.
 *
 * The atomic locks are not safe to lock recursively.
 *
 * Porting Note: The spin lock functions and type are required and can not be
 * emulated because they are used in the atomic emulation code.
 */
public typealias SDL_SpinLock = int32;

public static //extension SDL3
{

/**
 * Try to lock a spin lock by setting it to a non-zero value.
 *
 * ***Please note that spinlocks are dangerous if you don't know what you're
 * doing. Please be careful using any sort of spinlock!***
 *
 * \param lock a pointer to a lock variable.
 * \returns true if the lock succeeded, false if the lock is already held.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_LockSpinlock
 * \sa SDL_UnlockSpinlock
 */
	[CLink] public static extern bool SDL_TryLockSpinlock(SDL_SpinLock* lock);

/**
 * Lock a spin lock by setting it to a non-zero value.
 *
 * ***Please note that spinlocks are dangerous if you don't know what you're
 * doing. Please be careful using any sort of spinlock!***
 *
 * \param lock a pointer to a lock variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_TryLockSpinlock
 * \sa SDL_UnlockSpinlock
 */
	[CLink] public static extern void SDL_LockSpinlock(SDL_SpinLock* lock);

/**
 * Unlock a spin lock by setting it to 0.
 *
 * Always returns immediately.
 *
 * ***Please note that spinlocks are dangerous if you don't know what you're
 * doing. Please be careful using any sort of spinlock!***
 *
 * \param lock a pointer to a lock variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_LockSpinlock
 * \sa SDL_TryLockSpinlock
 */
	[CLink] public static extern void SDL_UnlockSpinlock(SDL_SpinLock* lock);

/**
 * Insert a memory release barrier (function version).
 *
 * Please refer to SDL_MemoryBarrierRelease for details. This is a function
 * version, which might be useful if you need to use this functionality from a
 * scripting language, etc. Also, some of the macro versions call this
 * function behind the scenes, where more heavy lifting can happen inside of
 * SDL. Generally, though, an app written in C/C++/etc should use the macro
 * version, as it will be more efficient.
 *
 * \threadsafety Obviously this function is safe to use from any thread at any
 *               time, but if you find yourself needing this, you are probably
 *               dealing with some very sensitive code; be careful!
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_MemoryBarrierRelease
 */
	[CLink] public static extern void SDL_MemoryBarrierReleaseFunction();

/**
 * Insert a memory acquire barrier (function version).
 *
 * Please refer to SDL_MemoryBarrierRelease for details. This is a function
 * version, which might be useful if you need to use this functionality from a
 * scripting language, etc. Also, some of the macro versions call this
 * function behind the scenes, where more heavy lifting can happen inside of
 * SDL. Generally, though, an app written in C/C++/etc should use the macro
 * version, as it will be more efficient.
 *
 * \threadsafety Obviously this function is safe to use from any thread at any
 *               time, but if you find yourself needing this, you are probably
 *               dealing with some very sensitive code; be careful!
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_MemoryBarrierAcquire
 */
	[CLink] public static extern void SDL_MemoryBarrierAcquireFunction();

/**
 * A type representing an atomic integer value.
 *
 * This can be used to manage a value that is synchronized across multiple
 * CPUs without a race condition; when an app sets a value with
 * SDL_SetAtomicInt all other threads, regardless of the CPU it is running on,
 * will see that value when retrieved with SDL_GetAtomicInt, regardless of CPU
 * caches, etc.
 *
 * This is also useful for atomic compare-and-swap operations: a thread can
 * change the value as long as its current value matches expectations. When
 * done in a loop, one can guarantee data consistency across threads without a
 * lock (but the usual warnings apply: if you don't know what you're doing, or
 * you don't do it carefully, you can confidently cause any number of
 * disasters with this, so in most cases, you _should_ use a mutex instead of
 * this!).
 *
 * This is a struct so people don't accidentally use numeric operations on it
 * directly. You have to use SDL atomic functions.
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_CompareAndSwapAtomicInt
 * \sa SDL_GetAtomicInt
 * \sa SDL_SetAtomicInt
 * \sa SDL_AddAtomicInt
 */
	[CRepr] public struct SDL_AtomicInt { public int32 value; }

/**
 * Set an atomic variable to a new value if it is currently an old value.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicInt variable to be modified.
 * \param oldval the old value.
 * \param newval the new value.
 * \returns true if the atomic variable was set, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetAtomicInt
 * \sa SDL_SetAtomicInt
 */
	[CLink] public static extern bool SDL_CompareAndSwapAtomicInt(SDL_AtomicInt* a, int32 oldval, int32 newval);

/**
 * Set an atomic variable to a value.
 *
 * This function also acts as a full memory barrier.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicInt variable to be modified.
 * \param v the desired value.
 * \returns the previous value of the atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetAtomicInt
 */
	[CLink] public static extern int32 SDL_SetAtomicInt(SDL_AtomicInt* a, int32 v);

/**
 * Get the value of an atomic variable.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicInt variable.
 * \returns the current value of an atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetAtomicInt
 */
	[CLink] public static extern int32 SDL_GetAtomicInt(SDL_AtomicInt* a);

/**
 * Add to an atomic variable.
 *
 * This function also acts as a full memory barrier.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicInt variable to be modified.
 * \param v the desired value to add.
 * \returns the previous value of the atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_AtomicDecRef
 * \sa SDL_AtomicIncRef
 */
	[CLink] public static extern int32 SDL_AddAtomicInt(SDL_AtomicInt* a, int32 v);

/**
 * Increment an atomic variable used as a reference count.
 *
 * ***Note: If you don't know what this macro is for, you shouldn't use it!***
 *
 * \param a a pointer to an SDL_AtomicInt to increment.
 * \returns the previous value of the atomic variable.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_AtomicDecRef
 */
	public static int32 SDL_AtomicIncRef(SDL_AtomicInt* a) => SDL_AddAtomicInt(a, 1);

/**
 * Decrement an atomic variable used as a reference count.
 *
 * ***Note: If you don't know what this macro is for, you shouldn't use it!***
 *
 * \param a a pointer to an SDL_AtomicInt to decrement.
 * \returns true if the variable reached zero after decrementing, false
 *          otherwise.
 *
 * \threadsafety It is safe to call this macro from any thread.
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_AtomicIncRef
 */
	public static bool SDL_AtomicDecRef(SDL_AtomicInt* a) => (SDL_AddAtomicInt(a, -1) == 1);

/**
 * A type representing an atomic unsigned 32-bit value.
 *
 * This can be used to manage a value that is synchronized across multiple
 * CPUs without a race condition; when an app sets a value with
 * SDL_SetAtomicU32 all other threads, regardless of the CPU it is running on,
 * will see that value when retrieved with SDL_GetAtomicU32, regardless of CPU
 * caches, etc.
 *
 * This is also useful for atomic compare-and-swap operations: a thread can
 * change the value as long as its current value matches expectations. When
 * done in a loop, one can guarantee data consistency across threads without a
 * lock (but the usual warnings apply: if you don't know what you're doing, or
 * you don't do it carefully, you can confidently cause any number of
 * disasters with this, so in most cases, you _should_ use a mutex instead of
 * this!).
 *
 * This is a struct so people don't accidentally use numeric operations on it
 * directly. You have to use SDL atomic functions.
 *
 * \since This struct is available since SDL 3.2.0.
 *
 * \sa SDL_CompareAndSwapAtomicU32
 * \sa SDL_GetAtomicU32
 * \sa SDL_SetAtomicU32
 */
	[CRepr] public struct SDL_AtomicU32 { public uint32 value; }

/**
 * Set an atomic variable to a new value if it is currently an old value.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicU32 variable to be modified.
 * \param oldval the old value.
 * \param newval the new value.
 * \returns true if the atomic variable was set, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetAtomicU32
 * \sa SDL_SetAtomicU32
 */
	[CLink] public static extern bool SDL_CompareAndSwapAtomicU32(SDL_AtomicU32* a, uint32 oldval, uint32 newval);

/**
 * Set an atomic variable to a value.
 *
 * This function also acts as a full memory barrier.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicU32 variable to be modified.
 * \param v the desired value.
 * \returns the previous value of the atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_GetAtomicU32
 */
	[CLink] public static extern uint32 SDL_SetAtomicU32(SDL_AtomicU32* a, uint32 v);

/**
 * Get the value of an atomic variable.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicU32 variable.
 * \returns the current value of an atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_SetAtomicU32
 */
	[CLink] public static extern uint32 SDL_GetAtomicU32(SDL_AtomicU32* a);

/**
 * Add to an atomic variable.
 *
 * This function also acts as a full memory barrier.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to an SDL_AtomicU32 variable to be modified.
 * \param v the desired value to add or subtract.
 * \returns the previous value of the atomic variable.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.4.0.
 */
	[CLink] public static extern uint32 SDL_AddAtomicU32(SDL_AtomicU32* a, int32 v);

/**
 * Set a pointer to a new value if it is currently an old value.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to a pointer.
 * \param oldval the old pointer value.
 * \param newval the new pointer value.
 * \returns true if the pointer was set, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_CompareAndSwapAtomicInt
 * \sa SDL_GetAtomicPointer
 * \sa SDL_SetAtomicPointer
 */
	[CLink] public static extern bool SDL_CompareAndSwapAtomicPointer(void** a, void* oldval, void* newval);

/**
 * Set a pointer to a value atomically.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to a pointer.
 * \param v the desired pointer value.
 * \returns the previous value of the pointer.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_CompareAndSwapAtomicPointer
 * \sa SDL_GetAtomicPointer
 */
	[CLink] public static extern void* SDL_SetAtomicPointer(void** a, void* v);

/**
 * Get the value of a pointer atomically.
 *
 * ***Note: If you don't know what this function is for, you shouldn't use
 * it!***
 *
 * \param a a pointer to a pointer.
 * \returns the current value of a pointer.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.2.0.
 *
 * \sa SDL_CompareAndSwapAtomicPointer
 * \sa SDL_SetAtomicPointer
 */
	[CLink] public static extern void* SDL_GetAtomicPointer(void** a);

}
