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

import com.google.inject.Injector;
import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup;
import picocli.CommandLine;

import java.nio.file.Path;

public class TestableGenerator extends Generator {

    private static final Injector INJECTOR = new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration();

    private final Path basePath;

    public TestableGenerator(final Path basePath) {
        this.basePath = basePath;
        setAnsi(CommandLine.Help.Ansi.OFF);
        INJECTOR.injectMembers(this);
    }

    @Override
    Path getBasePath() {
        return basePath;
    }
}
