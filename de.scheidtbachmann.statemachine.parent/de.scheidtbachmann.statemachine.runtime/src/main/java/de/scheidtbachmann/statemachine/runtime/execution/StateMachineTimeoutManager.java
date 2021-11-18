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

/**
 * Timeout manager that is started for a state machine and waits for a given
 * time. After the time has elapsed the given action is executed in the
 * execution context of the state machine.
 *
 * The timeout can be cancelled or restarted at any time.
 */
public interface StateMachineTimeoutManager {

    /**
     * Checks if there is currently a timeout running.
     *
     * @return {@code true} if a timeout is running, {@code false} otherwise.
     */
    boolean isRunning();

    /**
     * Starts the timeout.
     */
    void start();

    /**
     * Resets/starts the timeout.
     */
    void restart();

    /**
     * Cancels a running timeout.
     */
    void cancel();
}