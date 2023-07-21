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

import static org.assertj.core.api.BDDAssertions.catchThrowable;
import static org.assertj.core.api.BDDAssertions.then;

import org.junit.jupiter.api.Test;

import java.util.List;

class StateMachineStateContainerTest {

    private StateMachineRootContext inputContext;
    private StateMachineStateContainer testee;
    private String result;
    private Object exceptionThrown;

    @Test
    void testStringGeneration_NullAsContextShouldThrowNullPointer() {
        givenNullAsContext();
        givenTesteeHasBeenCreated();
        whenBuildingString();
        thenExceptionIsThrownOfType(NullPointerException.class);
    }

    @Test
    void testStringGeneration_SingleStateShouldReturn() {
        givenStatesInContext(List.of("State"));
        givenTesteeHasBeenCreated();
        whenBuildingString();
        thenNoExceptionIsThrown();
        thenResultingStringMatches("State");
    }

    @Test
    void testStringGeneration_DuplicateStatesShouldBeFiltered() {
        givenStatesInContext(List.of("State", "State"));
        givenTesteeHasBeenCreated();
        whenBuildingString();
        thenNoExceptionIsThrown();
        thenResultingStringMatches("State");
    }

    @Test
    void testStringGeneration_MultipleStatesShouldBeCombined() {
        givenStatesInContext(List.of("State", "OtherState"));
        givenTesteeHasBeenCreated();
        whenBuildingString();
        thenNoExceptionIsThrown();
        thenResultingStringMatches("State,OtherState");
    }

    @Test
    void testStringGeneration_MultipleStatesWithDuplicateShouldBeCombinedAndFiltered() {
        givenStatesInContext(List.of("State", "OtherState", "State"));
        givenTesteeHasBeenCreated();
        whenBuildingString();
        thenNoExceptionIsThrown();
        thenResultingStringMatches("State,OtherState");
    }

    private void givenStatesInContext(final List<String> states) {
        inputContext = () -> states.stream();
    }

    private void givenNullAsContext() {
        inputContext = null;
    }

    private void givenTesteeHasBeenCreated() {
        testee = new StateMachineStateContainer(inputContext);
    }

    private void whenBuildingString() {
        exceptionThrown = catchThrowable(() -> result = testee.toString());
    }

    private void thenExceptionIsThrownOfType(final Class<? extends Throwable> expectedClazz) {
        then(exceptionThrown).isInstanceOf(expectedClazz);
    }

    private void thenNoExceptionIsThrown() {
        then(exceptionThrown).isNull();
    }

    private void thenResultingStringMatches(final String expectedString) {
        then(result).isEqualTo(expectedString);
    }
}
