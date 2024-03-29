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

import de.cau.cs.kieler.kicool.registration.IProcessorProvider

/**
 * Provider to make code generators available to KiCool.
 */
class CodegeneratorProcessorProvider implements IProcessorProvider {

    override getProcessors() {
        #[
            de.scheidtbachmann.statemachine.transformators.ModelSelect,
            de.scheidtbachmann.statemachine.transformators.StateOriginMarker,            
            de.scheidtbachmann.statemachine.codegen.lean.cpp.StatebasedLeanCppCodeGenerator,
            de.scheidtbachmann.statemachine.codegen.lean.java.StatebasedLeanJavaCodeGenerator
        ]
    }
}
