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

import de.scheidtbachmann.statemachine.transformators.ModelSelect;

import com.google.common.collect.Iterables;
import com.google.inject.Inject;
import com.google.inject.Provider;
import de.cau.cs.kieler.kicool.compilation.CodeContainer;
import de.cau.cs.kieler.kicool.compilation.CodeFile;
import de.cau.cs.kieler.kicool.compilation.CompilationContext;
import de.cau.cs.kieler.kicool.compilation.Compile;
import de.cau.cs.kieler.kicool.environments.Environment;
import de.cau.cs.kieler.kicool.registration.KiCoolRegistration;
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeGenerator;
import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.Resource.Diagnostic;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * Common abtract class for state machine compilation.
 */
public abstract class AbstractStateMachineGeneratorPlugin extends AbstractMojo {

    private static final String ISSUE_FORMAT = "Line %d, column %d: %s%n";

    // Common lock to allow thread safety in parallel maven execution
    protected static final Object LOCK = new Object();

    protected AbstractStateMachineGeneratorPlugin() {
        super();
        new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration().injectMembers(this);
    }

    @Inject
    private Provider<IResourceValidator> validatorProvider;

    protected final Path basePath = Paths.get("");

    private final ResourceSet set = new ResourceSetImpl();

    protected void processStateMachine(final StateMachine machine) throws MojoFailureException, MojoExecutionException {
        // Make sure the output folder exists and is writable
        final Path outputPath = basePath.toAbsolutePath().resolve(machine.getOutputFolder());
        prepareOutputFolder(outputPath);
        // Load input data

        final Resource resource = loadResource(machine.getFileName());
        if (resource != null) {
            doValidate(resource);
            doGenerate(resource, machine, outputPath);
        } else {
            throw new MojoExecutionException("Loading resource yielded null.");
        }
    }

    private void prepareOutputFolder(final Path outputPath) throws MojoFailureException {
        if (!Files.exists(outputPath)) {
            try {
                Files.createDirectories(outputPath);
            } catch (final IOException e) {
                throw new MojoFailureException("Couldn't create output path.");
            }
        }
        if (!Files.isDirectory(outputPath)) {
            throw new MojoFailureException("Output path exists, but is no directory.");
        }
        if (!Files.isWritable(outputPath)) {
            throw new MojoFailureException("Output paths is not writable.");
        }
    }

    /**
     * Do the real validation work.
     *
     * @throws MojoFailureException
     *             if code was not valid
     */
    private void doValidate(final Resource resource) throws MojoFailureException {
        // Resolve the injected provider for a validator
        final IResourceValidator validator = validatorProvider.get();
        // Validate the resource and gather all the issues
        final List<Issue> issues = validator.validate(resource, CheckMode.ALL, null);
        if (issues == null || issues.isEmpty()) {
            // Validation successful. We happy!
            getLog().debug("Input is fine.");
        } else {
            // Something is not fine. Filter various severities
            final Iterable<Issue> errors = Iterables.filter(issues, issue -> issue.getSeverity() == Severity.ERROR);
            final Iterable<Issue> warnings = Iterables.filter(issues, issue -> issue.getSeverity() == Severity.WARNING);
            final Iterable<Issue> infos = Iterables.filter(issues, issue -> issue.getSeverity() == Severity.INFO);
            // Print all the issues to stdout
            final StringBuilder builder = new StringBuilder();
            if (errors.iterator().hasNext()) {
                builder.append("Validation discovered the following errors:\n");
                for (final Issue issue : errors) {
                    builder.append(
                        String.format(ISSUE_FORMAT, issue.getLineNumber(), issue.getColumn(), issue.getMessage()));
                }
            }
            if (warnings.iterator().hasNext()) {
                builder.append("%nValidation discovered the following warnings:\n");
                for (final Issue issue : warnings) {
                    builder.append(
                        String.format(ISSUE_FORMAT, issue.getLineNumber(), issue.getColumn(), issue.getMessage()));
                }
            }
            if (infos.iterator().hasNext()) {
                builder.append("%nFurther infos/remarks:\n");
                for (final Issue issue : infos) {
                    builder.append(
                        String.format(ISSUE_FORMAT, issue.getLineNumber(), issue.getColumn(), issue.getMessage()));
                }
            }

            throw new MojoFailureException(builder.toString());
        }

    }

    private void doGenerate(final Resource resource, final StateMachine machine, final Path outputPath)
        throws MojoFailureException, MojoExecutionException {
        final String strategyId = loadCustomStrategy(machine.getStrategy());
        getLog().debug(String.format("Compiling %s using strategy %s ...", resource, strategyId));

        final Object result = doCompile(resource, machine, strategyId);

        if (result instanceof CodeContainer) {
            final CodeContainer cc = (CodeContainer) result;
            for (final CodeFile file : cc.getFiles()) {
                try {
                    final Path fileOutputPath = outputPath.resolve(file.getFileName());
                    Files.write(fileOutputPath, file.getCode().getBytes());
                } catch (final IOException e) {
                    throw new MojoFailureException("Failed to write output file " + file.getFileName() + ".\n" + e);
                }
            }
        } else {
            throw new MojoExecutionException("No code generated.");
        }
    }

    private Object doCompile(final Resource resource, final StateMachine machine, final String strategyId) {

        try {
            final CompilationContext ctx = Compile.createCompilationContext(strategyId, resource.getContents().get(0));
            // the following property setting only applies to strategy
            // 'de.cau.cs.kieler.sccharts.statebased'
            ctx.getStartEnvironment().setProperty(StatebasedCCodeGenerator.LEAN_MODE, true);
            if (machine.getSelectedModel() != null && !machine.getSelectedModel().isEmpty()) {
                ctx.getStartEnvironment().setProperty(ModelSelect.SELECTED_MODEL, machine.getSelectedModel());
            }

            ctx.setStopOnError(true);
            final Environment compiled = ctx.compile();
            compiled.getErrors().forEach((obj, list) -> list.forEach(link -> getLog().error(link.getMessage())));

            return compiled.getModel();

        } catch (final Exception t) {
            getLog().error(t);
            return null;
        } finally {
            getLog().debug("...done.");
        }
    }

    /*
     * ----------------------- HELPER -----------------------
     */

    private Resource loadResource(final String fileName) {
        Resource resource = null;
        if (fileName != null && !fileName.isEmpty()) {
            final URI sourceFile = URI.createFileURI(fileName);

            if (set.getURIConverter().exists(sourceFile, null)) {
                resource = set.getResource(sourceFile, true);
            }
        }

        return resource;
    }

    /**
     * Checks for an id of a pre-installed compilation strategy and attempts to load
     * the provided strategy description othwise.
     *
     * @throws MojoFailureException
     *             if the given strategy couldn't be loaded
     */
    private String loadCustomStrategy(final String strategy) throws MojoFailureException {
        final boolean strategyIsAlreadyLoaded = KiCoolRegistration.getSystemModels().stream() //
            .map(de.cau.cs.kieler.kicool.System::getId) //
            .anyMatch(strategy::equals);
        if (strategyIsAlreadyLoaded) {
            return strategy;
        } else if (!strategy.endsWith(".kico")) {
            throw new MojoFailureException("The extension of the provided strategy file is invalid.");
        } else {
            final Path strategyPath = basePath.resolve(strategy);
            if (!Files.exists(strategyPath)) {
                throw new MojoFailureException("The provided strategy file does not exist.");
            } else if (!Files.isRegularFile(strategyPath)) {
                throw new MojoFailureException("The provided strategy file is not a file.");
            } else if (!Files.isReadable(strategyPath)) {
                throw new MojoFailureException("The provided strategy file is not readable.");
            }

            final Resource strategyResource =
                set.getResource(URI.createFileURI(basePath.resolve(strategy).toString()), true);
            final Iterable<Diagnostic> issues =
                Iterables.concat(strategyResource.getErrors(), strategyResource.getWarnings());
            final StringBuilder issuesText = new StringBuilder();
            for (final Diagnostic issue : issues) {
                issuesText.append(String.format(ISSUE_FORMAT, issue.getLine(), issue.getColumn(), issue.getMessage()));
            }

            final EObject root = strategyResource.getContents().get(0);

            if (root instanceof de.cau.cs.kieler.kicool.System) {
                final de.cau.cs.kieler.kicool.System sys = (de.cau.cs.kieler.kicool.System) root;
                if (KiCoolRegistration.getSystemModels().stream().map(de.cau.cs.kieler.kicool.System::getId)
                    .anyMatch(id -> id.equals(strategy))) {
                    throw new MojoFailureException(
                        "Did load strategy without errors, but the strategy's id " + sys.getId() + "is already used.");
                } else if (issuesText.length() == 0) {
                    KiCoolRegistration.registerTemporarySystem(sys);
                    return sys.getId();
                } else {
                    throw new MojoFailureException("Did load " + strategy + " with errors:\n" + issuesText.toString());
                }
            } else {
                throw new MojoFailureException(
                    "Could not find valid compilation strategy description in given strategy.\n"
                        + issuesText.toString());
            }
        }
    }
}
