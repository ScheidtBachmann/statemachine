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

package de.scheidtbachmann.statemachine.codegen.lean.cpp

import com.google.inject.Inject
import com.google.inject.Injector
import de.cau.cs.kieler.annotations.StringPragma
import de.cau.cs.kieler.annotations.extensions.PragmaExtensions
import de.cau.cs.kieler.annotations.registry.PragmaRegistry
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.kicool.compilation.ExogenousProcessor
import de.cau.cs.kieler.kicool.compilation.codegen.CodeGeneratorNames
import de.cau.cs.kieler.sccharts.SCCharts
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

import static de.cau.cs.kieler.kicool.compilation.codegen.AbstractCodeGenerator.*
import static de.cau.cs.kieler.kicool.compilation.codegen.CodeGeneratorNames.*

import static extension de.cau.cs.kieler.sccharts.processors.statebased.lean.codegen.AbstractStatebasedLeanTemplate.hostcodeSafeName

/**
 * C++ Code Generator for the state-based code generation using templates.
 */
class StatebasedLeanCppCodeGenerator extends ExogenousProcessor<SCCharts, CodeContainer> {

  @Inject extension PragmaExtensions
  @Inject protected Injector injector

  protected static val HOSTCODE = PragmaRegistry.register("hostcode", StringPragma, 
      "Allows additional hostcode to be included (e.g. includes).")
  protected static val NAMESPACE = PragmaRegistry.register("namespace", StringPragma,
      "The namespace to use for the generated code.")
  protected static val SUPERCLASS = PragmaRegistry.register("superclass", StringPragma,
      "Superclass to use for the generated class file.")

  public static val C_EXTENSION = ".cpp"
  public static val H_EXTENSION = ".h"

  public static val INCLUDES = "includes"
  
  @Accessors Map<CodeGeneratorNames, String> naming = <CodeGeneratorNames, String> newHashMap

  override getId() {
    "de.scheidtbachmann.statemachine.codegen.statebased.lean.cpp"
  }

  override getName() {
    "State-based C++ Code (Lean) - Scheidt & Bachmann"
  }

  override process() {
    val template = injector.getInstance(StatebasedLeanCppTemplate)

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

    naming.put(TICK, environment.getProperty(TICK_FUNCTION_NAME))
    naming.put(RESET, environment.getProperty(RESET_FUNCTION_NAME))
    naming.put(LOGIC, environment.getProperty(LOGIC_FUNCTION_NAME))
    naming.put(TICKDATA, environment.getProperty(TICKDATA_STRUCT_NAME))   

    codeContainer.addCCode(cFilename, cFile.toString).naming.putAll(naming)
    codeContainer.addCHeader(hFilename, hFile.toString).naming.putAll(naming)
     
  }
}
