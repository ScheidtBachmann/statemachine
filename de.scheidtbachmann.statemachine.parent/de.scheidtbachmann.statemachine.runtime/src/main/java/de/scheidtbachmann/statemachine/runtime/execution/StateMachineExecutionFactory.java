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

package de.scheidtbachmann.statemachine.runtime.execution;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Interface for a factory that is used by the state machine to handle the
 * direct tick execution as well as the scheduling of timeouts.
 */
public interface StateMachineExecutionFactory {

    /**
     * Creates a new {@link ScheduledExecutorService} for the state machine.
     *
     * @param nameFragment
     *            Part to be used in the name of the thread factory to
     *            distinguish generated threads.
     * @return The {@link ScheduledExecutorService} for the state machine.
     */
    ScheduledExecutorService createExecutor(String nameFragment);

    /**
     * Creates a new {@link StateMachineTimeoutManager} for the state machine.
     *
     * @param executor
     *            The {@link ScheduledExecutorService} used by the state
     *            machine.
     * @param timeoutId
     *            The identification of the timeout.
     * @param delay
     *            The delay for the timeout scheduling
     * @param timeUnit
     *            The {@link TimeUnit} of the delay.
     * @param timeoutAction
     *            The action to perform when the timeout is hit. The
     *            {@link Consumer} is passed the actual {@link StateMachineTimeout},
     *            so that the cancellation state can be validated during
     *            execution.
     * @param autoStart
     *            Flag to control whether the timeout should be immediately started
     * @return The created {@link StateMachineTimeoutManager}.
     */
    StateMachineTimeoutManager createTimeout(ScheduledExecutorService executor, String timeoutId, long delay,
        TimeUnit timeUnit, Consumer<StateMachineTimeout> timeoutAction, boolean autoStart);

}