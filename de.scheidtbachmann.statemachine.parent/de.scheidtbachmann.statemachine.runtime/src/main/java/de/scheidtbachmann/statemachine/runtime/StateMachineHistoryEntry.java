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

import java.util.Objects;

/**
 * Small wrapper to store the history of state machine actions.
 */
public class StateMachineHistoryEntry {

    private String startState;
    private String events;
    private String endState;
    private Throwable throwable;

    /**
     * Returns the name of the state (or multiple comma-separated states) the state machine was in,
     * at the start of the activation.
     *
     * @return the state at the start of the activation.
     */
    public String getStartState() {
        return startState;
    }

    /**
     * Stores the state of the state machine before activation.
     *
     * @param startState
     *            The name of the state before activation (or multiple comma-separated states).
     */
    public void setStartState(final String startState) {
        this.startState = startState;
    }

    /**
     * Returns the (comma-seperated) events, active in the state machine activation.
     *
     * @return the string representation of the active events
     */
    public String getEvents() {
        return events;
    }

    /**
     * Stores the events, active in the state machine activation.
     *
     * @param events
     *            The string representation of the active events (comma-separated if multiple events)
     */
    public void setEvents(final String events) {
        this.events = events;
    }

    /**
     * Returns the name of the state (or multiple comma-separated states) the state machine was in,
     * at the end of the activation.
     *
     * @return the state at the end of the activation.
     */
    public String getEndState() {
        return endState;
    }

    /**
     * Stores the state of the state machine after activation.
     *
     * @param endState
     *            The name of the state after activation (or multiple comma-separated states).
     */
    public void setEndState(final String endState) {
        this.endState = endState;
    }

    /**
     * Returns the {@link Throwable} that might have been thrown during the state machine activation.
     *
     * @return the {@link Throwable} that has been thrown, or {@code null} if no {@link Throwable} has been thrown
     */
    public Throwable getThrowable() {
        return throwable;
    }

    /**
     * Stores the {@link Throwable} that has been thrown during the state machine activation.
     *
     * @param throwable
     *            The {@link Throwable} to store for the execution.
     */
    public void setThrowable(final Throwable throwable) {
        this.throwable = throwable;
    }

    @Override
    public int hashCode() {
        return Objects.hash(endState, events, startState, throwable);
    }

    @Override
    public boolean equals(final Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final StateMachineHistoryEntry other = (StateMachineHistoryEntry) obj;
        return Objects.equals(endState, other.endState) && Objects.equals(events, other.events)
            && Objects.equals(startState, other.startState) && Objects.equals(throwable, other.throwable);
    }

    @Override
    public String toString() {
        final StringBuilder builder = new StringBuilder();
        builder.append("StateMachineHistoryEntry [");
        builder.append("startState=").append(startState);
        builder.append(", events=").append(events);
        builder.append(", endState=").append(endState);
        builder.append(", throwable=").append(throwable);
        builder.append("]");
        return builder.toString();
    }
}
