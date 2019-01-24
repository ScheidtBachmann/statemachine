package de.scheidtbachmann.statemachine.plugin;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
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

import com.google.common.collect.Iterables;
import com.google.common.collect.Iterators;
import com.google.inject.Inject;
import com.google.inject.Provider;

import de.cau.cs.kieler.kicool.compilation.CodeContainer;
import de.cau.cs.kieler.kicool.compilation.CodeFile;
import de.cau.cs.kieler.kicool.compilation.CompilationContext;
import de.cau.cs.kieler.kicool.compilation.Compile;
import de.cau.cs.kieler.kicool.registration.KiCoolRegistration;
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeGenerator;
import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup;

/**
 * Maven plugin to run the StateMachine code generator.
 * 
 * @author wechselberg
 */
@Mojo(name = "SMGen", defaultPhase = LifecyclePhase.GENERATE_SOURCES)
public class StateMachineGeneratorPlugin extends AbstractMojo {

	public StateMachineGeneratorPlugin() {
		super();
		new StateMachineStandaloneSetup().createInjectorAndDoEMFRegistration().injectMembers(this);
		;
	}

	/**
	 * The files to read as StateMachines
	 */
	@Parameter(property = "stateMachines", required = true)
	private List<String> stateMachines;

	/** The folder the generated files should be placed in */
	@Parameter(property = "outputFolder", defaultValue = "sm-gen")
	private String outputFolder;

	/** The compilation strategy to use during code generation */
	@Parameter(property = "strategy", defaultValue = "de.cau.cs.kieler.sccharts.statebased")
	private String strategy;

	@Inject
	private Provider<IResourceValidator> validatorProvider;

	private Path basePath = Paths.get("");

	private ResourceSet set = new ResourceSetImpl();

	@Override
	public void execute() throws MojoExecutionException, MojoFailureException {

		// Make sure the output folder exists and is writable
		Path basePath = Paths.get("");
		Path outputPath = basePath.toAbsolutePath().resolve(outputFolder);
		if (!Files.exists(outputPath)) {
			try {
				Files.createDirectories(outputPath);
			} catch (IOException e) {
				throw new MojoFailureException("Couldn't create output path.");
			}
		}
		if (!Files.isDirectory(outputPath)) {
			throw new MojoFailureException("Output path exists, but is no directory.");
		}
		if (!Files.isWritable(outputPath)) {
			throw new MojoFailureException("Output paths is not writable.");
		}

		for (String fileName : stateMachines) {
			// Load input data
			Resource resource = loadResource(fileName);
			doValidate(resource);
			doGenerate(resource, outputPath);
		}
	}

	/**
	 * Do the real validation work.
	 * @throws MojoFailureException 
	 */
	private void doValidate(Resource resource) throws MojoFailureException {
		// Resolve the injected provider for a validator
		IResourceValidator validator = validatorProvider.get();
		// Validate the resource and gather all the issues
		List<Issue> issues = validator.validate(resource, CheckMode.ALL, null);
		if (issues == null || issues.isEmpty()) {
			// Validation successful. We happy!
			getLog().debug("Input is fine.");
		} else {
			// Something is not fine. Filter various severities
			Iterable<Issue> errors = Iterables.filter(issues, issue -> {
				return issue.getSeverity() == Severity.ERROR;
			});
			Iterable<Issue> warnings = Iterables.filter(issues, issue -> {
				return issue.getSeverity() == Severity.WARNING;
			});
			Iterable<Issue> infos = Iterables.filter(issues, issue -> {
				return issue.getSeverity() == Severity.INFO;
			});
			// Print all the issues to stdout
			StringBuilder builder = new StringBuilder();
			if (errors.iterator().hasNext()) {
				builder.append("Validation discovered the following errors:\n");
				for (Issue issue : errors) {
					builder.append(String.format("Line %d, column %d %s: %s%n", issue.getLineNumber(),
							issue.getColumn(), issue.isSyntaxError() ? "(syntax error)" : "", issue.getMessage()));
				}
			}
			if (warnings.iterator().hasNext()) {
				builder.append("%nValidation discovered the following warnings:\n");
				for (Issue issue : warnings) {
					builder.append(String.format("Line %d, column %d: %s%n", issue.getLineNumber(), issue.getColumn(),
							issue.getMessage()));
				}
			}
			if (infos.iterator().hasNext()) {
				builder.append("%nFurther infos/remarks:\n");
				for (Issue issue : infos) {
					builder.append(String.format("Line %d, column %d: %s%n", issue.getLineNumber(), issue.getColumn(),
							issue.getMessage()));
				}
			}
			
			throw new MojoFailureException(builder.toString());
		}
		
	}

	private void doGenerate(final Resource resource, Path outputPath)
			throws MojoFailureException, MojoExecutionException {
		String strategyId = loadCustomStrategy(strategy);
		getLog().debug(String.format("Compiling %s using strategy %s ...", resource, strategyId));

		Object result = doCompile(resource, strategyId);

		if (result instanceof CodeContainer) {
			CodeContainer cc = (CodeContainer) result;
			for (CodeFile file : cc.getFiles()) {
				try {
					final Path fileOutputPath = outputPath.resolve(file.getFileName());
					Files.write(fileOutputPath, file.getCode().getBytes());
				} catch (IOException e) {
					throw new MojoFailureException("Failed to write output file " + file.getFileName() + ".\n" + e);
				}
			}
		} else {
			throw new MojoExecutionException("No code generated.");
		}
	}

	private Object doCompile(final Resource resource, String strategyId) {

		try {
			CompilationContext ctx = Compile.createCompilationContext(strategyId, resource.getContents().get(0));
			// the following property setting only applies to strategy
			// 'de.cau.cs.kieler.sccharts.statebased'
			ctx.getStartEnvironment().setProperty(StatebasedCCodeGenerator.LEAN_MODE, true);
			return ctx.compile().getModel();

		} catch (Throwable t) {
			t.printStackTrace();
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
			URI sourceFile = URI.createFileURI(fileName);

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
	 */
	private String loadCustomStrategy(final String strategy) throws MojoFailureException {
		if (Iterators.contains(KiCoolRegistration.getAvailableSystemsIDs(), strategy)) {
			return strategy;
		} else if (!strategy.endsWith(".kico")) {
			throw new MojoFailureException("The extension of the provided strategy file is invalid.");
		} else {
			Path strategyPath = basePath.resolve(strategy);
			if (!Files.exists(strategyPath)) {
				throw new MojoFailureException("The provided strategy file does not exist.");
			} else if (!Files.isRegularFile(strategyPath)) {
				throw new MojoFailureException("The provided strategy file is not a file.");
			} else if (!Files.isReadable(strategyPath)) {
				throw new MojoFailureException("The provided strategy file is not readable.");
			}

			Resource strategyResource = set.getResource(URI.createFileURI(basePath.resolve(strategy).toString()), true);
			Iterable<Diagnostic> issues = Iterables.concat(strategyResource.getErrors(),
					strategyResource.getWarnings());
			StringBuilder issuesText = new StringBuilder();
			for (Diagnostic issue : issues) {
				issuesText.append(String.format("Line %d, column %d: %s%n", issue.getLine(), issue.getColumn(),
						issue.getMessage()));
			}

			EObject root = strategyResource.getContents().get(0);

			if (root instanceof de.cau.cs.kieler.kicool.System) {
				de.cau.cs.kieler.kicool.System sys = (de.cau.cs.kieler.kicool.System) root;
				if (Iterators.contains(KiCoolRegistration.getAvailableSystemsIDs(), strategy)) {
					throw new MojoFailureException("Did load strategy without errors, but the strategy's id "
							+ sys.getId() + "is already used.");
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
