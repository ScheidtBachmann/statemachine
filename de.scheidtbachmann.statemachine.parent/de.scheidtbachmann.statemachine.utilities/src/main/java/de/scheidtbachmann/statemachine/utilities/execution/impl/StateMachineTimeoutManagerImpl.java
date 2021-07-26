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

package de.scheidtbachmann.statemachine.utilities.execution.impl;

import de.scheidtbachmann.statemachine.utilities.execution.StateMachineTimeout;
import de.scheidtbachmann.statemachine.utilities.execution.StateMachineTimeoutManager;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Timeout manager that is started for a state machine and waits for a given
 * time. After the time has elapsed the given action is executed in the
 * execution context of the state machine.
 *
 * The timeout can be cancelled or restarted at any time.
 */
public class StateMachineTimeoutManagerImpl implements StateMachineTimeoutManager {

    private final ScheduledExecutorService executor;
    private final Consumer<StateMachineTimeout> timeoutAction;
    private Timeout timeout = null;
    private final long delay;
    private final TimeUnit timeUnit;

    /**
     * Creates a new StateMachineTimeoutManager.
     *
     * @param executor
     *            the executor to use for timeouts
     * @param delay
     *            the delay for this timeout
     * @param timeUnit
     *            the time unit for the delay of this timeout
     * @param timeoutAction
     *            the action to perform on timeout. The action is a
     *            {@link Consumer} for the concrete {@link Timeout}, so
     *            that during execution the cancellation of the timeout
     *            can be checked..
     */
    public StateMachineTimeoutManagerImpl(final ScheduledExecutorService executor, final long delay,
        final TimeUnit timeUnit, final Consumer<StateMachineTimeout> timeoutAction) {
        this.timeoutAction = timeoutAction;
        this.executor = executor;
        this.delay = delay;
        this.timeUnit = timeUnit;
    }

    @Override
    public boolean isRunning() {
        return timeout != null;
    }

    @Override
    public void restart() {
        if (timeout != null) {
            timeout.cancel();
        }
        timeout = new Timeout(executor, delay, timeUnit);
    }

    @Override
    public void cancel() {
        if (timeout != null) {
            timeout.cancel();
            timeout = null;
        }
    }

    public class Timeout implements StateMachineTimeout {
        private ScheduledFuture<?> timeoutFuture;
        private boolean cancelled = false;

        public Timeout(final ScheduledExecutorService executor, final long delay, final TimeUnit timeUnit) {
            timeoutFuture = executor.schedule(this::execute, delay, timeUnit);
        }

        private void execute() {
            if (cancelled) {
                return;
            }
            timeoutAction.accept(this);
            timeout = null;
        }

        private void cancel() {
            cancelled = true;
            if (timeoutFuture != null) {
                timeoutFuture.cancel(false);
                timeoutFuture = null;
            }
        }

        @Override
        public boolean isCancelled() {
            return cancelled;
        }
    }
}
