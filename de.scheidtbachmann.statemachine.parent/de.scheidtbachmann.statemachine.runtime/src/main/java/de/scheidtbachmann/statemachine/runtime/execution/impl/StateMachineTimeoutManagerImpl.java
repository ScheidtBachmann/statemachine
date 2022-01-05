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

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Timeout manager that controls execution for delayed actions in the state machine.
 * After the time has elapsed the given action is executed in the execution context of the state machine.
 *
 * The timeout can be cancelled or restarted at any time.
 */
public class StateMachineTimeoutManagerImpl implements StateMachineTimeoutManager {

    private static final Logger LOG = LoggerFactory.getLogger(StateMachineTimeoutManagerImpl.class);

    private final ScheduledExecutorService executor;
    private final Runnable timeoutAction;
    private ScheduledFuture<?> timeoutFuture = null;
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
     * @param autoStart
     *            Flag to control whether the timeout should be immediately started
     */
    public StateMachineTimeoutManagerImpl(final ScheduledExecutorService executor, final long delay,
        final TimeUnit timeUnit, final Runnable timeoutAction, final boolean autoStart) {
        this.timeoutAction = timeoutAction;
        this.executor = executor;
        this.delay = delay;
        this.timeUnit = timeUnit;
        if (autoStart) {
            start();
        }
    }

    @Override
    public synchronized boolean isRunning() {
        return timeoutFuture != null && !timeoutFuture.isDone();
    }

    @Override
    public synchronized void start() {
        if (!isRunning()) {
            timeoutFuture = executor.schedule(this::execute, delay, timeUnit);
        }
    }

    @Override
    public synchronized void restart() {
        cancel();
        start();
    }

    @Override
    public synchronized void cancel() {
        if (isRunning()) {
            timeoutFuture.cancel(false);
        }
    }

    private void execute() {
        try {
            timeoutAction.run();
        } catch (final Throwable t) {
            LOG.error("Exception in scheduled code", t);
        }
    }
}
