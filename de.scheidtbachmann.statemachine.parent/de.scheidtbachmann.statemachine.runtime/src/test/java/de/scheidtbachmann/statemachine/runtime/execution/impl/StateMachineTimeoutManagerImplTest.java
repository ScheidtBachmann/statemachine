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

import static org.assertj.core.api.BDDAssertions.catchThrowable;
import static org.assertj.core.api.BDDAssertions.then;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.BDDMockito;
import org.mockito.Mock;
import org.mockito.Mock.Strictness;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

@ExtendWith(MockitoExtension.class)
class StateMachineTimeoutManagerImplTest {

    private static final Duration DEFAULT_DELAY = Duration.ofMillis(20);

    private StateMachineTimeoutManagerImpl testee;

    @Mock(strictness = Strictness.LENIENT)
    private ScheduledExecutorService executorServiceMock;
    @Mock(strictness = Strictness.LENIENT)
    private ScheduledFuture<?> scheduledFutureMock;

    private final AtomicBoolean taskIsRunning = new AtomicBoolean(false);

    @BeforeEach
    void setupExecutorAndFuture() {
        givenExecutorCanScheduleTasks();
        givenTaskReactsToCancellation();
    }

    @Nested
    class InstanceCreation {

        @Test
        void testCreation_AutostartTrueShouldSchedule() {
            whenCreatingTesteeWithAutostartSetTo(true);
            thenTaskHasBeenScheduled();
        }

        @Test
        void testCreation_AutostartFalseShouldNotSchedule() {
            whenCreatingTesteeWithAutostartSetTo(false);
            thenTaskHasNotBeenScheduled();
        }

        private void whenCreatingTesteeWithAutostartSetTo(final boolean autoStart) {
            testee = new StateMachineTimeoutManagerImpl(executorServiceMock, DEFAULT_DELAY.toMillis(),
                TimeUnit.MILLISECONDS, null, autoStart);
        }
    }

    @Nested
    class IsRunning {

        private boolean result;

        @Test
        void testIsRunningShouldBeTrueAfterAutostart() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, true);
            whenCheckingWhetherTaskIsRunning();
            thenTaskShouldBeRunning();
        }

        @Test
        void testIsRunningShouldBeFalseWithoutAutostart() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, false);
            whenCheckingWhetherTaskIsRunning();
            thenTaskShouldNotBeRunning();
        }

        @Test
        void testIsRunningShouldBeFalseWhenTaskIsDone() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, true);
            givenTaskIsDone();
            whenCheckingWhetherTaskIsRunning();
            thenTaskShouldNotBeRunning();
        }

        private void givenTaskIsDone() {
            given(scheduledFutureMock.isDone()).willReturn(true);
        }

        private void whenCheckingWhetherTaskIsRunning() {
            result = testee.isRunning();
        }

        private void thenTaskShouldNotBeRunning() {
            then(result).isFalse();
        }

        private void thenTaskShouldBeRunning() {
            then(result).isTrue();
        }
    }

    @Nested
    class Start {

        @Test
        void testStart_StartOnAutostartShouldDoNothing() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, true);
            whenStartingTask();
            thenTaskHasBeenScheduled();
        }

        @Test
        void testStart_StartOnUnstartedShouldBeRunning() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, false);
            whenStartingTask();
            thenTaskHasBeenScheduled();
        }

        private void whenStartingTask() {
            testee.start();
        }
    }

    @Nested
    class Cancel {

        @Test
        void testCancel_ShouldStopRunningTask() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, true);
            whenCancellingTask();
            thenTaskHasBeenCancelled();
        }

        @Test
        void testCancel_ShouldDoNothingWithStoppedTask() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, false);
            whenCancellingTask();
            thenTaskHasNotBeenCancelled();
        }

        private void whenCancellingTask() {
            testee.cancel();
        }

    }

    @Nested
    class Restart {

        @Test
        void testRestart_ShouldStartNonRunningTask() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, false);
            whenRestartingTask();
            thenTaskHasNotBeenCancelled();
            thenTaskHasBeenScheduled();
        }

        @Test
        void testRestart_ShouldCancelAndStartRunningTask() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(null, true);
            whenRestartingTask();
            thenTaskHasBeenCancelled();
            thenTaskHasBeenScheduledTwice();
        }

        private void whenRestartingTask() {
            testee.restart();
        }
    }

    @Nested
    class Execution {

        private final AtomicBoolean taskHasStarted = new AtomicBoolean(false);
        private final AtomicBoolean taskHasFinished = new AtomicBoolean(false);
        private final Runnable nonThrowingTask = () -> {
            taskHasStarted.set(true);
            taskHasFinished.set(true);
        };
        private final Runnable throwingTask = () -> {
            taskHasStarted.set(true);
            throw new IllegalArgumentException();
        };

        private Object exceptionThrown;

        @Test
        void testExecution_ShouldRunPassedAction() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(nonThrowingTask, true);
            whenRunningScheduledTask();
            thenNoExceptionIsThrown();
            thenPassedTaskIsStarted();
            thenPassedTaskIsFinished();
        }

        @Test
        void testExecution_ThrowingTaskShouldNotThrowBack() {
            givenTesteeHasBeenCreatedWithTaskAndAutostart(throwingTask, true);
            whenRunningScheduledTask();
            thenNoExceptionIsThrown();
            thenPassedTaskIsStarted();
            thenPassedTaskIsNotFinished();
        }

        private void thenPassedTaskIsStarted() {
            then(taskHasStarted.get()).isTrue();
        }

        private void thenPassedTaskIsFinished() {
            then(taskHasFinished.get()).isTrue();
        }

        private void thenPassedTaskIsNotFinished() {
            then(taskHasFinished.get()).isFalse();
        }

        private void whenRunningScheduledTask() {
            exceptionThrown = catchThrowable(() -> taskRunnable.run());
        }

        private void thenNoExceptionIsThrown() {
            then(exceptionThrown).isNull();
        }
    }

    private Runnable taskRunnable;

    private void givenExecutorCanScheduleTasks() {
        doAnswer(invocation -> {
            taskRunnable = invocation.getArgument(0);
            taskIsRunning.set(true);
            return scheduledFutureMock;
        }).when(executorServiceMock).schedule(any(Runnable.class), anyLong(), any(TimeUnit.class));
    }

    private void givenTaskReactsToCancellation() {
        given(scheduledFutureMock.isDone()).willAnswer(invocations -> {
            final boolean running = taskIsRunning.get();
            return !running;
        });
        given(scheduledFutureMock.cancel(anyBoolean())).will(invocation -> {
            taskIsRunning.set(false);
            return null;
        });
    }

    private void givenTesteeHasBeenCreatedWithTaskAndAutostart(final Runnable task, final boolean autoStart) {
        testee = new StateMachineTimeoutManagerImpl(executorServiceMock, DEFAULT_DELAY.toMillis(),
            TimeUnit.MILLISECONDS, task, autoStart);
    }

    private void thenTaskHasNotBeenScheduled() {
        BDDMockito.then(executorServiceMock).should(never()).schedule(any(Runnable.class), eq(DEFAULT_DELAY.toMillis()),
            eq(TimeUnit.MILLISECONDS));
    }

    private void thenTaskHasBeenScheduled() {
        BDDMockito.then(executorServiceMock).should().schedule(any(Runnable.class), eq(DEFAULT_DELAY.toMillis()),
            eq(TimeUnit.MILLISECONDS));
    }

    private void thenTaskHasBeenScheduledTwice() {
        BDDMockito.then(executorServiceMock).should(times(2)).schedule(any(Runnable.class),
            eq(DEFAULT_DELAY.toMillis()), eq(TimeUnit.MILLISECONDS));
    }

    private void thenTaskHasNotBeenCancelled() {
        BDDMockito.then(scheduledFutureMock).should(never()).cancel(anyBoolean());
    }

    private void thenTaskHasBeenCancelled() {
        BDDMockito.then(scheduledFutureMock).should().cancel(anyBoolean());
    }
}
