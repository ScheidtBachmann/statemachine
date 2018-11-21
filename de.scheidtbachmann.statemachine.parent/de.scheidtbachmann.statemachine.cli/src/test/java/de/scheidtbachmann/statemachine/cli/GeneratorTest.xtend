package de.scheidtbachmann.statemachine.cli

import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.nio.charset.StandardCharsets
import java.nio.file.FileVisitResult
import java.nio.file.Files
import java.nio.file.NoSuchFileException
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.SimpleFileVisitor
import java.nio.file.attribute.BasicFileAttributes
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
	val syserr = new ByteArrayOutputStream
	
	new() {
		System.setOut(new PrintStream(sysout))
		System.setErr(new PrintStream(syserr))
	}
	
	@Test
	def void testNoArgs() {
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
	def void testValidate() {
		runValidate(Paths.get(''))
		
		assertSysOutEquals('''
			Check the given input file for syntactic and semantic errors and problems.
			Usage: scc validate [-stdin] [sourceFile]
			
			Parameters:
			      [sourceFile]   The input state chart file.
			
			Options:
			      -stdin         Forces the validator to read input from stdIn.
		''')
	}
	
	@Test
	def void testValidateStdIn() {
		System.setIn(new ByteArrayInputStream('scchart foo { state }'.bytes))
		
		runValidate(Paths.get(''), '-stdin')
		
		assertSysOutEquals('''
			Validation discovered the following errors:
			Line 1, column 21 (syntax error): missing RULE_ID at '}'
			Line 1, column 15 : Every region must have an initial state.
			
			Validation discovered the following warnings:
			Line 1, column 15: The state is not reachable.
		''')
	}
	
	@Test
	def void testValidateFile() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { state }' ], CREATE, WRITE)
		
		runValidate(basePath, fileName)
		
		assertSysOutEquals('''
			Validation discovered the following errors:
			Line 1, column 21 (syntax error): missing RULE_ID at '}'
			Line 1, column 15 : Every region must have an initial state.
			
			Validation discovered the following warnings:
			Line 1, column 15: The state is not reachable.
		''')
		
		basePath.deleteDirRecursively
	}
	
	
	@Test
	def void testGenerate() {
		runGenerate(Paths.get(''))
		
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
	def void testGenerateNonExistingInput() {
		runGenerate(Paths.get(''), 'foo')
		
		assertSysOutEquals('''
			Input file 'foo' not found!
		''')
	}
	
	@Test
	def void testGenerateEmptyInput() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ '' ], CREATE, WRITE)
		
		runGenerate(basePath, fileName)
		
		assertSysOutEquals('''
			No content found in the provided resource.
		''')

		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputStdOut() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		runGenerate(basePath, '-stdout', fileName)
		
		assertSysOutStartsWith('''
			Compiling foo.sm using strategy 'de.cau.cs.kieler.sccharts.priority.java'...done.
			foo.java:
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputNonWritable01() {
		val fileName = 'foo.sm'
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		Files.createDirectory(basePath.resolve('gen')).toFile.setWritable(false, false)
		
		runGenerate(basePath, '-o gen', fileName)
		
		assertSysOutEquals('''
			The provided output path does exist, but writing is not permitted.
		''')

		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputNonWritable02() {
		val fileName = 'foo.sm'
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		Files.createDirectory(basePath.resolve('gen')).toFile.setWritable(false, false)
		
		runGenerate(basePath, '-o gen/gen', fileName)
		
		assertSysOutStartsWith('''
			The provided output path does not exist, creation failed with an exception:
			Reason: java.nio.file.AccessDeniedException:
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputStrategy() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		runGenerate(basePath, '-stdout', '-s de.cau.cs.kieler.sccharts.priority', fileName)
		
		assertSysOutStartsWith('''
			Compiling foo.sm using strategy 'de.cau.cs.kieler.sccharts.priority'...done.
			foo.c:
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategy() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		basePath.resolve(strategyFileName).write(
			#[ 'public system my.java label "foo" system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
		)
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutStartsWith('''
			Did load bar.kico without errors.
			Compiling foo.sm using strategy 'my.java'...done.
			foo.java:
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyMissing() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			The provided strategy file 'bar.kico' does not exist.
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyWrongExtenstion() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kic'
		basePath.resolve(strategyFileName).createFile()
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			The extension of the provided strategy file 'bar.kic' is invalid, see help content.
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyIsDirectory() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		basePath.resolve(strategyFileName).createDirectory()
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			The provided strategy file 'bar.kico' is not a file.
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyUnreadable() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		basePath.resolve(strategyFileName).write(
			#[ 'public system my.java label "foo" system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
		).toFile.setReadable(false, false)
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			The provided strategy file 'bar.kico' is not readable.
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyEmpty() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		basePath.resolve(strategyFileName).write(#[ '' ], CREATE, WRITE)
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			Could not find valid compilation strategy description in bar.kico.
			Found the following problems:
			Line 1, column 1: mismatched input '<EOF>' expecting 'system'
		''')
		
		basePath.deleteDirRecursively
	}
	
	@Test
	def void testGenerateOutputCustomStrategyErroneous() {
		val basePath = Files.createTempDirectory('stateChartGenTesting')
		val fileName = 'foo.sm'
		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
		
		val strategyFileName = 'bar.kico'
		basePath.resolve(strategyFileName).write(
			#[ 'public system my.java /* label "foo" */ system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
		)
		
		runGenerate(basePath, '-stdout', '-s', strategyFileName, fileName)
		
		assertSysOutEquals('''
			Did load bar.kico with errors:
			Line 1, column 41: mismatched input 'system' expecting 'label'
		''')
		
		basePath.deleteDirRecursively
	}
	
	
	// ----------------------------------------------------------------------------------------------
	
	private def runValidate(Path basePath, String... args) {
		CommandLine.run(new TestableGenerator(basePath), #[ 'validate'] + args)
	}
	
	private def runGenerate(Path basePath, String... args) {
		CommandLine.run(new TestableGenerator(basePath), #[ 'generate'] + args)
	}
	
	def assertSysOutEquals(String expected) {
		Assert.assertEquals('Found outputs in stdErr:', '', syserr.toString)
		Assert.assertEquals(expected, sysout.toString(UTF8))
	}
	
	def assertSysOutStartsWith(String expected) {
		Assert.assertEquals('Found outputs in stdErr:', '', syserr.toString)
		switch actual: sysout.toString(UTF8) {
			String:
				if (!actual.startsWith(expected.trim))
					throw new ComparisonFailure('', expected, actual)
			default:
				Assert.fail('Obtained result is not of type String.')
		}
	}
	
	private def deleteDirRecursively(Path path) {
		try {
			path.walkFileTree(new SimpleFileVisitor<Path>() {
				override visitFile(Path file, BasicFileAttributes attrs) throws IOException {
					Files.delete(file)
					return FileVisitResult.CONTINUE
				}
				
				override postVisitDirectory(Path dir, IOException exc) throws IOException {
					Files.delete(dir)
					return FileVisitResult.CONTINUE
				}
			})
		} catch (NoSuchFileException nsfe) {
			return
		}
	}
}