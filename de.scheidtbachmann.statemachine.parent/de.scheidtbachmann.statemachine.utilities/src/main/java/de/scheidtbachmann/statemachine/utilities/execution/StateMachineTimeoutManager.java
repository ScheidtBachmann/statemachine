
package de.scheidtbachmann.statemachine.utilities.execution;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Timeout manager that is started for a state machine and waits for a given
 * time. After the time has elapsed the given action is executed in the
 * execution context of the state machine.
 *
 * The timeout can be cancelled or restarted at any time.
 */
public class StateMachineTimeoutManager {

    private final ScheduledExecutorService executor;
    private final Consumer<Timeout> timeoutAction;
    private Timeout timeout = null;
    private final long delay;
    private final TimeUnit timeUnit;

    /**
     * Creates a new StateMachineTimeoutManager.
     *
     * @param executor
     *            the executor to use for timeouts
     * @param delay
     *            the delay for this timeout
     * @param timeUnit
     *            the time unit for the delay of this timeout
     * @param timeoutAction
     *            the action to perform on timeout. The action is a
     *            {@link Consumer} for the concrete {@link Timeout}, so
     *            that during execution the cancellation of the timeout
     *            can be checked..
     */
    public StateMachineTimeoutManager(final ScheduledExecutorService executor, final long delay,
        final TimeUnit timeUnit, final Consumer<Timeout> timeoutAction) {
        this.timeoutAction = timeoutAction;
        this.executor = executor;
        this.delay = delay;
        this.timeUnit = timeUnit;
    }

    /**
     * Checks if there is currently a timeout running.
     *
     * @return true if a timeout is running.
     */
    public boolean isRunning() {
        return timeout != null;
    }

    /**
     * Resets/starts the timeout.
     */
    public void restart() {
        if (timeout != null) {
            timeout.cancel();
        }
        timeout = new Timeout(executor, delay, timeUnit);
    }

    /**
     * Cancels a running timeout and no timeout is started.
     */
    public void cancel() {
        if (timeout != null) {
            timeout.cancel();
            timeout = null;
        }
    }

    public class Timeout {
        private ScheduledFuture<?> timeoutFuture;
        private boolean cancelled = false;

        public Timeout(final ScheduledExecutorService executor, final long delay, final TimeUnit timeUnit) {
            timeoutFuture = executor.schedule(this::execute, delay, timeUnit);
        }

        private void execute() {
            if (cancelled) {
                return;
            }
            timeoutAction.accept(this);
            timeout = null;
        }

        /**
         * Cancels this timeout.
         */
        public void cancel() {
            cancelled = true;
            if (timeoutFuture != null) {
                timeoutFuture.cancel(false);
                timeoutFuture = null;
            }
        }

        public boolean isCancelled() {
            return cancelled;
        }
    }
}
