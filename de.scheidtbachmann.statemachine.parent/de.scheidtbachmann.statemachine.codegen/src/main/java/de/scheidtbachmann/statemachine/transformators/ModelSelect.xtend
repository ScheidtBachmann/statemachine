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

package de.scheidtbachmann.statemachine.transformators

import de.cau.cs.kieler.core.properties.IProperty
import de.cau.cs.kieler.core.properties.Property
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor

/**
 * Processor to select one model from a file containing multiple models at the same time.
 */
class ModelSelect extends SCChartsProcessor {

    public static val IProperty<String> SELECTED_MODEL =
       new Property<String>("de.scheidtbachmann.statemachine.modelselect.name", "")

    override getId() {
        "de.scheidtbachmann.statemachine.processors.modelselect"
    }

    override getName() {
        "Model Selector"
    }

    override process() {
        if (!environment.getProperty(SELECTED_MODEL).nullOrEmpty) {
            val allowedModels = environment.getProperty(SELECTED_MODEL).split(",");
            val model = getModel()
            model.rootStates.removeIf[root | !allowedModels.exists[allowed | allowed.equals(root.name)]]
        }
    }
}
