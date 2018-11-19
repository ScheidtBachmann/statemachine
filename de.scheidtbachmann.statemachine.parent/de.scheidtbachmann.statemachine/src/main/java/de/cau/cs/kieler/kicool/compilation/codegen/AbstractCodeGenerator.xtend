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
package de.cau.cs.kieler.kicool.compilation.codegen

import de.cau.cs.kieler.kicool.compilation.Processor
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import com.google.inject.Inject
import com.google.inject.Injector
import de.cau.cs.kieler.kicool.compilation.codegen.CodeGeneratorModule
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Map
import de.cau.cs.kieler.core.model.properties.IProperty
import de.cau.cs.kieler.core.model.properties.Property


/**
 * Abstract Code Generation Processor
 * 
 * @author ssm
 * @kieler.design 2017-07-21 proposed 
 * @kieler.rating 2017-07-21 proposed yellow 
 * 
 */
abstract class AbstractCodeGenerator<T, E> extends Processor<T, CodeContainer> {
    
    @Inject protected Injector injector
    
    public static val IProperty<Boolean> COMMENTS_ENABLED = 
       new Property<Boolean>("de.cau.cs.kieler.kicool.codegen.comments.enabled", true)
    
    
    @Accessors(PUBLIC_GETTER) val moduleMap = <E, CodeGeneratorModule<T, E>> newHashMap
    
    override getType() {
        ProcessorType.EXOGENOUS_TRANSFORMATOR
    }
    
    abstract def void createModuleMap(T rootModel, Map<E, CodeGeneratorModule<T, E>> moduleMap)
    
    def void preProcess(T rootModel) {
        // Override for convenient additions...
    }
        
    override process() {
        val rootModel = getModel
        val result = new CodeContainer
        
        preProcess(rootModel);
        createModuleMap(rootModel, moduleMap)
        val commentsEnabled = environment.getProperty(COMMENTS_ENABLED)
        
        for (moduleObject : moduleMap.keySet) {
            moduleMap.get(moduleObject) => [
                generateInit
            ]
        }
        for (moduleObject : moduleMap.keySet) {
            moduleMap.get(moduleObject) => [
                generate
            ]
        }
        for (moduleObject : moduleMap.keySet) {
            moduleMap.get(moduleObject) => [
                generateDone
            ]
        }
        for (moduleObject : moduleMap.keySet) {
            moduleMap.get(moduleObject) => [
                generateWrite(result)
            ]
        }
        
        setModel(result)
    }
    
    /**
     * Creates a generator module via the injector. 
     * Override this if you need to create specialized generator modules of a certain type.
     */
    protected def CodeGeneratorModule<T, E> createCodeGenetatorModule() {
        return injector.getInstance(CodeGeneratorModule) as CodeGeneratorModule<T, E>
    }
    
    protected def hostcodeSafeName(String string) {
        if (string === null) return ""
        string.replaceAll("[\\s-]","_")
    }

}

