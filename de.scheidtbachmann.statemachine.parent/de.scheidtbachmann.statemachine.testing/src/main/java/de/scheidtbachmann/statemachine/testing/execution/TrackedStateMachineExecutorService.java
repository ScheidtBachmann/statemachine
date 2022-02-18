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

package de.scheidtbachmann.statemachine.testing.execution;

import java.util.Collection;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

class TrackedStateMachineExecutorService implements ScheduledExecutorService {

    private final ScheduledExecutorService delegatedExecutor;

    private volatile boolean executedTasks;

    TrackedStateMachineExecutorService(final ThreadFactory factory) {
        executedTasks = false;
        delegatedExecutor = Executors.newSingleThreadScheduledExecutor(factory);
    }

    public ScheduledExecutorService getDelegate() {
        return delegatedExecutor;
    }

    @Override
    public void shutdown() {
        delegatedExecutor.shutdown();
    }

    @Override
    public List<Runnable> shutdownNow() {
        return delegatedExecutor.shutdownNow();
    }

    @Override
    public boolean isShutdown() {
        return delegatedExecutor.isShutdown();
    }

    @Override
    public boolean isTerminated() {
        return delegatedExecutor.isTerminated();
    }

    @Override
    public boolean awaitTermination(final long timeout, final TimeUnit unit) throws InterruptedException {
        return delegatedExecutor.awaitTermination(timeout, unit);
    }

    @Override
    public <T> Future<T> submit(final Callable<T> task) {
        return delegatedExecutor.submit(task);
    }

    @Override
    public <T> Future<T> submit(final Runnable task, final T result) {
        return delegatedExecutor.submit(task, result);
    }

    @Override
    public Future<?> submit(final Runnable task) {
        return delegatedExecutor.submit(task);
    }

    @Override
    public <T> List<Future<T>> invokeAll(final Collection<? extends Callable<T>> tasks) throws InterruptedException {
        return delegatedExecutor.invokeAll(tasks);
    }

    @Override
    public <T> List<Future<T>> invokeAll(final Collection<? extends Callable<T>> tasks, final long timeout,
        final TimeUnit unit) throws InterruptedException {
        return delegatedExecutor.invokeAll(tasks, timeout, unit);
    }

    @Override
    public <T> T invokeAny(final Collection<? extends Callable<T>> tasks)
        throws InterruptedException, ExecutionException {
        return delegatedExecutor.invokeAny(tasks);
    }

    @Override
    public <T> T invokeAny(final Collection<? extends Callable<T>> tasks, final long timeout, final TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException {
        return delegatedExecutor.invokeAny(tasks, timeout, unit);
    }

    @Override
    public void execute(final Runnable command) {
        executedTasks = true;
        delegatedExecutor.execute(command);
    }

    @Override
    public ScheduledFuture<?> schedule(final Runnable command, final long delay, final TimeUnit unit) {
        return delegatedExecutor.schedule(command, delay, unit);
    }

    @Override
    public <V> ScheduledFuture<V> schedule(final Callable<V> callable, final long delay, final TimeUnit unit) {
        return delegatedExecutor.schedule(callable, delay, unit);
    }

    @Override
    public ScheduledFuture<?> scheduleAtFixedRate(final Runnable command, final long initialDelay, final long period,
        final TimeUnit unit) {
        return delegatedExecutor.scheduleAtFixedRate(command, initialDelay, period, unit);
    }

    @Override
    public ScheduledFuture<?> scheduleWithFixedDelay(final Runnable command, final long initialDelay, final long delay,
        final TimeUnit unit) {
        return delegatedExecutor.scheduleWithFixedDelay(command, initialDelay, delay, unit);
    }

    public boolean hasExecutedTasks() {
        return executedTasks;
    }

    public void resetExecutedTasks() {
        executedTasks = false;
    }
}