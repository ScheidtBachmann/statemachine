package de.scheidtbachmann.statemachine.cli

import com.google.inject.Inject
import com.google.inject.Provider
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.kicool.compilation.Compile
import de.cau.cs.kieler.kicool.registration.KiCoolRegistration
import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.nio.file.Path
import java.nio.file.Paths
import java.util.Collections
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Model.CommandSpec
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import picocli.CommandLine.Spec

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

@Command(
	name = 'scc',
	mixinStandardHelpOptions=true,
	version = "hauke's statechart compiler 0.1"
)
class Generator implements Runnable {

	def static void main(String[] args) {
		CommandLine.run(
			new StateMachineStandaloneSetup().createInjectorAndDoEMFRegistration().getInstance(Generator), args
		)
	}
	
	@Accessors(PROTECTED_SETTER)
	CommandLine.Help.Ansi ansi
	
	@Spec
	CommandSpec commandSpec
	
	override void run() {
		// implementation of the main command that just shows the global help content
		commandSpec.commandLine.usage(System.out, ansi)
	}
	
	@Inject
	Provider<ResourceSet> resourceSetProvider
	
	@Inject
	Provider<IResourceValidator> validatorProvider
	
	String sourceFileName
	Resource resource
	
	def loadResource(String fileName, boolean useStdIn) {
		if (resource !== null)
			return resource
		
		else if (useStdIn) {
			resource = resourceSetProvider.get().createResource(
				URI::createFileURI('stdIn.sm')
			)
			resource.load(System.in, emptyMap)
			return resource
		
		} else if (!fileName.nullOrEmpty) {
			sourceFileName = fileName
			val set = resourceSetProvider.get()
			val sourceFile = URI::createFileURI(basePath.resolve(fileName).toString)
			
			if (set.getURIConverter().exists(sourceFile, Collections::emptyMap())) {
				resource = set.getResource(sourceFile, true)
				return resource
			}
		}
	}
	
	def boolean checkResourceLoaded(Resource it) {
		val loaded = it !== null && it.isLoaded
		if (!loaded) {
			if (sourceFileName.nullOrEmpty)
				println('No input file name is given!')
			else
				println('''Input file '«sourceFileName»' not found!''')
		}
		return loaded
	}
	
	static val CMD_VALIDATE = 'validate'
	
	@Command(
		name = CMD_VALIDATE,
		header = 'Check the given input file for syntactic and semantic errors and problems.',
		parameterListHeading = "%nParameters:%n",
		optionListHeading = "%nOptions:%n",
		sortOptions = false
	)
	def void validate(
		@Option(names = '-stdin', description = "Forces the validator to read input from stdIn.")
		boolean stdIn,
		@Parameters(arity = "0..1", paramLabel = "sourceFile", description = "The input state chart file.")
		String sourceFileName
	) {
		if (!stdIn && sourceFileName.nullOrEmpty)
			commandSpec.subcommands.get(CMD_VALIDATE).usage(System.out, ansi)
			
		else if (sourceFileName.loadResource(stdIn).checkResourceLoaded())
			doValidate()
	}
	
	private def doValidate() {
		val issues = validatorProvider.get.validate(resource, CheckMode.ALL, null)
		if (issues.nullOrEmpty) 
			println('Input is fine.')
		
		else {
			val errors = issues.filter[ severity == Severity.ERROR].toList
			val warnings = issues.filter[ severity == Severity.WARNING].toList
			val infos = issues.filter[ severity == Severity.INFO].toList
			print('''
				«IF !errors.isEmpty»
					Validation discovered the following errors:
					«FOR it : errors»
						Line «lineNumber», column «column» «IF syntaxError»(syntax error)«ENDIF»: «message»
					«ENDFOR»	
				«ENDIF»
				«IF !warnings.isEmpty»
					
					Validation discovered the following warnings:
					«FOR it : warnings»
						Line «lineNumber», column «column»: «message»
					«ENDFOR»
				«ENDIF»
				«IF !infos.isEmpty»
					
					Further infos/remarks:
					«FOR it : infos»
						Line «lineNumber», column «column»: «message»
					«ENDFOR»
				«ENDIF»
			''')
		}
	}
	
	static val CMD_GENERATE = 'generate'
	
	static class StrategyCandidates implements Iterable<String> {
		val sortedIds = KiCoolRegistration.availableSystemsIDs.toIterable.sort
		
		override iterator() {
			val sorted = sortedIds.iterator
			sorted.map[
				'%n  ' + if (sorted.hasNext) it else it +', %n  or a path to a custom <.kico> file'
			]
		}
	}
	
	@Command(
		name = CMD_GENERATE,
		separator = " ",
		header = 'Generate executable code corresponding to the given input file.',
		parameterListHeading = "%nParameters:%n",
		optionListHeading = "%nOptions:%n",
		sortOptions = false
	)
	def void generate(
		@Option(
			names = '-stdin',
			description = "Forces the generator to read input from stdIn."
		)
		boolean stdIn,
		@Option(
			names = #[ '-o', '-output'],
			paramLabel = '<path>',
			defaultValue = 'gen',
			description = "The destination folder of the generated artifacts. %nDefault is: ${DEFAULT-VALUE}."
		)
		Path outlet,
		@Option(
			names = '-stdout',
			description = "Forces the generator to write generated content to stdOut."
		)
		boolean stdOut,
		@Option(
			names = #[ '-s', '-strategy'],
			paramLabel = '<strategy>',
			completionCandidates = StrategyCandidates,
			defaultValue = 'de.cau.cs.kieler.sccharts.priority.java',
			description = "The generation strategy to apply. %nCandidates are: ${COMPLETION-CANDIDATES}. %nDefault is: %n   ${DEFAULT-VALUE}."
		)
		String strategy,
		@Parameters(arity = '0..1', paramLabel = '<sourceFile>', description="The input state chart file.")
		String sourceFileName
	) {
		if (!stdIn && sourceFileName.nullOrEmpty)
			commandSpec.subcommands.get(CMD_GENERATE).usage(System.out, ansi)
			
		else if (sourceFileName.loadResource(stdIn).checkResourceLoaded()) {
			if (resource.contents.head === null)
				println('No content found in the provided resource.')
			
			else if (stdOut)
				doGenerate(strategy, null)
			
			else {
				val resolved = basePath.toAbsolutePath.resolve(outlet)
				if (resolved.exists) {
					if (resolved.isDirectory) {
						if (resolved.isWritable) 
							doGenerate(strategy, resolved)
						else {
							println('The provided output path does exist, but writing is not permitted.')
							return
						} 
					} else {
						println('The provided output path exists but is not a directory.')
						return
					}
				} else {
					try {
						resolved.createDirectory()
					} catch (IOException e) {
						println('The provided output path does not exist, creation failed with an exception:')
						println('Reason: ' + e.class.canonicalName + ': ' + e.message)
						return
					}
					doGenerate(strategy, resolved)
				}
			}
		}
	}
	
	// customization hook for testing purposes
	package def getBasePath() {
		Paths.get('')
	}
	
	def doGenerate(String strategy, Path outlet) {
		val strategyId = strategy.loadCustomStrategy()
		
		if (strategyId === null)
			return
		else if (!sourceFileName.nullOrEmpty)
			print('''Compiling «sourceFileName» using strategy '«strategyId»'...''')
		else
			print('''Compiling using strategy '«strategyId»'...''')
		
		val altSysout = new ByteArrayOutputStream()
		val altSyserr = new ByteArrayOutputStream()
		val result = doCompile(strategyId, altSysout, altSyserr)
		
		if (result instanceof CodeContainer) {
			if (outlet === null) {
				println(result.files.map[
					'''
						«fileName»:
						  «code»
					'''
				].join)
			} else {
				for (f : result.files) {
					val res = try {
						outlet.resolve(f.fileName).write(f.code.bytes, CREATE, WRITE)
					} catch (IOException e) {
						e
					} catch (SecurityException e) {
						e
					}
					switch res {
						Path: println('''Wrote «res»''')
						Exception: println('''Writing «f.fileName» failed: «res.message»''')
					}
				}
			}
		
		} else
			println('No code generated.')
		
		if (altSyserr.size !== 0) {
			System.err.printf('%nFailures occured:%n')
			System.err.write(altSyserr.toByteArray)
		}
		
		if (altSysout.size !== 0) {
			System.out.printf('%nFurther notes: occured:%n')
			System.out.write(altSyserr.toByteArray)
		}
	}
	
	def doCompile(String strategyId, ByteArrayOutputStream altSysout, ByteArrayOutputStream altSyserr) {
		val sysoutOri = System.out
		val syserrOri = System.err

		System.setOut(new PrintStream(altSysout))
		System.setErr(new PrintStream(altSyserr))
		
		try {
			val ctx = Compile.createCompilationContext(strategyId, resource.contents.head)
			ctx.compile().model
			
		} catch (Throwable t) {
			t.printStackTrace()
			null
			
		} finally {
			System.setErr(syserrOri)
			System.setOut(sysoutOri)
			println('done.')
		}
	}
	
	/** Checks for an id of a pre-installed compilation strategy and attempts to load the provided strategy description othwise. */
	def loadCustomStrategy(String strategy) {
		if (KiCoolRegistration.availableSystemsIDs.exists[ it == strategy]) {
			return strategy
		
		} else if (!strategy.endsWith('.kico')) {
			println('''The extension of the provided strategy file '«strategy»' is invalid, see help content.''')
			return null
			
		} else {
			val strategyPath = basePath.resolve(strategy)
			if (!strategyPath.exists) {
				println('''The provided strategy file '«strategy»' does not exist.''')
				return null
			} else if (!strategyPath.isRegularFile) {
				println('''The provided strategy file '«strategy»' is not a file.''')
				return null
			} else if (!strategyPath.isReadable) {
				println('''The provided strategy file '«strategy»' is not readable.''')
				return null
			}
			
			val strategyResource = resource.resourceSet.getResource(URI.createFileURI(basePath.resolve(strategy).toString), true)
			val issues = strategyResource.errors + strategyResource.warnings
			val String issuesText = if (issues.iterator.hasNext) {
				'''
					«FOR it: issues»
						Line «line», column «column»: «it.message»
					«ENDFOR»
				'''
			}
			
			switch root: strategyResource.contents.head {
				de.cau.cs.kieler.kicool.System:
					if (KiCoolRegistration.availableSystemsIDs.exists[ it == root.id]) {
						println('''Did load «strategy» without errors, but the strategy's «root.id» is already used.''')
						return null
					
					} else if (issuesText === null) {
						println('''Did load «strategy» without errors.''')
						KiCoolRegistration.registerTemporarySystem(root)
						return root.id
					
					} else {
						print('''
							Did load «strategy» with errors:
							«issuesText»
						''')
						return null
					}
				default: {
					print('''
						Could not find valid compilation strategy description in «strategy».
						«IF issuesText !== null»
							Found the following problems:
							«issuesText»
						«ENDIF»
					''')
					return null
				}
			}
		}
	}
}
