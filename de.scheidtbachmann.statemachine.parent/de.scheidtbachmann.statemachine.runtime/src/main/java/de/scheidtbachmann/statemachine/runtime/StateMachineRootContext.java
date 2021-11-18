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

package de.scheidtbachmann.statemachine.runtime;

import java.util.stream.Stream;

/**
 * Simple interface that should be implemented by the root context of a generated state machine.
 */
public interface StateMachineRootContext {

    /**
     * Retrieve a {@link Stream} of names of states that are currently active.
     *
     * @return The {@link Stream} of names of active states.
     */
    Stream<String> getCurrentState();

}
