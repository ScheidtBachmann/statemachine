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

    public String getStartState() {
        return startState;
    }

    public void setStartState(final String startState) {
        this.startState = startState;
    }

    public String getEvents() {
        return events;
    }

    public void setEvents(final String events) {
        this.events = events;
    }

    public String getEndState() {
        return endState;
    }

    public void setEndState(final String endState) {
        this.endState = endState;
    }

    public Throwable getThrowable() {
        return throwable;
    }

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
