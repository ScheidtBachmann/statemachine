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

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeout;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.ScheduledExecutorService;
import java.util.function.Consumer;

/**
 * Implementation of {@link StateMachineTimeoutManager} for testing purposes.
 * This implementation has no actual timing functionality, but has to be triggered explicitly from the test code.
 */
public class StateMachineTestTimeoutManager implements StateMachineTimeoutManager {

    private boolean running;
    private final String timeoutId;

    private final ScheduledExecutorService executor;
    private final Consumer<StateMachineTimeout> action;

    public StateMachineTestTimeoutManager(final ScheduledExecutorService executor, final String timeoutId,
        final Consumer<StateMachineTimeout> action) {
        this.executor = executor;
        this.timeoutId = timeoutId;
        this.action = action;
        running = false;
    }

    @Override
    public boolean isRunning() {
        return running;
    }

    @Override
    public void start() {
        running = true;
    }

    @Override
    public void restart() {
        running = true;
    }

    @Override
    public void cancel() {
        running = false;
    }

    void trigger() {
        try {
            executor.submit(() -> action.accept(new StateMachineTestTimeout())).get();
            running = false;
        } catch (final ExecutionException e) {
            throw new StateMachineTestTimeoutException("Problem triggering timeout", e);
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private class StateMachineTestTimeout implements StateMachineTimeout {
        @Override
        public boolean isCancelled() {
            return !running;
        }

        @Override
        public String getId() {
            return timeoutId;
        }
    }
}
