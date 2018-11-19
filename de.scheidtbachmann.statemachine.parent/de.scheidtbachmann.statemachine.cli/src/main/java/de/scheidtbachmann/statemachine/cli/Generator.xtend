package de.scheidtbachmann.statemachine.cli

import com.google.inject.Inject
import com.google.inject.Provider
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.kicool.compilation.Compile
import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup
import java.util.Collections
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Model.CommandSpec
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import picocli.CommandLine.Spec

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
	
	@Spec
	CommandSpec commandSpec
	
	override void run() {
		// implementation of the main command that just shows the global help content
		commandSpec.commandLine.usage(System.out)
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
			val set = resourceSetProvider.get()
			val sourceFile = URI::createFileURI(fileName)
			
			if (set.getURIConverter().exists(sourceFile, Collections::emptyMap())) {
				sourceFileName = fileName
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
				println('''Input file «sourceFileName» not found!''')
		}
		return loaded
	}
	
	static val CMD_VALIDATE = 'validate'
	
	@Command( name = CMD_VALIDATE )
	def void validate(
		@Option(names = '-stdin', description = "Forces the validator to read input from stdIn.")
		boolean stdIn,
		@Parameters(arity = "0..1", paramLabel = "sourceFile", description = "The input state chart file.")
		String sourceFileName
	) {
		if (!stdIn && sourceFileName.nullOrEmpty) {
			commandSpec.subcommands.get(CMD_VALIDATE).usage(System.out)
			
		} else if (sourceFileName.loadResource(stdIn).checkResourceLoaded())
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
	
	@Command( name = CMD_GENERATE )
	def void generate(
		@Option(names = '-stdin', description="Forces the generator to read input from stdIn.")
		boolean stdIn,
		@Parameters(arity = "0..1", paramLabel = "sourceFile", description="The input state chart file.")
		String sourceFileName
	) {
		if (!stdIn && sourceFileName.nullOrEmpty)
			commandSpec.subcommands.get(CMD_GENERATE).usage(System.out)
			
		else if (sourceFileName.loadResource(stdIn).checkResourceLoaded()) {
			if (resource.contents.head === null) {
				println('No content found in the provided resource.')
				
			} else {
				if (!sourceFileName.nullOrEmpty)
					print('''Compiling «sourceFileName»...''')
				else
					print('Compiling...')
				
				//val ctx = Compile.createCompilationContext('de.cau.cs.kieler.sccharts.netlist.java', resource.contents.head)
				val ctx = Compile.createCompilationContext('de.cau.cs.kieler.sccharts.priority.java', resource.contents.head)
				val result = ctx.compile().model
				println('done.')
				switch result {
					CodeContainer:
						println(result.files.map[
							'''
								«fileName»:
								  «code»
							'''
						].join)
					default:
						println('No code generated.')
				}
			}
		}
	}
}
