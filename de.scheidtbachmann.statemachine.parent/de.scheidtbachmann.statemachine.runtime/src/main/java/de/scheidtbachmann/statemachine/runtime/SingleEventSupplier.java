// ******************************************************************************
//
// Copyright (c) 2022 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.runtime;

/**
 * Functional interface to encapsulate the supplier for a single InputEvent in the StateMachine.
 *
 * @param <T>
 *            The concrete type of InputEvent this supplies.
 */
@FunctionalInterface
public interface SingleEventSupplier<T> {

    T getEvent();
}
