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
import org.apache.maven.project.MavenProject;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Maven plugin that compiles all state machines in the source directory with the same settings.
 */
@Mojo(name = "SMGenAll", defaultPhase = LifecyclePhase.GENERATE_SOURCES, threadSafe = true)
public class StateMachineAutoGeneratorPlugin extends AbstractStateMachineGeneratorPlugin {

    private static final String PACKAGE_PRAGMA = "#package";
    private static final String DEFAULT_FILE_EXTENSION = ".sctx";

    @Parameter(defaultValue = "${project}", readonly = true, required = true)
    private MavenProject project;

    @Parameter(property = "outputFolder", defaultValue = "${project.basedir}/src-gen", required = true)
    private String outputFolder;

    @Parameter(property = "sourceFolder", defaultValue = "${project.basedir}/src", required = true)
    private String sourceFolder;

    @Parameter(property = "strategy", required = true)
    private String strategy;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        synchronized (LOCK) {
            final List<StateMachine> stateMachines = gatherAllStateMachines();
            for (final StateMachine machine : stateMachines) {
                processStateMachine(machine);
            }
        }
    }

    private List<StateMachine> gatherAllStateMachines() throws MojoExecutionException {
        final Path path = Paths.get(sourceFolder);
        if (path.toFile().exists() && path.toFile().canRead() && path.toFile().isDirectory()) {
            try (Stream<Path> paths = Files.walk(path)) {
                return paths.map(Path::toFile) // Resolve all paths to files, to be able to work with then name
                    .filter(File::isFile) // Drop all directories and stuff
                    .filter(file -> file.getName().endsWith(DEFAULT_FILE_EXTENSION)) // Only take state machine files
                    .map(this::createStateMachineConfig) // Resolve the file and configure the state machine from it
                    .collect(Collectors.toList());
            } catch (final IOException e) {
                throw new MojoExecutionException("Unable to read files", e);
            }
        } else {
            return Collections.emptyList();
        }
    }

    private StateMachine createStateMachineConfig(final File file) {
        final StateMachine result = new StateMachine();
        result.setStrategy(strategy);
        result.setFileName(file.getAbsolutePath());
        Path outputPath = Paths.get(outputFolder);
        try {
            final String packageDeclaration = Files.readAllLines(file.toPath(), StandardCharsets.UTF_8).stream() //
                .filter(line -> line.startsWith(PACKAGE_PRAGMA)) // Find a package declaration in the state machine
                .findFirst() // We should only have one declaration, so we go ahead with that one
                .map(line -> line.substring(PACKAGE_PRAGMA.length())) // Strip away the pragma at the start
                .map(line -> line.replace("\"", "")) // Strip away the quotes to have the clean declaration
                .map(String::trim) // Drop whitespace if there is any
                .orElse(""); // In case we have nothing, take empty string
            outputPath = Paths.get(outputFolder, packageDeclaration.split("\\."));
        } catch (final IOException e) {
            getLog().error("Problem loading file", e);
        }
        result.setOutputFolder(outputPath.toString());

        return result;
    }
}
