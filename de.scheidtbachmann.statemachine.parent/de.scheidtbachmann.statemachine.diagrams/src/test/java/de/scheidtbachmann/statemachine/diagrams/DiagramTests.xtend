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
package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.Klighd
import de.cau.cs.kieler.klighd.standalone.KlighdStandaloneSetup
import java.io.PrintWriter
import java.io.StringWriter
import org.eclipse.core.runtime.IStatus

class DiagramTests {

    public static val init = [|KlighdStandaloneSetup.initialize() null].apply()

    static def getFailureTrace(IStatus status) {
        if (status?.exception === null)
            ""
        else {
            val buffer = new StringWriter()
            status.exception.printStackTrace(new PrintWriter(buffer))
            Klighd.LINE_SEPARATOR + buffer.toString
        }
    }
}
