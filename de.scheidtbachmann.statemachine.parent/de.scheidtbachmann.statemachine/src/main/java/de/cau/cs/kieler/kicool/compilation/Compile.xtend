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
package de.cau.cs.kieler.kicool.compilation

import de.cau.cs.kieler.kicool.System
import de.cau.cs.kieler.kicool.registration.KiCoolRegistration
import java.util.List

import static com.google.common.base.Preconditions.*
import static extension de.cau.cs.kieler.kicool.compilation.internal.ContextPopulation.*
import static extension de.cau.cs.kieler.kicool.compilation.internal.SystemTransformation.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import de.cau.cs.kieler.kicool.KiCoolFactory
import de.cau.cs.kieler.kicool.ProcessorGroup
import de.cau.cs.kieler.kicool.compilation.internal.EnvironmentPropertyHolder

/**
 * Class for preparing compilations programmatically through creating compilation contexts. 
 * The context itself then has a method to invoke the compilation.
 * 
 * @author ssm
 * @kieler.design 2017-02-19 proposed
 * @kieler.rating 2017-02-19 proposed yellow  
 */
class Compile {
    
    /**
     * Easily create a standard compilation context from a compilation system and a source model.
     */
    static def CompilationContext createCompilationContext(System system, Object sourceModel) {
        checkNotNull(system, "System is null")
        checkNotNull(sourceModel, "Source model is null")
        val context = KiCoolRegistration.getInjector.getInstance(CompilationContext)
        context => [
            it.originalSystem = system
            it.transformSystem
            it.originalModel = sourceModel
            it.populateContext
            // configure start environment
            for (subSystem : subContexts.values.map[originalSystem]) {
                EnvironmentPropertyHolder.processEnvironmentConfig(it.startEnvironment, subSystem.config)
            }
            EnvironmentPropertyHolder.processEnvironmentConfig(it.startEnvironment, system.config)
//            RuntimeSystems.add(it.getSystem, it)
        ]
    }
    
    /**
     * Create a compilation context from a system id and a source model.
     */
    static def CompilationContext createCompilationContext(String systemID, Object sourceModel) {
        createCompilationContext(KiCoolRegistration.getSystemById(systemID), sourceModel)
    }

    /**
     * Create a compilation context from a system id and a source model and additional processors
     */
    static def CompilationContext createCompilationContext(String systemID, Object sourceModel, List<String> additionalProcessors) {
        val system = KiCoolRegistration.getSystemById(systemID).copy => [
            for (processorId : additionalProcessors) {
                val entry = KiCoolFactory.eINSTANCE.createProcessorReference => [
                    it.id = processorId
                ]
                switch(processors) {
                    ProcessorGroup: (processors as ProcessorGroup).processors += entry
                }
                
            }
        ]
        createCompilationContext(system, sourceModel)
    }
    
    
    /**
     * Start a compilation in an asynchronous job.
     */
    static def asyncronousCompilation(CompilationContext compilationContext) {
        // chsch: deactivated because of dependency to 'org.eclipse.core.runtime'
        throw new UnsupportedOperationException('asynchronous compilation is currently not supported')
        // AsynchronousCompilation.compile(compilationContext)
         
    }
    
    static def addToRuntimeSystems(CompilationContext context) {
        RuntimeSystems.add(context.getSystem, context)        
    }
    
    static def removeFromRuntimeSystems(CompilationContext context) {
        RuntimeSystems.remove(context.getSystem)
    }
}