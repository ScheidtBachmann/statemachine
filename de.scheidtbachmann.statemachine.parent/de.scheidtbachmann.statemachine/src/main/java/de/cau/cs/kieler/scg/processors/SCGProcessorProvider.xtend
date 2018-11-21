package de.cau.cs.kieler.scg.processors

import de.cau.cs.kieler.kicool.registration.IProcessorProvider

class SCGProcessorProvider implements IProcessorProvider {

    override getProcessors() {
        #[
            de.cau.cs.kieler.scg.transformations.basicblocks.BasicBlockTransformation,
            de.cau.cs.kieler.scg.transformations.basicblocks.BasicBlockTransformationSCplus,
            de.cau.cs.kieler.scg.transformations.guards.FlatThreadsGuardTransformation,
            de.cau.cs.kieler.scg.transformations.guards.SimpleGuardTransformation,
            de.cau.cs.kieler.scg.processors.analyzer.ControlflowValidator,
            de.cau.cs.kieler.scg.processors.analyzer.LoopAnalyzerV2,
            de.cau.cs.kieler.scg.processors.analyzer.ThreadAnalyzer,
            de.cau.cs.kieler.scg.processors.optimizer.CleanupValuedObjects,
            de.cau.cs.kieler.scg.processors.optimizer.ConditionalMerger,
            de.cau.cs.kieler.scg.processors.optimizer.CopyPropagationV2,
            de.cau.cs.kieler.scg.processors.optimizer.HaltStateRemover,
            de.cau.cs.kieler.scg.processors.optimizer.PartialExpressionEvaluation,
            de.cau.cs.kieler.scg.processors.optimizer.SmartRegisterAllocation,
            de.cau.cs.kieler.scg.processors.ssa.CSSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.DeSSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.optimizer.SCCP,
            de.cau.cs.kieler.scg.processors.ssa.SCSSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.SimpleSCSSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.SSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.UnSSATransformation,
            de.cau.cs.kieler.scg.processors.ssa.WeakUnemitSSATransformation,
            de.cau.cs.kieler.scg.processors.transformators.codegen.c.CCodeGenerator,
            de.cau.cs.kieler.scg.processors.transformators.codegen.java.JavaCodeGenerator,
            de.cau.cs.kieler.scg.processors.transformators.dependencies.DependencyTransformationV2,
            de.cau.cs.kieler.scg.processors.transformators.priority.PriorityProcessor,
            de.cau.cs.kieler.scg.processors.transformators.priority.SCLPTransformation,
            de.cau.cs.kieler.scg.processors.transformators.priority.SJTransformation,
            de.cau.cs.kieler.scg.processors.transformators.SimpleGuardScheduler,
            de.cau.cs.kieler.scg.processors.transformators.SimpleGuardTransformation,
            de.cau.cs.kieler.scg.processors.transformators.StructuralDepthJoinProcessor,
            de.cau.cs.kieler.scg.processors.transformators.SurfaceDepthSeparatorProcessor
        ]
    }
}