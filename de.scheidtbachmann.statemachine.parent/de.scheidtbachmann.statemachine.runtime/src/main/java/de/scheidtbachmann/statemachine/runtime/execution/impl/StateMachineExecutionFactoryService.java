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

package de.scheidtbachmann.statemachine.runtime.execution.impl;

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineExecutionFactory;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeout;
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.osgi.service.component.annotations.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Implementation of the {@link StateMachineExecutionFactory} for regular usage
 * in OSGi context.
 */
@Component(name = "statemachine.utilities.StateMachineExecutionFactoryService", immediate = true)
public class StateMachineExecutionFactoryService implements StateMachineExecutionFactory {

    private static final Logger LOG = LoggerFactory.getLogger(StateMachineExecutionFactoryService.class);

    @Override
    public ScheduledExecutorService createExecutor(final String nameFragment) {
        // Create a thread factory to be able to use prettier names for the generated threads
        final ThreadFactory executorThreadFactory = runnable -> {
            final String threadName = String.format("StateMachine-%s-%s", nameFragment, UUID.randomUUID().toString());
            final Thread thread = new Thread(runnable, threadName);
            thread.setUncaughtExceptionHandler((failedThread, throwable) -> LOG.error(
                String.format("Exception in StateMachine Execution on thread %s", failedThread.getName()), throwable));
            return thread;
        };
        return Executors.newSingleThreadScheduledExecutor(executorThreadFactory);
    }

    @Override
    public StateMachineTimeoutManager createTimeout(final ScheduledExecutorService executor, final String timeoutId,
        final long delay, final TimeUnit timeUnit, final Consumer<StateMachineTimeout> timeoutAction,
        final boolean autoStart) {
        return new StateMachineTimeoutManagerImpl(executor, timeoutId, delay, timeUnit, timeoutAction, autoStart);
    }
}
