
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