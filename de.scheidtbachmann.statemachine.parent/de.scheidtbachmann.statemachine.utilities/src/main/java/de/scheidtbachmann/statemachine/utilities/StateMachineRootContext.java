
package de.scheidtbachmann.statemachine.utilities;

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
