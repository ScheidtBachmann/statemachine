
package de.scheidtbachmann.statemachine.utilities.execution;

import de.scheidtbachmann.statemachine.utilities.execution.StateMachineTimeoutManager.Timeout;

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
     * @param delay
     *            The delay for the timeout scheduling
     * @param timeUnit
     *            The {@link TimeUnit} of the delay.
     * @param timeoutAction
     *            The action to perform when the timeout is hit. The
     *            {@link Consumer} is passed the actual {@link Timeout},
     *            so that the cancellation state can be validated during
     *            execution.
     * @return The created {@link StateMachineTimeoutManager}.
     */
    StateMachineTimeoutManager createTimeout(ScheduledExecutorService executor, long delay, TimeUnit timeUnit,
        Consumer<Timeout> timeoutAction);

}