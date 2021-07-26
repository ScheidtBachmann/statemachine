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

package de.scheidtbachmann.statemachine.utilities;

import java.util.stream.Collectors;

/**
 * Simple container for the current state of the state machine to implement the
 * proper toString method.
 */
public class StateMachineStateContainer {

    private final StateMachineRootContext rootContext;

    public StateMachineStateContainer(final StateMachineRootContext context) {
        rootContext = context;
    }

    @Override
    public String toString() {
        return rootContext.getCurrentState().distinct().collect(Collectors.joining(","));
    }
}