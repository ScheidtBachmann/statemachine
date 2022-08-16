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

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicBoolean;

class StateMachineTestExecutionFactoryTest {

    private static final int THREAD_WAIT_TIME = 2000;

    private final StateMachineTestExecutionFactory testee = new StateMachineTestExecutionFactory();

    private Runnable task;

    private final AtomicBoolean task1HasExecuted = new AtomicBoolean(false);
    private final AtomicBoolean task2HasExecuted = new AtomicBoolean(false);

    @Test
    void testWaitForCurrentTasksDone() {
        givenTaskSchedulesAnotherTask();
        whenExecutingCurrentTaskAndWaitingForIt();
        thenOnlyFirstTaskShouldHaveExecuted();
    }

    @Test
    void testWaitForAllTasksDone() {
        givenTaskSchedulesAnotherTask();
        whenExecutingAllTaskAndWaitingForIt();
        thenBothTasksShouldHaveExecuted();
    }

    private void givenTaskSchedulesAnotherTask() {
        task = () -> {
            waitSomeTime();
            testee.createExecutor("").execute(() -> {
                waitSomeTime();
                task2HasExecuted.set(true);
            });
            task1HasExecuted.set(true);
        };
    }

    private void whenExecutingCurrentTaskAndWaitingForIt() {
        testee.createExecutor("").execute(task);
        testee.waitForCurrentTasksDone();
    }

    private void whenExecutingAllTaskAndWaitingForIt() {
        testee.createExecutor("").execute(task);
        testee.waitForAllTasksDone();
    }

    private void thenOnlyFirstTaskShouldHaveExecuted() {
        assertTrue(task1HasExecuted.get(), "First task not executed.");
        assertFalse(task2HasExecuted.get(), "Second task already executed.");
    }

    private void thenBothTasksShouldHaveExecuted() {
        assertTrue(task1HasExecuted.get(), "First task not executed.");
        assertTrue(task2HasExecuted.get(), "Second task not executed.");
    }

    private void waitSomeTime() {
        try {
            Thread.sleep(THREAD_WAIT_TIME);
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

}
