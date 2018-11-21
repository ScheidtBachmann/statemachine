/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2016 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.kicool.registration

import com.google.common.io.ByteStreams
import com.google.inject.Guice
import de.cau.cs.kieler.kicool.KiCoolStandaloneSetup
import de.cau.cs.kieler.kicool.System
import de.cau.cs.kieler.kicool.classes.SourceTargetPair
import de.cau.cs.kieler.kicool.compilation.Processor
import de.cau.cs.kieler.kicool.kitt.tracing.internal.TracingIntegration
import java.io.ByteArrayInputStream
import java.io.Closeable
import java.io.IOException
import java.nio.file.FileSystemNotFoundException
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Paths
import java.util.Collections
import java.util.HashMap
import java.util.Iterator
import java.util.List
import java.util.Map
import java.util.ServiceLoader
import java.util.jar.JarFile
import org.eclipse.emf.common.EMFPlugin
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator

import static com.google.common.base.Preconditions.*

import static extension java.lang.String.format

/**
 * Main class for the registration of systems and processors.
 * 
 * @author ssm
 * @kieler.design 2016-10-19 proposed 
 * @kieler.rating 2016-10-19 proposed yellow
 *
 */
class KiCoolRegistration {
    
    public static val EXTENSION_POINT_SYSTEM = "de.cau.cs.kieler.kicool.system"
    public static val EXTENSION_POINT_PROCESSOR = "de.cau.cs.kieler.kicool.processor"
    
    private static val injector = Guice.createInjector(TracingIntegration.MODULE)
    private static val kicoolXtextInjector = KiCoolStandaloneSetup.doSetup
    
    private static val Map<String, System> modelsMap = new HashMap<String, System>()
    private static val Map<String, System> modelsIdMap = new HashMap<String, System>()
    private static val List<System> systemsModels = loadRegisteredSystemModels
    private static val Map<String, System> temporarySystems = <String, System> newHashMap
    
    private static val Map<String, Class<? extends Processor<?,?>>> processorMap = new HashMap<String, Class<? extends Processor<?,?>>>()
    private static val Map<String, SourceTargetPair<?,?>> processorModelTypes = new HashMap<String, SourceTargetPair<?,?>>()
    private static val List<Class<? extends Processor<?,?>>> processorList = loadRegisteredProcessors
    
    
    static def getInjector() {
        injector
    }
    
    static def getInstance(Class<?> clazz) {
        injector.getInstance(clazz);
    }
    
    static def getInstance(Object object) {
        injector.getInstance(object.getClass());
    }
    
    static def List<System> getSystemModels() {
        val allSystemModels = newArrayList
        if(!temporarySystems.isEmpty) {
            allSystemModels.addAll(temporarySystems.values)
        }
        allSystemModels.addAll(systemsModels)
        return allSystemModels
    }
    
    static def registerTemporarySystem(System system) {
        val id = system.id
        if(modelsIdMap.containsKey(id)) {
            throw new Exception("Cannot register temporary system '"+id+"'. Another system with this id is already registered.")
        }
        temporarySystems.put(id, system)
    }
    
    static def boolean isTemporarySystem(String id) {
        return temporarySystems.containsKey(id)
    }
    
    static def System getSystemByResource(String res) {
        checkArgument(modelsMap.containsKey(res), "No processor system registered for resource: " + res)
        modelsMap.get(res)
    }
    
    static def System getSystemById(String id) {
        if (temporarySystems.containsKey(id)) {
            return temporarySystems.get(id)
        }
        checkArgument(modelsIdMap.containsKey(id), "No processor system registered with id: " + id)
        modelsIdMap.get(id)
    }
    
    static def Iterator<String> getAvailableSystemsIDs() {
        modelsIdMap.keySet.iterator
    }
    
    static def System getProcessorSystemModel(String locationString) {
        modelsMap.get(locationString) as System
    }
    
    static def loadRegisteredSystemModels() {
        val systems = getRegisteredSystems
        val modelList = <System> newArrayList
        modelsMap.clear
        modelsIdMap.clear
        for(system : systems) {
            try {
                val model = loadEObjectFromResourceLocation(system.key, system.value)
                modelList += model
                modelsMap.put(system.key, model) 
                modelsIdMap.put(model.id, model)
            } catch (Exception e) {
                java.lang.System.err.println("There was an error loading the registered processor system " + system.toString)
                e.printStackTrace
            }
        }
        modelList
    }

    static def getRegisteredSystems() {
        val resourceList = <Pair<String, Object>> newArrayList
        if (EMFPlugin.IS_ECLIPSE_RUNNING) {
// chsch: deactivated because of dependency to 'org.eclipse.core.runtime' 
//          val systems = Platform.getExtensionRegistry().getConfigurationElementsFor(EXTENSION_POINT_SYSTEM);
//          for(system : systems) {
//              resourceList += new Pair<String, String>(system.getAttribute("system"), system.contributor.name)
//          }
            resourceList
        } else {
            val closeables = <Closeable>newArrayList()
            Collections.list(
                KiCoolRegistration.classLoader.getResources('system')
            ).iterator.map[
                if (protocol == 'jar') {
                    val file = new JarFile(file.substring(0, file.indexOf('!')).replaceFirst('^file:', ''))
                    closeables += file
                    file.stream.filter[
                        !isDirectory && name.startsWith('system') && name.endsWith('kico')
                    ].map[
                        name -> new ByteArrayInputStream(ByteStreams.toByteArray(file.getInputStream(it)))
                    ].iterator
                } else {
                    try {
                        FileSystems.getFileSystem(toURI);
                    } catch ( FileSystemNotFoundException e ) {
                        closeables += FileSystems.newFileSystem(toURI, emptyMap)
                    } catch ( Throwable t) {
                        // do nothing; chsch: on osx I get an IllegalArgumentException if the path is unequal to '/'
                    }
                    Files.find(Paths.get(toURI), 5)[ it, attributes | 
                        attributes.regularFile && fileName.toString.endsWith('kico')
                    ].map[
                        toString -> new ByteArrayInputStream(Files.readAllBytes(it))
                    ].iterator
                }
            ].flatten.toList => [
                for (c: closeables)
                    c.close()
            ]
        }
    }
    
    static def <T extends EObject> T loadEObjectFromResourceLocation(String resourceLocation, Object access) throws IOException {
        val XtextResourceSet resourceSet = kicoolXtextInjector.getInstance(XtextResourceSet)
        val resource = switch access {
            String case access.nullOrEmpty: 
                resourceSet.getResource(
                    URI.createPlatformPluginURI("/%s/%s".format(access, resourceLocation), false),
                    true
                )
            ByteArrayInputStream: {
                val res = resourceSet.createResource(URI.createURI(resourceLocation))
                res.load(access, emptyMap)
                res
            }
        }
        if (resource !== null && resource.getContents() !== null && resource.getContents().size() > 0) {
            val validatorResults = kicoolXtextInjector.getInstance(IResourceValidator).validate(resource, CheckMode.ALL, CancelIndicator.NullImpl).filter[severity === Severity.ERROR].toList
            if (!validatorResults.empty) {
                println("KiCool WARNING: There are error markers in system located at " + /* bundleId + */ ":" + resourceLocation + ": \n- " + validatorResults.map[message].join("\n- "))
            }
            val eobject = resource.getContents().get(0) as T
            return eobject
        }
        throw new IOException("Could not load resource '" + resourceLocation + "'!");
    }
    
    static def void addProcessor(Processor<?,?> processor) {
        processorMap.put(processor.id, processor.class as Class<? extends Processor<?,?>>)
        processorList += processor.class as Class<? extends Processor<?,?>>
    }
    
    static def loadRegisteredProcessors() {
        val processors = getRegisteredProcessors
        processorMap.clear
        processorModelTypes.clear
        for(processor : processors) {
            try {
                val instance = getInstance(processor) as Processor<?,?>
                processorMap.put(instance.getId, processor)
                processorModelTypes.put(instance.getId, instance.getSourceTargetTypes)
            } catch(Throwable e) {
                java.lang.System.err.println("KiCool: Cannot load processor " + processor.name + " (" + e + ")");
            }
        }
        processors
    }
    
    static def getRegisteredProcessors() {
        val resourceList = <Class<? extends Processor<?,?>>> newArrayList
        if (EMFPlugin.IS_ECLIPSE_RUNNING) {
// chsch: deactivated because of dependency to 'org.eclipse.core.runtime' 
//        val processors = Platform.getExtensionRegistry().getConfigurationElementsFor(EXTENSION_POINT_PROCESSOR);
//        for(processor : processors) {
//            try {
//                val instance = processor.createExecutableExtension("class")
//                val clazz = instance.getClass
//                resourceList += clazz as Class<? extends Processor<?,?>> 
//                //Class.forName(processor.name) as Class<? extends Processor>
//            } catch(Throwable e) {
//                java.lang.System.err.println("KiCool: Cannot load processor " + processor.getAttribute("class"));
//            }
//        }
            resourceList
        } else {
            ServiceLoader.load(IProcessorProvider).iterator.toIterable.map[
                processors
            ].flatten.toList
        }
    }
    
    static def getProcessorClass(String id) {
        processorMap.get(id)
    }
    
    static def getProcessorClasses() {
        processorList
    }
    
    static def getProcessorIds() {
        processorMap.keySet
    }
    
    static def getProcessorInstance(String id) {
        val clazz = processorMap.get(id)
        if (clazz === null) return null;
        getInstance(clazz) as Processor<?,?>
    }
    
    static def checkProcessorCompatibility(String source, String target) {
        if (processorModelTypes.keySet.contains(source) && processorModelTypes.keySet.contains(target)) {
            val sPair = processorModelTypes.get(source)
            val tPair = processorModelTypes.get(target)
            return tPair.source.class.isAssignableFrom(sPair.target.class)
        } 
        return true
    }
}
