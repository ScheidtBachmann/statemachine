// ******************************************************************************
//
// Copyright (c) 2021 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.runtime.execution.impl;

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineExecutionFactory;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.osgi.service.component.annotations.Component;

import java.lang.Thread.State;
import java.lang.ref.WeakReference;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

/**
 * Implementation of the {@link StateMachineExecutionFactory} for regular usage
 * in OSGi context.
 */
@Component(name = "statemachine.utilities.StateMachineExecutionFactoryService", immediate = true,
    service = { ScheduledExecutorService.class })
public class StateMachineExecutionFactoryService implements StateMachineExecutionFactory {

    private final List<WeakReference<Thread>> executorThreadReferences =
        Collections.synchronizedList(new LinkedList<>());

    @Override
    public ScheduledExecutorService createExecutor(final String nameFragment) {
        // Create a thread factory to be able to use prettier names for the generated threads
        // as well as handling of uncaught exceptions
        final ThreadFactory executorThreadFactory = runnable -> newThreadForExecutor(nameFragment, runnable);
        return Executors.newSingleThreadScheduledExecutor(executorThreadFactory);
    }

    @Override
    public void releaseExecutor(final ScheduledExecutorService executor) {
        if (executor != null) {
            executor.shutdown();
        }
    }

    @Override
    public StateMachineTimeoutManager createTimeout(final ScheduledExecutorService executor, final String timeoutId,
        final long delay, final TimeUnit timeUnit, final Runnable timeoutAction, final boolean autoStart) {
        return new StateMachineTimeoutManagerImpl(executor, delay, timeUnit, timeoutAction, autoStart);
    }

    @Override
    public boolean isRunningInExecutor() {
        final Thread currentThread = Thread.currentThread();
        return executorThreadReferences.stream().anyMatch(threadRef -> threadRef.get() == currentThread);
    }

    protected Thread newThreadForExecutor(final String nameFragment, final Runnable runnable) {
        purgeTerminatedThreadRefs();
        final String threadName = String.format("StateMachine-%s-%s", nameFragment, UUID.randomUUID().toString());
        final Thread createdThread = new Thread(runnable, threadName);
        executorThreadReferences.add(new WeakReference<>(createdThread));
        return createdThread;
    }

    private void purgeTerminatedThreadRefs() {
        executorThreadReferences.removeIf(this::isThreadTerminated);
    }

    private boolean isThreadTerminated(final WeakReference<Thread> threadRef) {
        final Thread thread = threadRef.get();
        return thread == null || thread.getState() == State.TERMINATED;
    }
}
