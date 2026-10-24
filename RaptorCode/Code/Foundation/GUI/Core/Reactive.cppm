// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :reactive partition
//
// Values that update what depends on them (G5 of Specs/vg-and-gui-lab.md, after AUI's property
// system: dependency tracking, no manual subscriptions). A Property holds a value and records who
// reads it; a Computed is a value derived from others, re-evaluated lazily when one of them
// changes; an Effect runs a function and runs it again when something it read changes. Nothing
// subscribes by hand: what an evaluation reads is what it depends on, found again on every run, so
// a branch that stops reading a value stops depending on it.
//
// Changes push invalidation and pull values: a Property's change marks Computeds stale (they
// recompute when next read) and queues Effects on their scheduler, which a SceneRoot flushes once a
// frame, so a burst of changes costs one run per effect. An effect without a scheduler (a node
// outside any scene, a test) runs at once.
//
// The evaluation in progress is per thread, not per GUI: two GUIs never share an observer, and an
// evaluation never spans threads. Single-threaded otherwise, like the tree.

module;
#include "Core/Prelude.h"

export module foundation.gui:reactive;

import foundation.core; // Array, Function, Move

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Observer;

    /// The observer evaluating on this thread (the one a read is recorded for), or null.
    [[nodiscard]] Observer*& CurrentObserverSlot() noexcept;

    /// Something that may be read and may change: links itself to whoever read it, and tells them
    /// when it changes.
    class Observable
    {
    public:
        Observable() noexcept = default;
        Observable(const Observable&) = delete;
        Observable& operator=(const Observable&) = delete;
        ~Observable() { DetachAll(); }

        /// Records a read by the evaluating observer, if any (once per evaluation).
        void Track() const;
        /// Everything that read this is told it changed (Computeds go stale, Effects queue).
        void Notify();

        [[nodiscard]] usize ObserverCount() const noexcept { return m_observers.Size(); }

    private:
        friend class Observer;
        mutable Array<Observer*> m_observers;

        void DetachAll();
    };

    /// Something that reads: a Computed or an Effect. Its sources are what its last evaluation read.
    class Observer
    {
    public:
        Observer() noexcept = default;
        Observer(const Observer&) = delete;
        Observer& operator=(const Observer&) = delete;
        virtual ~Observer() { ClearSources(); }

        /// A source changed.
        virtual void Invalidate() = 0;

        [[nodiscard]] usize SourceCount() const noexcept { return m_sources.Size(); }

    protected:
        /// Runs `fn` as this observer: the sources of the last run are dropped, and what `fn`
        /// reads becomes the new ones.
        template <typename F>
        decltype(auto) Evaluate(F&& fn)
        {
            ClearSources();
            Scope scope(this);
            return fn();
        }

        void ClearSources()
        {
            for (const Observable* source : m_sources)
            {
                Array<Observer*>& list = source->m_observers;
                for (usize i = 0; i < list.Size(); ++i)
                    if (list[i] == this)
                    {
                        list.RemoveAt(i);
                        break;
                    }
            }
            m_sources.Clear();
        }

    private:
        friend class Observable;
        Array<const Observable*> m_sources;

        struct Scope
        {
            Observer* previous;
            explicit Scope(Observer* self) noexcept : previous(CurrentObserverSlot()) { CurrentObserverSlot() = self; }
            ~Scope() { CurrentObserverSlot() = previous; }
        };
    };

    /// Runs `fn` with no observer: what it reads is not recorded (an effect's writes that read a
    /// value first, a native handler called from inside an evaluation).
    template <typename F>
    decltype(auto) Untracked(F&& fn)
    {
        Observer*& slot = CurrentObserverSlot();
        Observer* previous = slot;
        slot = nullptr;
        struct Restore
        {
            Observer*& slot;
            Observer* previous;
            ~Restore() { slot = previous; }
        } restore{slot, previous};
        return fn();
    }

    inline void Observable::Track() const
    {
        Observer* observer = CurrentObserverSlot();
        if (observer == nullptr)
            return;
        for (const Observable* source : observer->m_sources)
            if (source == this)
                return;
        observer->m_sources.PushBack(this);
        m_observers.PushBack(observer);
    }

    inline void Observable::Notify()
    {
        if (m_observers.IsEmpty())
            return;
        // A copy: an observer told may re-evaluate at once (no scheduler) and relink.
        const Array<Observer*> observers = m_observers;
        for (Observer* observer : observers)
            observer->Invalidate();
    }

    inline void Observable::DetachAll()
    {
        for (Observer* observer : m_observers)
        {
            Array<const Observable*>& sources = observer->m_sources;
            for (usize i = 0; i < sources.Size(); ++i)
                if (sources[i] == this)
                {
                    sources.RemoveAt(i);
                    break;
                }
        }
        m_observers.Clear();
    }

    /// A value that records its readers and tells them when it changes. Setting it to what it is
    /// changes nothing.
    template <typename T>
    class Property
    {
    public:
        Property() = default;
        explicit Property(T value) : m_value(Move(value)) {}

        [[nodiscard]] const T& Get() const
        {
            m_changed.Track();
            return m_value;
        }
        /// The value without recording the read.
        [[nodiscard]] const T& Peek() const noexcept { return m_value; }

        /// Whether the value changed (and its readers were told).
        bool Set(T value)
        {
            if (m_value == value)
                return false;
            m_value = Move(value);
            m_changed.Notify();
            return true;
        }

        [[nodiscard]] const Observable& Changed() const noexcept { return m_changed; }

    private:
        T m_value{};
        Observable m_changed;
    };

    /// A value derived from others: evaluated when first read, then again only when read after one
    /// of the values it read changed. It records its own readers, as a Property does.
    template <typename T>
    class Computed final : public Observer
    {
    public:
        explicit Computed(core::Function<T()> expression) : m_expression(Move(expression)) {}

        [[nodiscard]] const T& Get()
        {
            m_changed.Track();
            if (m_stale)
            {
                m_value = Evaluate(m_expression);
                m_stale = false;
            }
            return m_value;
        }
        [[nodiscard]] bool IsStale() const noexcept { return m_stale; }

        void Invalidate() override
        {
            if (m_stale)
                return; // its readers were told already
            m_stale = true;
            m_changed.Notify();
        }

    private:
        core::Function<T()> m_expression;
        T m_value{};
        bool m_stale = true;
        Observable m_changed;
    };

    class Effect;

    /// Where effects wait to run: a GUIContext holds one and flushes it once a frame, for all its
    /// roots, so changes in between cost one run of each effect they reach.
    class EffectScheduler
    {
    public:
        EffectScheduler() noexcept = default;
        EffectScheduler(const EffectScheduler&) = delete;
        EffectScheduler& operator=(const EffectScheduler&) = delete;
        ~EffectScheduler();

        void Queue(Effect& effect);
        void Forget(Effect& effect);
        /// Runs the queued effects, and those their runs queue, at most a few rounds (an effect that
        /// changes what it reads would never settle). How many ran.
        u32 Flush();

        [[nodiscard]] bool HasPending() const noexcept { return !m_queue.IsEmpty(); }

    private:
        Array<Effect*> m_queue;
        Array<Effect*> m_batch; // the round being run (an effect destroyed meanwhile is nulled here)
    };

    /// A function run once at creation and again whenever something it read changed: on its
    /// scheduler's next flush, or at once when it has none.
    class Effect final : public Observer
    {
    public:
        using SchedulerSource = core::Function<EffectScheduler*()>;

        /// `scheduler` names where it waits; asked at each change, so an effect owned by a node finds
        /// the scheduler of the scene the node is in now.
        explicit Effect(core::Function<void()> body, SchedulerSource scheduler = {})
            : m_body(Move(body)), m_scheduler(Move(scheduler))
        {
            Run();
        }
        ~Effect() override
        {
            if (m_queuedOn != nullptr)
                m_queuedOn->Forget(*this);
        }

        /// Runs the body. An effect told to run again while it runs (its body changed what it read,
        /// with no scheduler to wait on) runs again after it finishes, not inside itself, a few times
        /// at most: one that never settles is cut off rather than recursing without end.
        void Run()
        {
            m_queuedOn = nullptr;
            if (m_running)
            {
                m_rerun = true;
                return;
            }
            m_running = true;
            for (i32 round = 0; round < 16; ++round)
            {
                m_rerun = false;
                ++m_runs;
                Evaluate(m_body);
                if (!m_rerun)
                    break;
            }
            m_running = false;
        }
        [[nodiscard]] u32 RunCount() const noexcept { return m_runs; }
        [[nodiscard]] bool IsQueued() const noexcept { return m_queuedOn != nullptr; }

        void Invalidate() override
        {
            if (m_running)
            {
                m_rerun = true; // after this run, not inside it
                return;
            }
            if (m_queuedOn != nullptr)
                return;
            EffectScheduler* scheduler = m_scheduler ? m_scheduler() : nullptr;
            if (scheduler == nullptr)
            {
                Run();
                return;
            }
            m_queuedOn = scheduler;
            scheduler->Queue(*this);
        }

    private:
        friend class EffectScheduler;
        core::Function<void()> m_body;
        SchedulerSource m_scheduler;
        EffectScheduler* m_queuedOn = nullptr;
        u32 m_runs = 0;
        bool m_running = false; // inside the body
        bool m_rerun = false;   // told to run again meanwhile
    };

    inline EffectScheduler::~EffectScheduler()
    {
        for (Effect* effect : m_queue)
            effect->m_queuedOn = nullptr;
        for (Effect* effect : m_batch)
            if (effect != nullptr)
                effect->m_queuedOn = nullptr;
    }

    inline void EffectScheduler::Queue(Effect& effect) { m_queue.PushBack(&effect); }

    inline void EffectScheduler::Forget(Effect& effect)
    {
        for (usize i = 0; i < m_queue.Size(); ++i)
            if (m_queue[i] == &effect)
            {
                m_queue.RemoveAt(i);
                break;
            }
        for (Effect*& queued : m_batch)
            if (queued == &effect)
                queued = nullptr;
    }

    inline u32 EffectScheduler::Flush()
    {
        u32 ran = 0;
        for (i32 round = 0; round < 16 && !m_queue.IsEmpty(); ++round)
        {
            m_batch = Move(m_queue);
            m_queue.Clear();
            for (usize i = 0; i < m_batch.Size(); ++i)
            {
                Effect* effect = m_batch[i];
                if (effect == nullptr || effect->m_queuedOn != this)
                    continue; // destroyed, or run since
                effect->Run();
                ++ran;
            }
            m_batch.Clear();
        }
        return ran;
    }
}
