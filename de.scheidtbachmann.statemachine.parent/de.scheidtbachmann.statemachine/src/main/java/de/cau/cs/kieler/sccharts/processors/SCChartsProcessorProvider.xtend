package de.cau.cs.kieler.sccharts.processors

import de.cau.cs.kieler.kicool.registration.IProcessorProvider

class SCChartsProcessorProvider implements IProcessorProvider {

    override getProcessors() {
        #[
            de.cau.cs.kieler.sccharts.processors.codegen.statebased.StatebasedCCodeGenerator,
            de.cau.cs.kieler.sccharts.processors.dataflow.Dataflow,
            de.cau.cs.kieler.sccharts.processors.statebased.DeConditionalize,
            de.cau.cs.kieler.sccharts.processors.statebased.DeImmediateDelay,
            de.cau.cs.kieler.sccharts.processors.statebased.DeSurfaceDepth,
            de.cau.cs.kieler.sccharts.processors.statebased.DeTriggerEffect,
            de.cau.cs.kieler.sccharts.processors.statebased.SuperfluousSuperstateRemover,
            de.cau.cs.kieler.sccharts.processors.transformators.Abort,
            de.cau.cs.kieler.sccharts.processors.transformators.AbortWTO,
            de.cau.cs.kieler.sccharts.processors.transformators.AbortWTODeep,
            de.cau.cs.kieler.sccharts.processors.transformators.ComplexFinalState,
            de.cau.cs.kieler.sccharts.processors.transformators.Connector,
            de.cau.cs.kieler.sccharts.processors.transformators.Const,
            de.cau.cs.kieler.sccharts.processors.transformators.CountDelay,
            de.cau.cs.kieler.sccharts.processors.transformators.Deferred,
            de.cau.cs.kieler.sccharts.processors.transformators.During,
            de.cau.cs.kieler.sccharts.processors.transformators.Entry,
            de.cau.cs.kieler.sccharts.processors.transformators.Exit,
            de.cau.cs.kieler.sccharts.processors.transformators.ExposeLocalValuedObject,
            de.cau.cs.kieler.sccharts.processors.transformators.Fby,
            de.cau.cs.kieler.sccharts.processors.transformators.FinalRegion,
            de.cau.cs.kieler.sccharts.processors.transformators.For,
            de.cau.cs.kieler.sccharts.processors.transformators.History,
            de.cau.cs.kieler.sccharts.processors.transformators.Initialization,
            de.cau.cs.kieler.sccharts.processors.transformators.InputOutputVariable,
            de.cau.cs.kieler.sccharts.processors.transformators.Map,
            de.cau.cs.kieler.sccharts.processors.transformators.Period,
            de.cau.cs.kieler.sccharts.processors.transformators.Pre,
            de.cau.cs.kieler.sccharts.processors.transformators.PrTransitions,
            de.cau.cs.kieler.sccharts.processors.transformators.Reference,
            de.cau.cs.kieler.sccharts.processors.transformators.RegionActions,
            de.cau.cs.kieler.sccharts.processors.transformators.Signal,
            de.cau.cs.kieler.sccharts.processors.transformators.SplitTED,
            de.cau.cs.kieler.sccharts.processors.transformators.Static,
            de.cau.cs.kieler.sccharts.processors.transformators.SurfaceDepth,
            de.cau.cs.kieler.sccharts.processors.transformators.Suspend,
            de.cau.cs.kieler.sccharts.processors.transformators.TakenTransitionSignaling,
            de.cau.cs.kieler.sccharts.processors.transformators.Termination,
            de.cau.cs.kieler.sccharts.processors.transformators.TimedAutomata,
            de.cau.cs.kieler.sccharts.processors.transformators.TriggerEffect,
            de.cau.cs.kieler.sccharts.processors.transformators.UserSchedule,
            de.cau.cs.kieler.sccharts.processors.transformators.WeakSuspend
        ]
    }
}