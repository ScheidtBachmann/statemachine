/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2018 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.kicool.compilation

import de.cau.cs.kieler.kicool.compilation.Processor

/**
 * @author ssm
 * @kieler.design 2018-10-12 proposed
 * @kieler.rating 2018-10-12 proposed yellow
 */
abstract class ExogenousProcessor<S, T> extends Processor<S, T> {
    
    /**
     * Type of the processor.
     */
    override final def ProcessorType getType() {
        return ProcessorType.EXOGENOUS_TRANSFORMATOR
    }
        
}