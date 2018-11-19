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

import com.google.inject.Inject
import de.cau.cs.kieler.kicool.ProcessorAlternativeGroup
import de.cau.cs.kieler.kicool.ProcessorGroup
import de.cau.cs.kieler.kicool.ProcessorReference
import de.cau.cs.kieler.kicool.ProcessorSystem
import de.cau.cs.kieler.kicool.classes.IKiCoolCloneable
import de.cau.cs.kieler.kicool.compilation.observer.CompilationFinished
import de.cau.cs.kieler.kicool.compilation.observer.CompilationStart
import de.cau.cs.kieler.kicool.compilation.observer.ProcessorError
import de.cau.cs.kieler.kicool.compilation.observer.ProcessorFinished
import de.cau.cs.kieler.kicool.compilation.observer.ProcessorStart
import de.cau.cs.kieler.kicool.environments.Environment
import de.cau.cs.kieler.kicool.kitt.tracing.internal.TracingIntegration
import java.util.List
import java.util.Map
import java.util.Observable
import java.util.Observer
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Accessors
import de.cau.cs.kieler.core.model.properties.IProperty

import static de.cau.cs.kieler.kicool.environments.Environment.*

import static extension de.cau.cs.kieler.kicool.compilation.internal.EnvironmentPropertyHolder.*
import static extension de.cau.cs.kieler.kicool.compilation.internal.UniqueNameCachePopulation.populateNameCache
import static extension de.cau.cs.kieler.kicool.kitt.tracing.internal.TracingIntegration.addTracingProperty
import static extension de.cau.cs.kieler.kicool.kitt.tracing.internal.TracingIntegration.isTracingActive
import static extension de.cau.cs.kieler.kicool.compilation.internal.ContextPopulation.*
import de.cau.cs.kieler.kicool.ProcessorEntry
import de.cau.cs.kieler.kicool.KiCoolFactory
import de.cau.cs.kieler.kicool.compilation.observer.CompilationChanged
import de.cau.cs.kieler.kicool.compilation.observer.AbstractContextNotification
import de.cau.cs.kieler.kicool.environments.UniqueClonableNameCache

/**
 * A compilation context is the central compilation unit. Once you prepared a context, you can
 * invoke the whole compilation process with {@code compile}. The context is an observable and 
 * you can register observers for various events such as compilation/processor start and finish
 * events. 
 * You can create contexts conveniently with the {@link Compile} class. It provides various 
 * static methods for context creation.
 * 
 * @author ssm
 * @kieler.design 2017-02-19 proposed
 * @kieler.rating 2017-02-19 proposed yellow  
 */
class CompilationContext extends Observable implements IKiCoolCloneable {

    /** The compilation system that will be used and worked on. */    
    @Accessors de.cau.cs.kieler.kicool.System system
    /** The original compilation system. Do not change this one! */
    @Accessors de.cau.cs.kieler.kicool.System originalSystem
    /** The mapping between original system and working copy. */
    @Accessors Map<ProcessorEntry, ProcessorEntry> systemMap
    @Accessors(PUBLIC_GETTER) Object originalModel
    /** Maps processor references in the system to processor instances. */
    @Accessors(PUBLIC_GETTER) Map<ProcessorReference, Processor<?,?>> processorMap
    /** The ordered list of all processor instances of this context */
    @Accessors(PUBLIC_GETTER) List<Processor<?,?>> processorInstancesSequence 
    @Accessors Map<ProcessorSystem, CompilationContext> subContexts
    @Accessors CompilationContext parentContext = null
    /** The environment that will be prepared at startup before compilation. */
    @Accessors(PUBLIC_GETTER) Environment startEnvironment
    /** A reference to the target environment of the last processor to enable quick access. */
    @Accessors(PUBLIC_GETTER) Environment result
    /** Recording of the notifications if enabled. */
    @Accessors(PUBLIC_GETTER) List<AbstractContextNotification> notifications
    
    new() {
        systemMap = <ProcessorEntry, ProcessorEntry> newHashMap
        processorMap = <ProcessorReference, Processor<?,?>> newLinkedHashMap
        processorInstancesSequence = <Processor<?,?>> newArrayList
        subContexts = <ProcessorSystem, CompilationContext> newLinkedHashMap
        notifications = <AbstractContextNotification> newLinkedList
        
        // This is the default start configuration.
        startEnvironment = new Environment
        startEnvironment.setProperty(COMPILATION_CONTEXT, this)
        startEnvironment.setProperty(INPLACE, false)        
        startEnvironment.setProperty(ONGOING_WORKING_COPY, false)
        startEnvironment.setProperty(ORIGINAL_MODEL, null)
        startEnvironment.setProperty(UNIQUE_NAME_CACHE_ENABLED, true)
        startEnvironment.setProperty(UNIQUE_NAME_CACHE, new UniqueClonableNameCache)
        
        result = null
    }
    
    /** Invoke this method if you want to compile asynchronously. */
    def void compileAsynchronously() {
        Compile.asyncronousCompilation(this)
    }
    
    /** Invoke the compilation process. */
    def Environment compile() {
        startEnvironment.addTracingProperty
        
        val modelCopy = if (originalModel instanceof EObject) {
            TracingIntegration.copy((originalModel as EObject), startEnvironment)
        } else {
            originalModel
        }
        startEnvironment.setProperty(MODEL, modelCopy)
        
        if (startEnvironment.getProperty(UNIQUE_NAME_CACHE_ENABLED)) {
            originalModel.populateNameCache(startEnvironment.getProperty(UNIQUE_NAME_CACHE))
        }
        
        for(intermediateProcessor : getIntermediateProcessors) {
            intermediateProcessor.setEnvironment(startEnvironment, startEnvironment)
            if (intermediateProcessor.validateInputType) {
                if (intermediateProcessor instanceof Metric<?,?>) {
                    intermediateProcessor.setMetricSourceEntity
                    intermediateProcessor.process
                }
            }
        }
        
        result = startEnvironment.compile
        result        
    }
    
    /** Takes the first processor entry and proceeds the compilation with the given environment. */
    // Protected is important. Should not be accessible from the outside.
    protected def Environment compile(Environment environment) {
        val processorEntry = system.processors
        
        notify(new CompilationStart(this))
        val EPrime = processorEntry.compileEntry(environment)
        notify(new CompilationFinished(this, EPrime))

        result = EPrime              
        EPrime  
    }
    
    /** Prepares the environments of the given processor reference and invoke the processor's process. */
    protected dispatch def Environment compileEntry(ProcessorReference processorReference, Environment environment) {
        val processorInstance = processorMap.get(processorReference)
        environment.setProperty(PROCESSOR_REFERENCE, processorReference)
        environment.setProperty(PROCESSOR_INSTANCE, processorInstance)
        if (processorInstance === null) {
            notify(new ProcessorError("An instance for processor reference " + processorReference + " was not found!", 
                this, processorReference, null))
            System.err.println("An instance for processor reference " + processorReference + " was not found!")
            return environment    
        }
        
        // Set environment information that come from the outside, e.g. the system.
        environment.processEnvironmentConfig(processorReference.preconfig)
        
        val environmentPrime = environment.preparePrimeEnvironment
        
        processorInstance.setEnvironment(environment, environmentPrime)
        
        notify(new ProcessorStart(this, processorReference, processorInstance))
        
        for (intermediateProcessor : getIntermediateProcessors(processorReference)) {
            intermediateProcessor.setEnvironment(environment, environmentPrime)
            if (intermediateProcessor.validateInputType) intermediateProcessor.processBefore
        }
        
        
        val startTimestamp = System.nanoTime
        environmentPrime.setProperty(START_TIMESTAMP, startTimestamp)
        
        processorInstance.executeCoProcessors(processorReference.preprocesses, false)
        
        try {
            if (processorInstance.sourceEnvironment.getProperty(ENABLED)) { 
                processorInstance.process
            }
        } catch (Exception e) {
            processorInstance.environment.errors.add(e)
            notify(new ProcessorError(e.message, this, processorReference, processorInstance))
            System.err.println("Error in processor " + processorReference)
            e.printStackTrace
        }

        processorInstance.executeCoProcessors(processorReference.postprocesses, true)
        
        val stopTimestamp = System.nanoTime
        environmentPrime.setProperty(STOP_TIMESTAMP, stopTimestamp)
        environmentPrime.setProperty(PTIME, (stopTimestamp - startTimestamp) / 1000_000)
        
        for (intermediateProcessor : getIntermediateProcessors(processorReference)) {
            intermediateProcessor.setEnvironment(environmentPrime, environmentPrime)
            if (intermediateProcessor.validateInputType) intermediateProcessor.process
        }
        
        val overallTimestamp = System.nanoTime
        environmentPrime.setProperty(OVERALL_TIMESTAMP, overallTimestamp)
        environmentPrime.setProperty(OVERALL_PTIME, (overallTimestamp - startTimestamp) / 1000_000)
        
        // Set post data that come from the outside, e.g. the system.
        environmentPrime.processEnvironmentConfig(processorReference.postconfig)
        
        notify(new ProcessorFinished(this, processorReference, processorInstance))
        
        environmentPrime
    }
        
    /** For a processor group, call compile for each entry. You can cancel a compilation if the cancel property is set. */
    protected dispatch def Environment compileEntry(ProcessorGroup processorGroup, Environment environment) {
        var Environment environmentPrime = environment
        var cancel = false
        var idx = 0
        while (idx < processorGroup.processors.size) {
            val processor = processorGroup.processors.get(idx)
             if (!cancel) {
                 environmentPrime = processor.compileEntry(environmentPrime)
                 cancel = environmentPrime.getProperty(CANCEL_COMPILATION)
             }
             idx++
        }
        environmentPrime
    }

    /** Compile each entry of the group. However, select the next environment for the ongoing compilation depending on the metric. */
    protected dispatch def Environment compileEntry(ProcessorAlternativeGroup processorAlternativeGroup, Environment environment) {
        val environmentList = <Environment> newArrayList
        for (processor : processorAlternativeGroup.processors) {
            environmentList += processor.compileEntry(environment)
        }
        var selectedEnvironment = environmentList.last
        for (e : environmentList) {
            val selMetric = selectedEnvironment.getProperty(Metric.METRIC)
            val envMetric = e.getProperty(Metric.METRIC)
            if (envMetric < selMetric) {
                selectedEnvironment = e
            }
        }
        selectedEnvironment
    }
    
    protected dispatch def Environment compileEntry(ProcessorSystem processorSystem, Environment environment) {
        val subContext = subContexts.get(processorSystem)
        subContext.compile(environment)
    }
    
    def Processor<?,?> getProcessorFor(IProperty<?> property, Object object) {
        for (processor : processorInstancesSequence) {
            val p = processor.environment.getProperty(property)
            if (p == object) return processor
        }
        return null
    }
    
    def Environment getResultForModel(Object model) {
        for (processor : processorInstancesSequence) {
            val p = processor.environment.getProperty(MODEL)
            if (p == model) {
                return processor.environment
            }
            
            val snapshots = processor.environment.getProperty(SNAPSHOTS)
            for (snapshot : snapshots) {
                if (snapshot == model) {
                    return processor.environment
                }
            }
            
            val errors = processor.environment.getProperty(ERRORS)
            if (errors.keySet.contains(model)) {
                return processor.environment
            }
            
            val warnings = processor.environment.getProperty(WARNINGS)
            if (warnings.keySet.contains(model)) {
                return processor.environment
            }
            
            val infos = processor.environment.getProperty(INFOS)
            if (infos.keySet.contains(model)) {
                return processor.environment
            }
            
        }
        return null
    }
    
    override cloneObject() {
        this
    }
    
    override isMutable() {
        false
    }
    
    def getProcessorInstances() {
        processorMap.values.toList
    }
    
    def Processor<?,?> getProcessorInstance(ProcessorReference processorReference) {
        processorMap.get(processorReference)
    }
    
    def Processor<?,?> getFirstProcessorInstance() {
        processorInstancesSequence.head
    }
    
    def setOriginalModel(Object originalModel) {
        this.originalModel = originalModel
        startEnvironment.setProperty(ORIGINAL_MODEL, originalModel)
    }
    
    public def notify(Object arg) {
        setChanged
        notifyObservers(arg)
        if (startEnvironment.getProperty(Environment.DYNAMIC_PROCESSOR_SYSTEM)) {
            notifications += arg as AbstractContextNotification
        }
    }   
    
    override synchronized void addObserver(Observer o) {
        super.addObserver(o)
        for (sc : subContexts.values) sc.addObserver(o)
    }

    override synchronized void deleteObserver(Observer o) {
        super.deleteObserver(o)
        for (sc : subContexts.values) sc.deleteObserver(o)
    }    
    
    def CompilationContext getRootContext() {
        if (parentContext === null) return this
        else return parentContext.getRootContext
    }
    
    def ProcessorEntry getOriginalProcessorEntry(ProcessorEntry processorEntry) {
        return systemMap.get(processorEntry)
    }
    
    /** 
     * Adds a single processor entry at the end of the root processor group.
     * Adding processor systems is not supported at the moment.
     */
    def void addProcessorEntry(ProcessorEntry processorEntry) {
        val processorEntryPoint = system.processors
        if (processorEntryPoint instanceof ProcessorGroup) {
            processorEntryPoint.processors += processorEntry
            processorEntry.populate(this)
            notify(new CompilationChanged(this, system, processorEntry))
        } else {
            throw new IllegalStateException("Tried to add a processor programmatically, but there was no processor group.")
        }
    }
    
    def void addProcessorEntry(String processorId) {
        val processorEntry = KiCoolFactory.eINSTANCE.createProcessorReference => [
            it.id = processorId
        ]
        processorEntry.addProcessorEntry 
    }
 
    /** 
     * Adds a list of processor entries at the given position of the root processor group.
     * Adding processor systems is not supported at the moment.
     */
    def void addProcessorEntries(Processor<?,?> position, List<ProcessorEntry> processorEntries) {
        val processorEntryPoint = system.processors
        if (processorEntryPoint instanceof ProcessorGroup) {
            for (newEntry : processorEntries.reverseView) {
                val posProcessor = processorMap.entrySet.findFirst[value == position]?.key
                if (posProcessor === null) {
                    throw new IllegalArgumentException("Given position processor does not exist.")
                }
                val idx = processorEntryPoint.processors.indexOf(posProcessor)
                if (posProcessor === null) {
                    throw new IllegalArgumentException("Given position processor does not exist in the processor group.")
                }
                processorEntryPoint.processors.add(idx + 1, newEntry)
                newEntry.populate(this)
                // Fix order in processor instance sequence
                val newInstance = processorMap.get(newEntry)
                processorInstancesSequence.remove(newInstance)
                processorInstancesSequence.add(processorInstancesSequence.indexOf(position) + 1, newInstance)
                notify(new CompilationChanged(this, system, newEntry))
            }
        } else {
            throw new IllegalStateException("Tried to add a processor programmatically, but there was no processor group.")
        }
    }
    
    def void addProcessorEntries(Processor<?,?> position, String... processorIds) {
        position.addProcessorEntries(processorIds.map[ id |
            (KiCoolFactory.eINSTANCE.createProcessorReference => [
                it.id = id
            ]) as ProcessorEntry
        ])
    }
    
    @Inject TracingIntegration tracingIntegrationInstance
    
    protected def List<IntermediateProcessor<?,?>> getIntermediateProcessors() {
        val processors = system.intermediates.map[ processorMap.get(it) as IntermediateProcessor<?,?> ]
        
        if (startEnvironment.isTracingActive) {
            return <IntermediateProcessor<?,?>> newLinkedList => [
                    addAll(processors) 
                    add(tracingIntegrationInstance)
                ]
        }
        
        processors
    }
    
    protected def List<IntermediateProcessor<?,?>> getIntermediateProcessors(ProcessorReference processorReference) {
        if (processorReference.metric !== null) {
            return (system.intermediates.filter[ !(processorMap.get(it) instanceof Metric<?,?>) ].toList => [
                it += processorReference.metric
            ]).map[ processorMap.get(it) as IntermediateProcessor<?,?> ]    
        } 
        return getIntermediateProcessors        
    }
    
    protected def void executeCoProcessors(Processor<?, ?> processor, List<ProcessorReference> processorReferences, boolean isPostProcessor) {
        for (processorReference : processorReferences) {
            processor.executeCoProcessor(processor.createCoProcessor(processorReference.id), !processorReference.silent, isPostProcessor)
        }
    }
    
       
}