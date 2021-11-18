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

package de.scheidtbachmann.statemachine.testing.execution;

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineExecutionFactory;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeout;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

/**
 * Implementation of {@link StateMachineExecutionFactory} for Unit tests.
 * Timeouts created by implementation are not actually time-dependent, but can be explicitly triggered from the test
 * using {@link #triggerTimeout(String)} with the corresponding timeout ID.
 */
public class StateMachineTestExecutionFactory implements StateMachineExecutionFactory {

    private final ScheduledExecutorService executorService;

    private final Map<String, StateMachineTestTimeoutManager> timeouts;

    private final AtomicBoolean executorIsHealthy;

    public StateMachineTestExecutionFactory() {
        executorIsHealthy = new AtomicBoolean(true);
        timeouts = new HashMap<>();
        final ThreadFactory factory = runnable -> {
            final Thread createdThread = new Thread(runnable, "StateMachineTestExecutionThread");
            createdThread.setUncaughtExceptionHandler((thread, throwable) -> executorIsHealthy.set(false));
            return createdThread;
        };
        executorService = Executors.newSingleThreadScheduledExecutor(factory);
    }

    @Override
    public ScheduledExecutorService createExecutor(final String threadName) {
        return executorService;
    }

    @Override
    public StateMachineTimeoutManager createTimeout(final ScheduledExecutorService executor, final String timeoutId,
        final long delay, final TimeUnit timeunit, final Consumer<StateMachineTimeout> timeoutAction,
        final boolean autoStart) {

        if (timeoutIsRunning(timeoutId)) {
            throw new StateMachineTestTimeoutException(String.format(
                "Tried creating new timeout %s, but timeout already exists and is already running.", timeoutId));
        } else {
            return registerNewTimeout(executor, timeoutId, timeoutAction);
        }
    }

    private boolean timeoutIsRunning(final String timeoutId) {
        return timeouts.containsKey(timeoutId) && timeouts.get(timeoutId).isRunning();
    }

    private StateMachineTimeoutManager registerNewTimeout(final ScheduledExecutorService executor,
        final String timeoutId, final Consumer<StateMachineTimeout> timeoutAction) {
        return timeouts.computeIfAbsent(timeoutId,
            id -> new StateMachineTestTimeoutManager(executor, id, timeoutAction));
    }

    /**
     * Triggers the timeout with the given ID, if it is currently running.
     *
     * @param timeoutId
     *            The id of the timeout to trigger.
     */
    public void triggerTimeout(final String timeoutId) {
        if (timeoutIsRunning(timeoutId)) {
            timeouts.get(timeoutId).trigger();
        }
    }

    /**
     * Checks if anything has thrown an uncaught exception in the executor.
     *
     * @return {@code true} if the executor didn't encounter any exception, {@code false} otherwise.
     */
    public boolean getExecutorIsHealthy() {
        return executorIsHealthy.get();
    }
}
