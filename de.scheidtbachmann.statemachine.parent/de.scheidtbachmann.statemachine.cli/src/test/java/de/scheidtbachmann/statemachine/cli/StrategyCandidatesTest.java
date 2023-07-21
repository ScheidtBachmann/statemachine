// ******************************************************************************
//
// Copyright (c) 2023 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.cli;

import org.assertj.core.api.BDDAssertions;
import org.junit.jupiter.api.Test;

import java.util.LinkedList;
import java.util.List;

class StrategyCandidatesTest {

    private final StrategyCandidates testee = new StrategyCandidates();

    @Test
    void testIteratorContainsExactData() {

        final List<String> result = new LinkedList<>();
        for (final String element : testee) {
            result.add(element);
        }

        BDDAssertions.then(result).containsExactlyElementsOf(EXPECTED_STRATEGIES);
    }

    private static final List<String> EXPECTED_STRATEGIES = List.of( //
        "%n  de.cau.cs.kieler.c.sccharts.dataflow", "%n  de.cau.cs.kieler.kicool.identity",
        "%n  de.cau.cs.kieler.kicool.identity.dynamic", "%n  de.cau.cs.kieler.sccharts.causalView",
        "%n  de.cau.cs.kieler.sccharts.core", "%n  de.cau.cs.kieler.sccharts.core.core",
        "%n  de.cau.cs.kieler.sccharts.csv", "%n  de.cau.cs.kieler.sccharts.dataflow",
        "%n  de.cau.cs.kieler.sccharts.dataflow.lustre", "%n  de.cau.cs.kieler.sccharts.expansion.only",
        "%n  de.cau.cs.kieler.sccharts.extended", "%n  de.cau.cs.kieler.sccharts.extended.core",
        "%n  de.cau.cs.kieler.sccharts.interactiveScheduling", "%n  de.cau.cs.kieler.sccharts.netlist",
        "%n  de.cau.cs.kieler.sccharts.netlist.arduino.deploy", "%n  de.cau.cs.kieler.sccharts.netlist.dataflow",
        "%n  de.cau.cs.kieler.sccharts.netlist.guardOpt", "%n  de.cau.cs.kieler.sccharts.netlist.java",
        "%n  de.cau.cs.kieler.sccharts.netlist.nxj.deploy", "%n  de.cau.cs.kieler.sccharts.netlist.nxj.deploy.rconsole",
        "%n  de.cau.cs.kieler.sccharts.netlist.promela", "%n  de.cau.cs.kieler.sccharts.netlist.references",
        "%n  de.cau.cs.kieler.sccharts.netlist.sccp", "%n  de.cau.cs.kieler.sccharts.netlist.simple",
        "%n  de.cau.cs.kieler.sccharts.netlist.simulink", "%n  de.cau.cs.kieler.sccharts.netlist.smv",
        "%n  de.cau.cs.kieler.sccharts.netlist.vhdl", "%n  de.cau.cs.kieler.sccharts.priority",
        "%n  de.cau.cs.kieler.sccharts.priority.java", "%n  de.cau.cs.kieler.sccharts.priority.java.legacy",
        "%n  de.cau.cs.kieler.sccharts.priority.legacy", "%n  de.cau.cs.kieler.sccharts.scssa",
        "%n  de.cau.cs.kieler.sccharts.simulation.netlist.c", "%n  de.cau.cs.kieler.sccharts.simulation.netlist.java",
        "%n  de.cau.cs.kieler.sccharts.simulation.priority.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.priority.c.legacy",
        "%n  de.cau.cs.kieler.sccharts.simulation.priority.java",
        "%n  de.cau.cs.kieler.sccharts.simulation.priority.java.legacy",
        "%n  de.cau.cs.kieler.sccharts.simulation.statebased.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.statebased.lean.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.statebased.lean.cs.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.statebased.lean.java",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.netlist.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.netlist.java",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.priority.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.priority.c.legacy",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.priority.java",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.priority.java.legacy",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.statebased.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.statebased.lean.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.statebased.lean.cs.c",
        "%n  de.cau.cs.kieler.sccharts.simulation.tts.statebased.lean.java", "%n  de.cau.cs.kieler.sccharts.statebased",
        "%n  de.cau.cs.kieler.sccharts.statebased.lean", "%n  de.cau.cs.kieler.sccharts.statebased.lean.arduino.deploy",
        "%n  de.cau.cs.kieler.sccharts.statebased.lean.c.template",
        "%n  de.cau.cs.kieler.sccharts.statebased.lean.cs.c.template",
        "%n  de.cau.cs.kieler.sccharts.statebased.lean.java.template",
        "%n  de.cau.cs.kieler.sccharts.statebased.woComments", "%n  de.cau.cs.kieler.sccharts.verification.nusmv",
        "%n  de.cau.cs.kieler.sccharts.verification.nuxmv", "%n  de.cau.cs.kieler.sccharts.verification.spin",
        "%n  de.cau.cs.kieler.scg.netlist", "%n  de.cau.cs.kieler.scg.priority", "%n  de.cau.cs.kieler.scl.netlist.c",
        "%n  de.cau.cs.kieler.scl.netlist.java", "%n  de.cau.cs.kieler.scl.priority.c",
        "%n  de.cau.cs.kieler.scl.priority.java", "%n  de.cau.cs.kieler.scl.scc",
        "%n  de.cau.cs.kieler.scl.simulation.netlist.c", "%n  de.cau.cs.kieler.scl.simulation.netlist.java",
        "%n  de.cau.cs.kieler.scl.simulation.priority.c", "%n  de.cau.cs.kieler.scl.simulation.priority.java",
        "%n  de.cau.cs.kieler.scl.ssa.scssa", "%n  de.cau.cs.kieler.scl.ssa.scssa.sccp",
        "%n  de.cau.cs.kieler.scl.ssa.scssa.simple", "%n  de.cau.cs.kieler.scl.ssa.seq",
        "%n  de.cau.cs.kieler.slic.schedule",
        "%n  de.scheidtbachmann.statemachine.codegen.statebased.lean.cpp.template",
        "%n  de.scheidtbachmann.statemachine.codegen.statebased.lean.java.template",
        "%n  de.scheidtbachmann.statemachine.codegen.statebased.lean.java.template.selective"
            + ", %n  or a path to a custom <.kico> file");
}
