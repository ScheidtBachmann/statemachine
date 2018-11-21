package de.cau.cs.kieler.sccharts.scg.processors

import de.cau.cs.kieler.kicool.registration.IProcessorProvider

class SCChartsSCGProcessorProvider implements IProcessorProvider {

    override getProcessors() {
        #[
            de.cau.cs.kieler.sccharts.scg.processors.transformators.SCG2SCCProcessor,
            de.cau.cs.kieler.sccharts.scg.processors.transformators.SCGTransformation
        ]
    }
}