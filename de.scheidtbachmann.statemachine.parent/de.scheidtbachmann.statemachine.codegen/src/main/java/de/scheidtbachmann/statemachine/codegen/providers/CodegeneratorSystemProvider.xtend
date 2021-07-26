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

package de.scheidtbachmann.statemachine.codegen.providers

import de.cau.cs.kieler.kicool.registration.ISystemProvider

/**
 * Provider to make processors available to KiCool.
 */
class CodegeneratorSystemProvider implements ISystemProvider {

    override getBundleId() {
        "de.scheidtbachmann.statemachine.codegen"
    }

    override getSystems() {
        #[
            "system/de.scheidtbachmann.codegen.statebased.lean.cpp.template.kico",
            "system/de.scheidtbachmann.codegen.statebased.lean.java.template.kico",
            "system/de.scheidtbachmann.codegen.statebased.lean.java.template.selective.kico"
        ]
    }
}
