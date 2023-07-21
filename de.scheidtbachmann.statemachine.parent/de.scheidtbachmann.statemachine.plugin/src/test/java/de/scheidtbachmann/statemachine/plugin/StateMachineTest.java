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

package de.scheidtbachmann.statemachine.plugin;

import static org.assertj.core.api.BDDAssertions.then;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.UUID;

class StateMachineTest {

    private static final String RANDOM_TEXT = UUID.randomUUID().toString();

    private StateMachine testee;
    private Object result;

    @Nested
    class FileName {

        @Test
        void testFileName_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenRetrievingFileName();
            thenResultIsNull();
        }

        @Test
        void testFileName_SetShouldReturnPreviousValue() {
            givenTesteeHasBeenCreated();
            givenFileNameHasBeenSet();
            whenRetrievingFileName();
            thenResultMatchesInput();
        }

        private void givenFileNameHasBeenSet() {
            testee.setFileName(RANDOM_TEXT);
        }

        private void whenRetrievingFileName() {
            result = testee.getFileName();
        }
    }

    @Nested
    class OutputFolder {

        private static final String DEFAULT_FOLDER = "sm-gen";

        @Test
        void testOutputFolder_UnsetShouldReturnDefault() {
            givenTesteeHasBeenCreated();
            whenRetrievingOutputFolder();
            thenResultMatchesDefaultFolder();
        }

        @Test
        void testOutputFolder_SetShouldReturnPreviousValue() {
            givenTesteeHasBeenCreated();
            givenOutputFolderHasBeenSet();
            whenRetrievingOutputFolder();
            thenResultMatchesInput();
        }

        private void givenOutputFolderHasBeenSet() {
            testee.setOutputFolder(RANDOM_TEXT);
        }

        private void whenRetrievingOutputFolder() {
            result = testee.getOutputFolder();
        }

        private void thenResultMatchesDefaultFolder() {
            then(result).asString().isEqualTo(DEFAULT_FOLDER);
        }
    }

    @Nested
    class Strategy {

        private static final String DEFAULT_STRATEGY = "de.cau.cs.kieler.sccharts.statebased";

        @Test
        void testStrategy_UnsetShouldReturnDefault() {
            givenTesteeHasBeenCreated();
            whenRetrievingStrategy();
            thenResultMatchesDefaultStrategy();
        }

        @Test
        void testStrategy_SetShouldReturnPreviousValue() {
            givenTesteeHasBeenCreated();
            givenStrategyHasBeenSet();
            whenRetrievingStrategy();
            thenResultMatchesInput();
        }

        private void givenStrategyHasBeenSet() {
            testee.setStrategy(RANDOM_TEXT);
        }

        private void whenRetrievingStrategy() {
            result = testee.getStrategy();
        }

        private void thenResultMatchesDefaultStrategy() {
            then(result).asString().isEqualTo(DEFAULT_STRATEGY);
        }
    }

    @Nested
    class SelectedModel {

        @Test
        void testSelectedModel_UnsetShouldReturnNull() {
            givenTesteeHasBeenCreated();
            whenRetrievingSelectedModel();
            thenResultIsNull();
        }

        @Test
        void testSelectedModel_SetShouldReturnPreviousValue() {
            givenTesteeHasBeenCreated();
            givenSelectedModelHasBeenSet();
            whenRetrievingSelectedModel();
            thenResultMatchesInput();
        }

        private void givenSelectedModelHasBeenSet() {
            testee.setSelectedModel(RANDOM_TEXT);
        }

        private void whenRetrievingSelectedModel() {
            result = testee.getSelectedModel();
        }
    }

    @Nested
    class ToString {

        @Test
        void testToString_ContainsAllAttributes() {
            givenTesteeHasBeenCreated();
            whenRetrievingStringRepresentation();
            thenAllAttributesAreContainedInResult();
        }

        private void whenRetrievingStringRepresentation() {
            result = testee.toString();
        }

        private void thenAllAttributesAreContainedInResult() {
            then(result).asString().contains("fileName");
            then(result).asString().contains("outputFolder");
            then(result).asString().contains("strategy");
            then(result).asString().contains("selectedModel");
        }
    }

    private void givenTesteeHasBeenCreated() {
        testee = new StateMachine();
    }

    private void thenResultIsNull() {
        then(result).isNull();
    }

    private void thenResultMatchesInput() {
        then(result).asString().isEqualTo(RANDOM_TEXT);
    }

}