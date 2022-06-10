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

package de.scheidtbachmann.statemachine.plugin;

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;

import java.util.List;

/**
 * Maven plugin with deliberately configured state machine compilation.
 */
@Mojo(name = "SMGen", defaultPhase = LifecyclePhase.GENERATE_SOURCES, threadSafe = true)
public class StateMachineGeneratorPlugin extends AbstractStateMachineGeneratorPlugin {

    /** The Configuration of all state machines that should be compiled. */
    @Parameter(property = "stateMachines", required = true)
    private List<StateMachine> stateMachines;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        synchronized (LOCK) {
            for (final StateMachine machine : stateMachines) {
                processStateMachine(machine);
            }
        }
    }
}
