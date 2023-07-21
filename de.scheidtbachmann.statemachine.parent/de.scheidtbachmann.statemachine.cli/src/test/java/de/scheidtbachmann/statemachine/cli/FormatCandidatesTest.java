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

package de.scheidtbachmann.statemachine.cli;

import org.assertj.core.api.BDDAssertions;
import org.junit.jupiter.api.Test;

import java.util.LinkedList;
import java.util.List;

class FormatCandidatesTest {

    private final FormatCandidates testee = new FormatCandidates();

    @Test
    void testIteratorContainsExactData() {

        final List<String> result = new LinkedList<>();
        for (final String element : testee) {
            result.add(element);
        }

        BDDAssertions.then(result).containsExactlyElementsOf(EXPECTED_FORMATS);
    }

    private static final List<String> EXPECTED_FORMATS = List.of("bmp", "jpeg", "png", "svg");

}
