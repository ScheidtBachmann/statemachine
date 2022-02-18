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

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.concurrent.atomic.AtomicBoolean;

public class StateMachineTestExecutionFactoryTest {

    private static final int THREAD_WAIT_TIME = 2000;

    private final StateMachineTestExecutionFactory testee = new StateMachineTestExecutionFactory();

    private Runnable task;

    private final AtomicBoolean task1HasExecuted = new AtomicBoolean(false);
    private final AtomicBoolean task2HasExecuted = new AtomicBoolean(false);

    @Test
    public void testWaitForCurrentTasksDone() {
        givenTaskSchedulesAnotherTask();
        whenExecutingCurrentTaskAndWaitingForIt();
        thenOnlyFirstTaskShouldHaveExecuted();
    }

    @Test
    public void testWaitForAllTasksDone() {
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
        assertTrue("First task not executed.", task1HasExecuted.get());
        assertFalse("Second task already executed.", task2HasExecuted.get());
    }

    private void thenBothTasksShouldHaveExecuted() {
        assertTrue("First task not executed.", task1HasExecuted.get());
        assertTrue("Second task not executed.", task2HasExecuted.get());
    }

    private void waitSomeTime() {
        try {
            Thread.sleep(THREAD_WAIT_TIME);
        } catch (final InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

}
