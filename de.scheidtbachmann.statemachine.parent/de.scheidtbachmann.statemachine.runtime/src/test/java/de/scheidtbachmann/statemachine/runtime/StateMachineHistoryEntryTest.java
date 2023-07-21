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

package de.scheidtbachmann.statemachine.runtime;

import static org.assertj.core.api.BDDAssertions.then;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.UUID;

class StateMachineHistoryEntryTest {

    private static final String RANDOM_STRING = UUID.randomUUID().toString();

    private StateMachineHistoryEntry testee;

    private Object result;

    @Nested
    class StartState {

        @Test
        void testStartState_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenReceivingStartState();
            thenResultIsNull();
        }

        @Test
        void testStartState_SetShouldReturnValue() {
            givenTesteeHasBeenCreated();
            givenStartStateHasBeenSet();
            whenReceivingStartState();
            thenResultMatchesInputString();
        }

        private void givenStartStateHasBeenSet() {
            testee.setStartState(RANDOM_STRING);
        }

        private void whenReceivingStartState() {
            result = testee.getStartState();
        }

    }

    @Nested
    class Events {

        @Test
        void testEvents_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenReceivingEvents();
            thenResultIsNull();
        }

        @Test
        void testEvents_SetShouldReturnValue() {
            givenTesteeHasBeenCreated();
            givenEventsHaveBeenSet();
            whenReceivingEvents();
            thenResultMatchesInputString();
        }

        private void givenEventsHaveBeenSet() {
            testee.setEvents(RANDOM_STRING);
        }

        private void whenReceivingEvents() {
            result = testee.getEvents();
        }

    }

    @Nested
    class EndState {

        @Test
        void testEndState_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenReceivingEndState();
            thenResultIsNull();
        }

        @Test
        void testEndState_SetShouldReturnValue() {
            givenTesteeHasBeenCreated();
            givenEndStateHasBeenSet();
            whenReceivingEndState();
            thenResultMatchesInputString();
        }

        private void givenEndStateHasBeenSet() {
            testee.setEndState(RANDOM_STRING);
        }

        private void whenReceivingEndState() {
            result = testee.getEndState();
        }

    }

    @Nested
    class Throwable {

        private java.lang.Throwable inputThrowable;

        @Test
        void testThrowable_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenReceivingThrowable();
            thenResultIsNull();
        }

        @Test
        void testThrowable_SetShouldReturnValue() {
            givenTesteeHasBeenCreated();
            givenThrowableHasBeenSet();
            whenReceivingThrowable();
            thenResultMatchesInputThrowable();
        }

        private void givenThrowableHasBeenSet() {
            inputThrowable = new java.lang.Throwable(RANDOM_STRING);
            testee.setThrowable(inputThrowable);
        }

        private void whenReceivingThrowable() {
            result = testee.getThrowable();
        }

        private void thenResultMatchesInputThrowable() {
            then(result).isEqualTo(inputThrowable);
        }
    }

    @Nested
    class HashCodeAndEquals {

        private static final String RANDOM_START_STATE_1 = "RandomStartState1";
        private static final String RANDOM_START_STATE_2 = "RandomStartState2";
        private static final String RANDOM_EVENTS_1 = "RandomEvents1";
        private static final String RANDOM_EVENTS_2 = "RandomEvents2";
        private static final String RANDOM_END_STATE_1 = "RandomEndState1";
        private static final String RANDOM_END_STATE_2 = "RandomEndState2";
        private static final String RANDOM_THROWABLE_REASON_1 = "RandomThrowableReason1";
        private static final String RANDOM_THROWABLE_REASON_2 = "RandomThrowableReason2";

        private StateMachineHistoryEntry otherTestee;

        private int firstHashCode;
        private int secondHashCode;

        @Test
        void testSymmetry() {
            givenTwoTesteesAreCreated();
            givenStartStateIsSetToSameValue();
            givenEventsAreSetToSameInput();
            givenEndStateIsSetToSameInput();
            givenThrowableIsSetToSameInput();
            whenReceivingHashCodes();
            thenHashCodesAreEqual();
            thenTesteesAreSymmetric();
        }

        @Test
        void testIdentity() {
            givenTesteeHasBeenCreated();
            givenSameTesteeTwice();
            thenTesteesAreSymmetric();
        }

        @Test
        void testUnequal_AllDifferent() {
            givenTwoTesteesAreCreated();
            givenStartStateIsSetToDifferentValues();
            givenEventsAreSetToDifferentValues();
            givenEndStateIsSetToDifferentValues();
            givenThrowablesAreSetToDifferentValues();
            whenReceivingHashCodes();
            thenHashCodesAreNotEqual();
            thenTesteesAreNotEqual();
        }

        @Test
        void testUnequal_Null() {
            givenTesteeHasBeenCreated();
            givenNullAsSecondTestee();
            thenTesteesAreNotEqual();
        }

        @Test
        void testUnequal_OtherClass() {
            givenTesteeHasBeenCreated();
            final String otherObject = "RandomString";
            then(testee).isNotEqualTo(otherObject);
        }

        private void givenNullAsSecondTestee() {
            otherTestee = null;
        }

        private void givenSameTesteeTwice() {
            otherTestee = testee;
        }

        private void givenTwoTesteesAreCreated() {
            testee = new StateMachineHistoryEntry();
            otherTestee = new StateMachineHistoryEntry();
        }

        private void givenStartStateIsSetToSameValue() {
            testee.setStartState(RANDOM_START_STATE_1);
            otherTestee.setStartState(RANDOM_START_STATE_1);
        }

        private void givenStartStateIsSetToDifferentValues() {
            testee.setStartState(RANDOM_START_STATE_1);
            otherTestee.setStartState(RANDOM_START_STATE_2);
        }

        private void givenEventsAreSetToSameInput() {
            testee.setEvents(RANDOM_EVENTS_1);
            otherTestee.setEvents(RANDOM_EVENTS_1);
        }

        private void givenEventsAreSetToDifferentValues() {
            testee.setEvents(RANDOM_EVENTS_1);
            otherTestee.setEvents(RANDOM_EVENTS_2);
        }

        private void givenEndStateIsSetToSameInput() {
            testee.setEndState(RANDOM_END_STATE_1);
            otherTestee.setEndState(RANDOM_END_STATE_1);
        }

        private void givenEndStateIsSetToDifferentValues() {
            testee.setEndState(RANDOM_END_STATE_1);
            otherTestee.setEndState(RANDOM_END_STATE_2);
        }

        private void givenThrowableIsSetToSameInput() {
            final java.lang.Throwable inputThrowable = new java.lang.Throwable(RANDOM_THROWABLE_REASON_1);
            testee.setThrowable(inputThrowable);
            otherTestee.setThrowable(inputThrowable);
        }

        private void givenThrowablesAreSetToDifferentValues() {
            testee.setThrowable(new java.lang.Throwable(RANDOM_THROWABLE_REASON_1));
            otherTestee.setThrowable(new java.lang.Throwable(RANDOM_THROWABLE_REASON_2));
        }

        private void whenReceivingHashCodes() {
            firstHashCode = testee.hashCode();
            secondHashCode = otherTestee.hashCode();
        }

        private void thenHashCodesAreEqual() {
            then(firstHashCode).isEqualTo(secondHashCode);
        }

        private void thenHashCodesAreNotEqual() {
            then(firstHashCode).isNotEqualTo(secondHashCode);
        }

        private void thenTesteesAreSymmetric() {
            then(testee).isEqualTo(otherTestee);
            then(otherTestee).isEqualTo(testee);
        }

        private void thenTesteesAreNotEqual() {
            then(testee).isNotEqualTo(otherTestee);
        }
    }

    @Nested
    class ToString {

        @Test
        void testToString_ShouldContainAllValues() {
            givenTesteeHasBeenCreated();
            whenReceivingStringRepresentation();
            thenResultContainsAllFields();
        }

        private void thenResultContainsAllFields() {
            then(result).asString().contains("startState=");
            then(result).asString().contains("events=");
            then(result).asString().contains("endState=");
            then(result).asString().contains("throwable=");
        }

        private void whenReceivingStringRepresentation() {
            result = testee.toString();
        }

    }

    private void givenTesteeHasBeenCreated() {
        testee = new StateMachineHistoryEntry();
    }

    private void thenResultIsNull() {
        then(result).isNull();
    }

    private void thenResultMatchesInputString() {
        then(result).asString().isEqualTo(RANDOM_STRING);
    }
}
