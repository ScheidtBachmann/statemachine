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
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Implementation of {@link StateMachineExecutionFactory} for Unit tests.
 * Timeouts created by implementation are not actually time-dependent, but can be explicitly triggered from the test
 * using {@link #triggerTimeout(String)} with the corresponding timeout ID.
 */
public class StateMachineTestExecutionFactory implements StateMachineExecutionFactory {

    private static final Logger LOG = LoggerFactory.getLogger(StateMachineTestExecutionFactory.class);

    private final TrackedStateMachineExecutorService executorService;

    private final Map<String, StateMachineTestTimeoutManager> timeouts;

    public StateMachineTestExecutionFactory() {
        timeouts = new HashMap<>();
        final ThreadFactory factory = runnable -> {
            final Thread createdThread = new Thread(runnable, "StateMachineTestExecutionThread");
            createdThread.setUncaughtExceptionHandler((thread, throwable) -> LOG
                .error(String.format("Uncaught exception in Thread (%s)", thread), throwable));
            return createdThread;
        };
        executorService = new TrackedStateMachineExecutorService(factory);
    }

    @Override
    public ScheduledExecutorService createExecutor(final String threadName) {
        return executorService;
    }

    @Override
    public void releaseExecutor(final ScheduledExecutorService executor) {
        // Nothing to do here, yet
        // In a future expansion we might want to handle some state here,
        // validating that nobody tries to do things on an executor that has been shut down.
    }

    @Override
    public synchronized StateMachineTimeoutManager createTimeout(final ScheduledExecutorService executor,
        final String timeoutId, final long delay, final TimeUnit timeunit, final Runnable timeoutAction,
        final boolean autoStart) {

        if (timeoutIsRunning(timeoutId)) {
            throw new StateMachineTestTimeoutException(String.format(
                "Tried creating new timeout %s, but timeout already exists and is already running.", timeoutId));
        } else {
            return registerNewTimeout(executor, timeoutId, timeoutAction, autoStart);
        }
    }

    private boolean timeoutIsRunning(final String timeoutId) {
        return timeouts.containsKey(timeoutId) && timeouts.get(timeoutId).isRunning();
    }

    private StateMachineTimeoutManager registerNewTimeout(final ScheduledExecutorService executor,
        final String timeoutId, final Runnable timeoutAction, final boolean autoStart) {
        final StateMachineTestTimeoutManager newTimeout =
            new StateMachineTestTimeoutManager(executor, timeoutAction, autoStart);
        timeouts.put(timeoutId, newTimeout);
        return newTimeout;
    }

    /**
     * Triggers the timeout with the given ID, if it is currently running.
     *
     * @param timeoutId
     *            The id of the timeout to trigger.
     * @throws StateMachineTestTimeoutException
     *             if execution is not successful
     */
    public void triggerTimeout(final String timeoutId) {
        final AtomicReference<StateMachineTestTimeoutManager> timeoutManager = new AtomicReference<>();
        try {
            executorService.submit(() -> {
                if (timeoutIsRunning(timeoutId)) {
                    timeoutManager.set(timeouts.get(timeoutId));
                }
            }).get();
            if (timeoutManager.get() != null) {
                timeoutManager.get().trigger();
            }
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (final ExecutionException e) {
            throw new StateMachineTestTimeoutException("Problem triggering timeout", e);
        }
    }

    /**
     * Synchronizes the execution by waiting for all <b>currently scheduled</b> tasks to be finished in the executor.
     *
     * @throws StateMachineTestTimeoutException
     *             if a problem occurs during execution
     */
    public void waitForCurrentTasksDone() {
        try {
            CompletableFuture.runAsync(() -> {
                // Nothing to do here, just wait on the execution
            }, executorService.getDelegate()).get();
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (final ExecutionException e) {
            throw new StateMachineTestTimeoutException("Problem synchronizing execution", e);
        }
    }

    /**
     * Synchronizes the execution by waiting for all <b>currently scheduled and newly incoming</b>
     * tasks to be finished in the executor.
     *
     * @throws StateMachineTestTimeoutException
     *             if a problem occurs during execution
     */
    public void waitForAllTasksDone() {
        while (executorService.potentiallyHasMoreTasks()) {
            executorService.setTasksHaveBeenWaitedOn();
            waitForCurrentTasksDone();
        }
    }
}
