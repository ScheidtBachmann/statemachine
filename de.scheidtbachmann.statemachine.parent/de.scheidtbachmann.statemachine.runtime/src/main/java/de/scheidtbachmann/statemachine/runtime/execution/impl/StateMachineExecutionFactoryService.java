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
import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.osgi.service.component.annotations.Component;

import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

/**
 * Implementation of the {@link StateMachineExecutionFactory} for regular usage
 * in OSGi context.
 */
@Component(name = "statemachine.utilities.StateMachineExecutionFactoryService", immediate = true)
public class StateMachineExecutionFactoryService implements StateMachineExecutionFactory {

    @Override
    public ScheduledExecutorService createExecutor(final String nameFragment) {
        // Create a thread factory to be able to use prettier names for the generated threads
        // as well as handling of uncaught exceptions
        final ThreadFactory executorThreadFactory = runnable -> {
            final String threadName = String.format("StateMachine-%s-%s", nameFragment, UUID.randomUUID().toString());
            return new Thread(runnable, threadName);
        };
        return Executors.newSingleThreadScheduledExecutor(executorThreadFactory);
    }

    @Override
    public void releaseExecutor(final ScheduledExecutorService executor) {
        if (executor != null) {
            executor.shutdown();
        }
    }

    @Override
    public StateMachineTimeoutManager createTimeout(final ScheduledExecutorService executor, final String timeoutId,
        final long delay, final TimeUnit timeUnit, final Runnable timeoutAction, final boolean autoStart) {
        return new StateMachineTimeoutManagerImpl(executor, delay, timeUnit, timeoutAction, autoStart);
    }
}
