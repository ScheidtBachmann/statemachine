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

import de.cau.cs.kieler.kicool.registration.KiCoolRegistration;

import java.util.Iterator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Possible strategies registered in compilation system.
 * Mainly used for listing all strategies in the help text.
 */
public class StrategyCandidates implements Iterable<String> {

    // Request all known compilation systems from KiCool and store in a nice sorted list
    private static final List<String> SORTED_IDS = KiCoolRegistration.getSystemModels().stream()
        .map(de.cau.cs.kieler.kicool.System::getId).sorted().collect(Collectors.toUnmodifiableList());

    @Override
    public Iterator<String> iterator() {
        final Stream<String> idsWithLinebreaks =
            SORTED_IDS.stream().limit((long) SORTED_IDS.size() - 1).map(input -> "%n  " + input);
        final String lastLine =
            "%n  " + SORTED_IDS.get(SORTED_IDS.size() - 1) + ", %n  or a path to a custom <.kico> file";

        return Stream.concat(idsWithLinebreaks, Stream.of(lastLine)).iterator();
    }

}
