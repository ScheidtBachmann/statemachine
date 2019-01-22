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
package de.cau.cs.kieler.scg.processors.transformators.codegen.java

import com.google.inject.Inject
import com.google.inject.Injector
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.scg.processors.transformators.codegen.c.CCodeGenerator
import de.cau.cs.kieler.scg.processors.transformators.codegen.c.CCodeGeneratorModule
import de.cau.cs.kieler.annotations.extensions.PragmaExtensions
import de.cau.cs.kieler.scg.codegen.SCGCodeGeneratorModule
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Root C Code Generator Module
 * 
 * Initializes necessary modules and invokes them in correct order.
 * 
 * @author ssm
 * @kieler.design 2017-07-21 proposed 
 * @kieler.rating 2017-07-21 proposed yellow 
 * 
 */
class JavaCodeGeneratorModule extends CCodeGeneratorModule {
    
    @Inject extension PragmaExtensions
    @Inject extension JavaCodeSerializeHRExtensions
    
    @Inject Injector injector
    
    public static val JAVA_EXTENSION = ".java"
    public static val CONTEXT_SUFFIX = "Context" 

    @Accessors var SCGCodeGeneratorModule contextInterface
            
    override configure() {
        struct = injector.getInstance(JavaCodeGeneratorStructModule)
        reset = injector.getInstance(JavaCodeGeneratorResetModule)
        tick = injector.getInstance(JavaCodeGeneratorTickModule)
        logic = injector.getInstance(JavaCodeGeneratorLogicModule)
        contextInterface = injector.getInstance(JavaCodeGeneratorContextModule)

        struct.configure(baseName, SCGraphs, scg, processorInstance, codeGeneratorModuleMap, codeFilename + JAVA_EXTENSION, this)
        reset.configure(baseName, SCGraphs, scg, processorInstance, codeGeneratorModuleMap, codeFilename + JAVA_EXTENSION, this)
        tick.configure(baseName, SCGraphs, scg, processorInstance, codeGeneratorModuleMap, codeFilename + JAVA_EXTENSION, this)
        logic.configure(baseName, SCGraphs, scg, processorInstance, codeGeneratorModuleMap, codeFilename + JAVA_EXTENSION, this)
        contextInterface.configure(baseName, SCGraphs, scg, processorInstance, codeGeneratorModuleMap, codeFilename + CONTEXT_SUFFIX + JAVA_EXTENSION, this)
    }
    
    override generateInit() {
        super.generateInit
        contextInterface.generateInit
    }
    
    override generate() {
        super.generate
        contextInterface.generate
    }
    
    override generateDone() {
        super.generateDone
        contextInterface.generateDone
    }
    
    override generateWrite(CodeContainer codeContainer) {
        val classFilename = codeFilename + JAVA_EXTENSION
        val classFile = new StringBuilder

        classFile.addHeader
        classFile.hostcodeAdditions
        
        classFile.append("public class " + codeFilename + " {\n\n")

        classFile.append(struct.code).append("\n")        
        classFile.append(reset.code).append("\n")
        classFile.append(logic.code).append("\n")
        classFile.append(tick.code)
        
        classFile.append("}\n")

        codeContainer.addJavaCode(classFilename, classFile.toString)

        val contextCode = contextInterface.code
        if (contextCode.length > 0) {
            val contextFilename = codeFilename + CONTEXT_SUFFIX + JAVA_EXTENSION
            val contextFile = new StringBuilder
            
            contextFile.addHeader
            contextFile.append("public interface " + codeFilename + CONTEXT_SUFFIX + " {\n\n")
            contextFile.append(contextCode).append("\n")
            contextFile.append("}\n")
            
            codeContainer.addJavaContextInterface(contextFilename, contextFile.toString)
        } 

    }    
    
    override def void addHeader(StringBuilder sb) {
        sb.append(
            "/*\n" + " * Automatically generated Java code by\n" + " * KIELER SCCharts - The Key to Efficient Modeling\n" +
                " *\n" + " * http://rtsys.informatik.uni-kiel.de/kieler\n" + " */\n\n")
                
        if (processorInstance.environment.getProperty(CCodeGenerator.DEBUG_COMMENTS)) {
            sb.addDebugComments
        }
    }  
    
    override def void hostcodeAdditions(StringBuilder sb) {
        val includes = modifications.get(JavaCodeSerializeHRExtensions.INCLUDES)
        for (include : includes)  {
            sb.append("import " + include + "\n")
        }
        
        val hostcodePragmas = SCGraphs.getStringPragmas(HOSTCODE)
        for (pragma : hostcodePragmas) {
            sb.append(pragma.values.head + "\n")
        }
        if (hostcodePragmas.size > 0 || includes.size > 0) {
            sb.append("\n")
        }
    }  
    
}