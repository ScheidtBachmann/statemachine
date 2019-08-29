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
package de.cau.cs.kieler.sccharts.processors.statebased.lean.codegen.cpp

import com.google.inject.Inject
import com.google.inject.Injector
import de.cau.cs.kieler.annotations.StringPragma
import de.cau.cs.kieler.annotations.extensions.PragmaExtensions
import de.cau.cs.kieler.annotations.registry.PragmaRegistry
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.kicool.compilation.ExogenousProcessor
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeGeneratorStructModule

import static extension de.cau.cs.kieler.sccharts.processors.statebased.lean.codegen.AbstractStatebasedLeanTemplate.hostcodeSafeName

/**
 * C++ Code Generator for the Statebased code generation using templates.
 * 
 * @author wechselberg
 */
class StatebasedLeanCppCodeGenerator extends ExogenousProcessor<SCCharts, CodeContainer> {

  @Inject extension PragmaExtensions
  @Inject protected Injector injector

  protected static val HOSTCODE = PragmaRegistry.register("hostcode", StringPragma, "Allows additional hostcode to be included (e.g. includes).")
  protected static val NAMESPACE = PragmaRegistry.register("namespace", StringPragma, "The namespace to use for the generated code.")
  protected static val SUPERCLASS = PragmaRegistry.register("superclass", StringPragma, "Superclass to use for the generated class file.")

  public static val C_EXTENSION = ".cpp"
  public static val H_EXTENSION = ".h"

  public static val INCLUDES = "includes"

  override getId() {
    "de.cau.cs.kieler.sccharts.processors.codegen.statebased.lean.cpp"
  }

  override getName() {
    "State-based C++ Code (Lean)"
  }

  override process() {
    val template = injector.getInstance(StatebasedLeanCppTemplate) as StatebasedLeanCppTemplate

    if (model.hasPragma(NAMESPACE)) {
      template.namespace = (model.getPragma(NAMESPACE) as StringPragma).values.head
    }

    if (model.hasPragma(SUPERCLASS)) {
      template.superClass = (model.getPragma(SUPERCLASS) as StringPragma).values.head
    }

    template.create(model.rootStates.head)

    val cc = new CodeContainer
    cc.writeToCodeContainer(template, model.rootStates.head.name.hostcodeSafeName, model)

    setModel(cc)
  }

  protected def void writeToCodeContainer(CodeContainer codeContainer, StatebasedLeanCppTemplate template,
    String codeFilename, SCCharts scc) {
    val hFilename = codeFilename + H_EXTENSION
    val cFilename = codeFilename + C_EXTENSION
    val hFile = new StringBuilder
    val cFile = new StringBuilder

    val headerMacro = ("_" + hFilename.replaceAll("\\.", "_") + "_").toUpperCase

    hFile.append('''
        #ifndef « headerMacro »
        #define « headerMacro »
        /*
         * Automatically generated C code by
         * KIELER SCCharts - The Key to Efficient Modeling
         *
         * http://rtsys.informatik.uni-kiel.de/kieler
         */
        « FOR include : template.findModifications.get(INCLUDES) »
            #include « include »
        « ENDFOR »
        « FOR hostcode : scc.getStringPragmas(HOSTCODE) »
            « hostcode.values.head »
        « ENDFOR »
        
        « template.header »
        #endif
        
    ''')

    cFile.append('''
        /*
         * Automatically generated C code by
         * KIELER SCCharts - The Key to Efficient Modeling
         *
         * http://rtsys.informatik.uni-kiel.de/kieler
         */
        #include "« hFilename »"
        
        « template.source »
    ''')

    codeContainer.addCCode(cFilename, cFile.toString, StatebasedCCodeGeneratorStructModule.STRUCT_NAME)
    codeContainer.addCHeader(hFilename, hFile.toString, StatebasedCCodeGeneratorStructModule.STRUCT_NAME)
  }
}
