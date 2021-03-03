# SST StateMachine Compilation

This software is used to generate code from statemachine models.
The underlying technology consists of the [KIELER SCCharts](https://rtsys.informatik.uni-kiel.de/confluence/x/GIDbAQ) compilation toolchain with some adjusted code generation.

## Version History (abbreviated)

* **0.1.0**: The initial version consists of a "hard-fork" of the SCCharts project, which has been heavily modified to provide stand-alone compilation with a CLI or a maven plugin.
* **0.2.0**: The version currently in development. The previously forked components have been migrated back to the original SCCharts project and options to use SCCharts in a stand-alone way. This version now depends on the published artifacts from Kiel University and only provides the modified data.