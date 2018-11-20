package de.scheidtbachmann.statemachine.cli

import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup
import java.io.ByteArrayOutputStream
import java.io.PrintStream
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Assert
import org.junit.ComparisonFailure
import org.junit.Test
import picocli.CommandLine

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

class GeneratorTest {
	
	static val UTF8 = StandardCharsets.UTF_8.name
	static val injector = new StateMachineStandaloneSetup().createInjectorAndDoEMFRegistration()
	
	static class TestableGenerator extends Generator {
		
		@Accessors
		val Path basePath
		
		new(Path basePath) {
			this.basePath = basePath
			injector.injectMembers(this)
		}
		
	}
	
	val sysout = new ByteArrayOutputStream
	
	new() {
		System.setOut(new PrintStream(sysout))
	}
	
	def assertSysOutEquals(String expected) {
		Assert.assertEquals(expected, sysout.toString(UTF8))
	}
	
	def assertSysOutStartsWith(String expected) {
		switch actual: sysout.toString(UTF8) {
			String:
				if (!actual.startsWith(expected.trim))
					throw new ComparisonFailure('', expected, actual)
			default:
				Assert.fail('Obtained result is not of type String.')
		}
	}
	
	
	@Test
	def testNoArgs() {
		CommandLine.run(new TestableGenerator(Paths.get('')))
		assertSysOutEquals('''
			Usage: scc [-hV] [COMMAND]
			  -h, --help      Show this help message and exit.
			  -V, --version   Print version information and exit.
			Commands:
			  generate  Generate executable code corresponding to the given input file.
			  validate  Check the given input file for syntactic and semantic errors and
			              problems.
		''')
	}

	@Test
	def testGenerate() {
		CommandLine.run(new TestableGenerator(Paths.get('')), 'generate')
		assertSysOutEquals('''
			Generate executable code corresponding to the given input file.
			Usage: scc generate [-stdin] [-stdout] [-o <path>] [-s <strategy>]
			                    [<sourceFile>]
			
			Parameters:
			      [<sourceFile>]         The input state chart file.
			
			Options:
			      -stdin                 Forces the generator to read input from stdIn.
			  -o, -output <path>         The destination folder of the generated artifacts.
			                             Default is: gen.
			      -stdout                Forces the generator to write generated content to
			                               stdOut.
			  -s, -strategy <strategy>   The generation strategy to apply.
			                             Candidates are:
			                               de.cau.cs.kieler.sccharts.core,
			                               de.cau.cs.kieler.sccharts.core.core,
			                               de.cau.cs.kieler.sccharts.dataflow,
			                               de.cau.cs.kieler.sccharts.dataflow.lustre,
			                               de.cau.cs.kieler.sccharts.extended,
			                               de.cau.cs.kieler.sccharts.extended.core,
			                               de.cau.cs.kieler.sccharts.netlist,
			                               de.cau.cs.kieler.sccharts.netlist.java,
			                               de.cau.cs.kieler.sccharts.netlist.java.tts,
			                               de.cau.cs.kieler.sccharts.netlist.sccp,
			                               de.cau.cs.kieler.sccharts.netlist.simple,
			                               de.cau.cs.kieler.sccharts.netlist.tts,
			                               de.cau.cs.kieler.sccharts.priority,
			                               de.cau.cs.kieler.sccharts.priority.java,
			                               de.cau.cs.kieler.sccharts.priority.java.tts,
			                               de.cau.cs.kieler.sccharts.scssa,
			                               de.cau.cs.kieler.sccharts.statebased,
			                               de.cau.cs.kieler.scg.netlist,
			                               de.cau.cs.kieler.scg.priority,
			                               or a path to a custom <.kico> file.
			                             Default is:
			                                de.cau.cs.kieler.sccharts.priority.java.
		''')
	}
	
	@Test
	def testGenerateNonExistingInput() {
		CommandLine.run(new TestableGenerator(Paths.get('')), 'generate', 'foo')
		assertSysOutEquals('''
			Input file 'foo' not found!
		''')
	}
	
	@Test
	def testGenerateEmptyInput() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ '' ], CREATE, WRITE)
		
		val genPath = Files.createDirectory(basePath.resolve('gen'))
		genPath.toFile.setWritable(false, false)
		
		CommandLine.run(new TestableGenerator(basePath), 'generate', fileName)
		assertSysOutEquals('''
			No content found in the provided resource.
		''')
	}
	
	@Test
	def testGenerateOutputNonWritable01() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val genPath = Files.createDirectory(basePath.resolve('gen'))
		genPath.toFile.setWritable(false, false)
		
		CommandLine.run(new TestableGenerator(basePath), 'generate', '-o gen',fileName)
		assertSysOutEquals('''
			The provided output path does exist, but writing is not permitted.
		''')
	}
	
	@Test
	def testGenerateOutputNonWritable02() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val genPath = Files.createDirectory(basePath.resolve('gen'))
		genPath.toFile.setWritable(false, false)
		
		CommandLine.run(new TestableGenerator(basePath), 'generate', '-o gen/gen',fileName)
		assertSysOutStartsWith('''
			The provided output path does not exist, creation failed with an exception:
			Reason: java.nio.file.AccessDeniedException:
		''')
	}
}