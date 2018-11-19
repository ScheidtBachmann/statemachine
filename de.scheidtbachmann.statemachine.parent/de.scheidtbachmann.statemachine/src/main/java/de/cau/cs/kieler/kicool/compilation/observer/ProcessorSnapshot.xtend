/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2017 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.kicool.compilation.observer

import de.cau.cs.kieler.kicool.compilation.CompilationContext
import org.eclipse.xtend.lib.annotations.Accessors
import de.cau.cs.kieler.kicool.ProcessorReference
import de.cau.cs.kieler.kicool.compilation.Processor

/**
 * Notification class for the processor snapshot event.
 * 
 * @author ssm
 * @kieler.design 2017-02-24 proposed
 * @kieler.rating 2017-02-24 proposed yellow 
 */
class ProcessorSnapshot extends AbstractProcessorNotification {
    
    @Accessors Object snapshot
    
    new(Object snapshot, CompilationContext compilationContext, ProcessorReference processorReference, Processor<?,?> processorInstance) {
        super(compilationContext, processorReference, processorInstance)
        this.snapshot = snapshot
    }
    
}