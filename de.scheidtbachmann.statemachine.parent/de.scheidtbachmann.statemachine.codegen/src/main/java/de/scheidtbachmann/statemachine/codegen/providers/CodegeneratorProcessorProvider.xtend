package de.scheidtbachmann.statemachine.codegen.providers

import de.cau.cs.kieler.kicool.registration.IProcessorProvider

/**
 * Provider to make code generators available to KiCool.
 * 
 * @author Wechselberg
 */
class CodegeneratorProcessorProvider implements IProcessorProvider {
    
    override getProcessors() {
        #[
            de.scheidtbachmann.statemachine.transformators.ModelSelect,
            de.scheidtbachmann.statemachine.codegen.lean.cpp.StatebasedLeanCppCodeGenerator,
            de.scheidtbachmann.statemachine.codegen.lean.java.StatebasedLeanJavaCodeGenerator
        ]
    }
    
}
