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

import java.util.Iterator;
import java.util.List;

/**
 * Possible file endings to use for the image export.
 */
public class FormatCandidates implements Iterable<String> {

    private static final List<String> KNOWN_FORMATS = List.of("bmp", "jpeg", "png", "svg");

    @Override
    public Iterator<String> iterator() {
        return KNOWN_FORMATS.iterator();
    }
}
