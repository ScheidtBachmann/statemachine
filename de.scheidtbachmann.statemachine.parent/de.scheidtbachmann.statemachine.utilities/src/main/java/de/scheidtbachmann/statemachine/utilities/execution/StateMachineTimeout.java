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

package de.scheidtbachmann.statemachine.utilities.execution;

/**
 * An actual Timeout event. This allows to check the cancellation of the Timeout prior to execution of the action.
 */
public interface StateMachineTimeout {

    /**
     * Flag to indicate whether the timeout has been cancelled prior to execution.
     * This flag should be checked at the start of the action, if a cancellation between
     * scheduling and actual execution should be honored.
     *
     * @return {@code true} if the timeout has been cancelled, {@code false} otherwise.
     */
    boolean isCancelled();

}