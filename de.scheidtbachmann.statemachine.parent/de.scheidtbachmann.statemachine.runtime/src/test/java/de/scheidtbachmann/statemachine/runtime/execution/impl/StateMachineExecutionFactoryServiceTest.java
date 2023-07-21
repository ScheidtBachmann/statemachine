// ******************************************************************************
//
// Copyright (c) 2023 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.runtime.execution.impl;

import static org.assertj.core.api.BDDAssertions.then;

import de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager;

import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

class StateMachineExecutionFactoryServiceTest {

    private static final String NAME_FRAGMENT = UUID.randomUUID().toString();
    private static final String TIMEOUT_ID = "TIMEOUT_ID";
    private static final Duration TIMEOUT_DELAY = Duration.ofMillis(20);

    private StateMachineExecutionFactoryService testee;
    private ScheduledExecutorService executorService;
    private Object result;

    @Test
    void testCreateExecutor_ShouldReturnExecutor() {
        givenTesteeHasBeenCreated();
        whenRetrievingExecutor();
        thenScheduledExecutorIsReturned();
    }

    @Test
    void testCreateExecutor_ThreadShouldContainNameFragment() throws InterruptedException, ExecutionException {
        givenTesteeHasBeenCreated();
        givenExecutorHasBeenRetrieved();
        whenRetrievingThreadName();
        thenThreadNameContainsNameFragment();
    }

    @Test
    void testCreateTimeout_ShouldReturnTimeoutManager() throws InterruptedException, ExecutionException {
        givenTesteeHasBeenCreated();
        givenExecutorHasBeenRetrieved();
        whenCreatingTimeoutManager();
        thenTimeoutManagerIsReturned();
    }

    @Test
    void testReleaseExecutor() throws InterruptedException, ExecutionException {
        givenTesteeHasBeenCreated();
        givenExecutorHasBeenRetrieved();
        whenReleasingExecutor();
        thenExecutorHasBeenShutDown();
    }

    @Test
    void testRunningInExecutor_ThreadInExecutor() throws InterruptedException, ExecutionException {
        givenTesteeHasBeenCreated();
        givenExecutorHasBeenRetrieved();
        whenTestingForThreadRunningInExecutor();
        thenThreadIsRunningInExecutor();
    }

    @Test
    void testRunningInExecutor_ThreadOutOfExecutor() throws InterruptedException, ExecutionException {
        givenTesteeHasBeenCreated();
        givenExecutorHasBeenRetrieved();
        whenTestingForThreadRunningOutOfExecutor();
        thenThreadIsNotRunningInExecutor();
    }

    private void givenTesteeHasBeenCreated() {
        testee = new StateMachineExecutionFactoryService();
    }

    private void givenExecutorHasBeenRetrieved() throws InterruptedException, ExecutionException {
        executorService = testee.createExecutor(NAME_FRAGMENT);
        executorService.submit(() -> { /* Just a dummy task to make sure the executor is created */ }).get();
    }

    private void whenRetrievingExecutor() {
        result = testee.createExecutor(NAME_FRAGMENT);
    }

    private void whenRetrievingThreadName() throws InterruptedException, ExecutionException {
        executorService.submit(() -> {
            result = Thread.currentThread().getName();
        }).get();
    }

    private void whenReleasingExecutor() {
        testee.releaseExecutor(executorService);
    }

    private void whenCreatingTimeoutManager() {
        result = testee.createTimeout(executorService, TIMEOUT_ID, TIMEOUT_DELAY.toMillis(), TimeUnit.MILLISECONDS,
            null, false);
    }

    private void whenTestingForThreadRunningOutOfExecutor() {
        result = testee.isRunningInExecutor();
    }

    private void whenTestingForThreadRunningInExecutor() throws InterruptedException, ExecutionException {
        executorService.submit(() -> {
            result = testee.isRunningInExecutor();
        }).get();
    }

    private void thenScheduledExecutorIsReturned() {
        then(result).isNotNull();
        then(result).isInstanceOf(ScheduledExecutorService.class);
    }

    private void thenExecutorHasBeenShutDown() {
        then(executorService.isShutdown()).isTrue();
    }

    private void thenThreadNameContainsNameFragment() {
        then(result).asString().contains(NAME_FRAGMENT);
    }

    private void thenTimeoutManagerIsReturned() {
        then(result).isInstanceOf(StateMachineTimeoutManager.class);
    }

    private void thenThreadIsRunningInExecutor() {
        then(result).isInstanceOf(Boolean.class);
        then((boolean) result).isTrue();
    }

    private void thenThreadIsNotRunningInExecutor() {
        then(result).isInstanceOf(Boolean.class);
        then((boolean) result).isFalse();
    }
}
