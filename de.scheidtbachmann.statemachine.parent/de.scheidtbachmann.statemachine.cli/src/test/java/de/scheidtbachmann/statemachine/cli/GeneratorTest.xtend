package de.scheidtbachmann.statemachine.cli

import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup
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
import org.junit.After
import org.junit.Assert
import org.junit.Assume
import org.junit.ComparisonFailure
import org.junit.Test
import picocli.CommandLine

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

class GeneratorTest {
  
  static val UTF8 = StandardCharsets.UTF_8.name
  static val injector = new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration()
  
  static class TestableGenerator extends Generator {
    
    @Accessors
    val Path basePath
    
    new(Path basePath) {
      this.basePath = basePath
      this.ansi = CommandLine.Help.Ansi.OFF
      injector.injectMembers(this)
    }
    
  }
  
  val sysout = new ByteArrayOutputStream
  val syserr = new ByteArrayOutputStream
  
  Path basePath
  
  new() {
    System.setOut(new PrintStream(sysout))
    System.setErr(new PrintStream(syserr))
  }
  
  @Test
  def void testNoArgs() {
    commandLineRun(Paths.get(''))
    
    assertSysOutEquals('''
      Scheidt & Bachmann StateChart Compiler
      Usage: scc [-hV] [COMMAND]
        -h, --help      Show this help message and exit.
        -V, --version   Print version information and exit.
      Commands:
        draw      Draw the state chart specified in given input file.
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
      Usage: scc validate [--stdin] [sourceFile]
      
      Parameters:
            [sourceFile]   The input state chart file.
      
      Options:
            --stdin        Forces the validator to read input from stdIn.
    ''')
  }
  
  @Test
  def void testValidateStdIn() {
    System.setIn(new ByteArrayInputStream('scchart foo { state }'.bytes))
    
    runValidate(Paths.get(''), '--stdin')
    
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
    basePath = Files.createTempDirectory('stateChartGenTesting')
    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { state }' ], CREATE, WRITE)
    
    runValidate(basePath, fileName)
    
    assertSysOutEquals('''
      Validation discovered the following errors:
      Line 1, column 21 (syntax error): missing RULE_ID at '}'
      Line 1, column 15 : Every region must have an initial state.
      	
      Validation discovered the following warnings:
      Line 1, column 15: The state is not reachable.
    ''')
  }

  @Test
  def void testDraw() {
    runDraw(Paths.get(''))
    
    assertSysOutEquals('''
      Draw the state chart specified in given input file.
      Usage: scc draw [--stdin] [-f <format>] [-o <path>] [<sourceFile>]
      
      Parameters:
            [<sourceFile>]      The input state chart file.
      
      Options:
            --stdin             Forces the artist to read input from stdIn.
        -f, --format <format>   The desired output format of the diagram drawings.
                                Candidates are: bmp, jpeg, png, svg.
                                Default is: png.
        -o, --output <path>     The destination folder of the drawn diagram pages.
                                Default is: diagrams.
    ''')
  }
  
  @Test
  def void testDrawEmptyInputStdIn() {
    System.setIn(new ByteArrayInputStream(#[]))
    
    runDraw(Paths.get(''), '--stdin')
    
    assertSysOutStartsWith('''
      No content found in the provided resource.
    ''')
  }
  
//	@Test
//	def void testDrawStdIn() {
//		System.setIn(new ByteArrayInputStream('scchart foo { initial state foo }'.bytes))
//		
//		val basePath = Files.createTempDirectory('stateChartGenTesting')
//		runDraw(basePath, '-stdin', '-diagModelOnly')
//		
//		val diagramModelFile = basePath.resolve('diagrams/foo').resolve(DiagramModelGenerator.DIAGRAM_MODEL_FILE_NAME)
//		
//		assertSysOutEquals('''
//			Creating diagram model...done.
//		''')
//		
//		assertFileEquals(diagramModelFile, '''
//			function getDiagramModel() {
//			  return {
//			    "id": "graph",
//			    "type": "graph",
//			    "layoutOptions": {
//			      "hAlign": "left",
//			      "hGap": 5,
//			      "paddingLeft": 7,
//			      "paddingRight": 7,
//			      "paddingTop": 7,
//			      "paddingBottom": 7
//			    },
//			    "children": [
//			      {
//			        "id": "state-0",
//			        "type": "node:state",
//			        "layout": "vbox",
//			        "layoutOptions": {
//			          "paddingLeft": 10,
//			          "paddingRight": 10,
//			          "paddingTop": 8,
//			          "paddingBottom": 8,
//			          "resizeContainer": true
//			        },
//			        "children": [
//			          {
//			            "text": "foo",
//			            "id": "state-0-label-0",
//			            "type": "label:stateLabel"
//			          }
//			        ]
//			      }
//			    ]
//			  };
//			}
//		''')
//		
//		basePath.deleteDirRecursively
//	}
//	
//	@Test
//	def void testDrawFile() {

//		val fileName = 'foo.sctx'
//		val basePath = Files.createTempDirectory('stateChartGenTesting')
//		basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
//		
//		runDraw(basePath, fileName, '-diagModelOnly')
//		
//		val diagramModelFile = basePath.resolve('diagrams/foo').resolve(DiagramModelGenerator.DIAGRAM_MODEL_FILE_NAME)
//		
//		assertSysOutEquals('''

//			Creating diagram model for foo.sctx...done.
//		''')
//		
//		assertFileEquals(diagramModelFile, '''
//			function getDiagramModel() {
//			  return {
//			    "id": "graph",
//			    "type": "graph",
//			    "layoutOptions": {
//			      "hAlign": "left",
//			      "hGap": 5,
//			      "paddingLeft": 7,
//			      "paddingRight": 7,
//			      "paddingTop": 7,
//			      "paddingBottom": 7
//			    },
//			    "children": [
//			      {
//			        "id": "state-0",
//			        "type": "node:state",
//			        "layout": "vbox",
//			        "layoutOptions": {
//			          "paddingLeft": 10,
//			          "paddingRight": 10,
//			          "paddingTop": 8,
//			          "paddingBottom": 8,
//			          "resizeContainer": true
//			        },
//			        "children": [
//			          {
//			            "text": "foo",
//			            "id": "state-0-label-0",
//			            "type": "label:stateLabel"
//			          }
//			        ]
//			      }
//			    ]
//			  };
//			}
//		''')
//		
//		basePath.deleteDirRecursively
//	}
  
  
  @Test
  def void testGenerate() {
    runGenerate(Paths.get(''))
    
    assertSysOutEquals('''
      Generate executable code corresponding to the given input file.
      
      Parameters:
            [<sourceFile>]     The input state chart file.
      
      Options:
            --stdin            Forces the generator to read input from stdIn.
        -o, --output <path>    The destination folder of the generated artifacts.
                               Default is: gen.
            --stdout           Forces the generator to write generated content to
                                 stdOut.
        -s, --strategy <strategy>
                               The generation strategy to apply.
                               Candidates are:
                                 de.cau.cs.kieler.c.sccharts.dataflow,
                                 de.cau.cs.kieler.kicool.identity,
                                 de.cau.cs.kieler.kicool.identity.dynamic,
                                 de.cau.cs.kieler.sccharts.causalView,
                                 de.cau.cs.kieler.sccharts.core,
                                 de.cau.cs.kieler.sccharts.core.core,
                                 de.cau.cs.kieler.sccharts.csv,
                                 de.cau.cs.kieler.sccharts.dataflow,
                                 de.cau.cs.kieler.sccharts.dataflow.lustre,
                                 de.cau.cs.kieler.sccharts.expansion.only,
                                 de.cau.cs.kieler.sccharts.extended,
                                 de.cau.cs.kieler.sccharts.extended.core,
                                 de.cau.cs.kieler.sccharts.interactiveScheduling,
                                 de.cau.cs.kieler.sccharts.netlist,
                                 de.cau.cs.kieler.sccharts.netlist.arduino.deploy,
                                 de.cau.cs.kieler.sccharts.netlist.guardOpt,
                                 de.cau.cs.kieler.sccharts.netlist.java,
                                 de.cau.cs.kieler.sccharts.netlist.nxj.deploy,
                                 de.cau.cs.kieler.sccharts.netlist.nxj.deploy.
                                 rconsole,
                                 de.cau.cs.kieler.sccharts.netlist.promela,
                                 de.cau.cs.kieler.sccharts.netlist.references,
                                 de.cau.cs.kieler.sccharts.netlist.sccp,
                                 de.cau.cs.kieler.sccharts.netlist.simple,
                                 de.cau.cs.kieler.sccharts.netlist.smv,
                                 de.cau.cs.kieler.sccharts.netlist.vhdl,
                                 de.cau.cs.kieler.sccharts.priority,
                                 de.cau.cs.kieler.sccharts.priority.java,
                                 de.cau.cs.kieler.sccharts.priority.java.legacy,
                                 de.cau.cs.kieler.sccharts.priority.legacy,
                                 de.cau.cs.kieler.sccharts.scssa,
                                 de.cau.cs.kieler.sccharts.simulation.netlist.c,
                                 de.cau.cs.kieler.sccharts.simulation.netlist.java,
                                 de.cau.cs.kieler.sccharts.simulation.priority.c,
                                 de.cau.cs.kieler.sccharts.simulation.priority.c.
                                 legacy,
                                 de.cau.cs.kieler.sccharts.simulation.priority.java,
                                 de.cau.cs.kieler.sccharts.simulation.priority.java.
                                 legacy,
                                 de.cau.cs.kieler.sccharts.simulation.statebased.c,
                                 de.cau.cs.kieler.sccharts.simulation.statebased.lean.
                                 c,
                                 de.cau.cs.kieler.sccharts.simulation.tts.netlist.c,
                                 de.cau.cs.kieler.sccharts.simulation.tts.netlist.
                                 java,
                                 de.cau.cs.kieler.sccharts.simulation.tts.priority.c,
                                 de.cau.cs.kieler.sccharts.simulation.tts.priority.c.
                                 legacy,
                                 de.cau.cs.kieler.sccharts.simulation.tts.priority.
                                 java,
                                 de.cau.cs.kieler.sccharts.simulation.tts.priority.
                                 java.legacy,
                                 de.cau.cs.kieler.sccharts.simulation.tts.statebased.
                                 c,
                                 de.cau.cs.kieler.sccharts.simulation.tts.statebased.
                                 lean.c,
                                 de.cau.cs.kieler.sccharts.statebased,
                                 de.cau.cs.kieler.scg.netlist,
                                 de.cau.cs.kieler.scg.priority,
                                 de.cau.cs.kieler.scl.netlist.c,
                                 de.cau.cs.kieler.scl.netlist.java,
                                 de.cau.cs.kieler.scl.priority.c,
                                 de.cau.cs.kieler.scl.priority.java,
                                 de.cau.cs.kieler.scl.scc,
                                 de.cau.cs.kieler.scl.simulation.netlist.c,
                                 de.cau.cs.kieler.scl.simulation.netlist.java,
                                 de.cau.cs.kieler.scl.simulation.priority.c,
                                 de.cau.cs.kieler.scl.simulation.priority.java,
                                 de.cau.cs.kieler.scl.ssa.scssa,
                                 de.cau.cs.kieler.scl.ssa.scssa.sccp,
                                 de.cau.cs.kieler.scl.ssa.scssa.simple,
                                 de.cau.cs.kieler.scl.ssa.seq,
                                 de.scheidtbachmann.statemachine.codegen.statebased.
                                 lean.cpp.template,
                                 de.scheidtbachmann.statemachine.codegen.statebased.
                                 lean.java.template,
                                 de.scheidtbachmann.statemachine.codegen.statebased.
                                 lean.java.template.selective,
                                 or a path to a custom <.kico> file.
                               Default is:
                                 de.cau.cs.kieler.sccharts.statebased.

            --select <model>   The parts of the model that should be taken from the
                                 input file
    ''')
  }
  
  
  @Test
  def void testGenerateInputStdInOutputStdOut() {
    System.setIn(new ByteArrayInputStream('scchart foo { initial state foo }'.bytes))
    
    runGenerate(basePath, '--stdin', '--stdout')
    
    assertSysOutStartsWith('''
      Compiling using strategy 'de.cau.cs.kieler.sccharts.statebased'...done.
      foo.c:
    ''')
  }
  
  @Test
  def void testGenerateEmptyInputStdInOutputStdOut() {
    System.setIn(new ByteArrayInputStream(#[]))
    
    runGenerate(basePath, '--stdin', '--stdout')
    
    assertSysOutStartsWith('''
      No content found in the provided resource.
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
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ '' ], CREATE, WRITE)
    
    runGenerate(basePath, fileName)
    
    assertSysOutEquals('''
      No content found in the provided resource.
    ''')
  }
  
  @Test
  def void testGenerateOutputStdOut() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    runGenerate(basePath, '--stdout', fileName)
    
    assertSysOutStartsWith('''

      Compiling foo.sctx using strategy 'de.cau.cs.kieler.sccharts.statebased'...done.
      foo.c:
    ''')
  }
  
  @Test
  def void testGenerateOutputNonWritable01() {
    Assume.assumeTrue(!isWindows)
    
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    Files.createDirectory(basePath.resolve('gen')).toFile.setWritable(false, false)
    
    runGenerate(basePath, '-o gen', fileName)
    
    assertSysOutEquals('''
      The provided output path does exist, but writing is not permitted.
    ''')
  }
  
  @Test
  def void testGenerateOutputNonWritable02() {
    Assume.assumeTrue(!isWindows)
    
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    Files.createDirectory(basePath.resolve('gen')).toFile.setWritable(false, false)
    
    runGenerate(basePath, '-o gen/gen', fileName)
    
    assertSysOutStartsWith('''
      The provided output path does not exist, creation failed with an exception:
      Reason: java.nio.file.AccessDeniedException:
    ''')
  }
  
  @Test
  def void testGenerateOutputStrategy() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    runGenerate(basePath, '--stdout', '-s de.cau.cs.kieler.sccharts.priority', fileName)
    
    assertSysOutStartsWith('''

      Compiling foo.sctx using strategy 'de.cau.cs.kieler.sccharts.priority'...done.
      foo.c:
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategy() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    basePath.resolve(strategyFileName).write(
      #[ 'public system my.java label "foo" system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
    )
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutStartsWith('''
      Did load bar.kico without errors.

      Compiling foo.sctx using strategy 'my.java'...done.
      foo.java:
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyMissing() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      The provided strategy file 'bar.kico' does not exist.
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyWrongExtenstion() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kic'
    basePath.resolve(strategyFileName).createFile()
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      The extension of the provided strategy file 'bar.kic' is invalid, see help content.
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyIsDirectory() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    basePath.resolve(strategyFileName).createDirectory()
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      The provided strategy file 'bar.kico' is not a file.
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyUnreadable() {
    Assume.assumeTrue(!isWindows)
    
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    basePath.resolve(strategyFileName).write(
      #[ 'public system my.java label "foo" system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
    ).toFile.setReadable(false, false)
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      The provided strategy file 'bar.kico' is not readable.
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyEmpty() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    basePath.resolve(strategyFileName).write(#[ '' ], CREATE, WRITE)
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      Could not find valid compilation strategy description in bar.kico.
      Found the following problems:
      Line 1, column 1: mismatched input '<EOF>' expecting 'system'
    ''')
  }
  
  @Test
  def void testGenerateOutputCustomStrategyErroneous() {
    basePath = Files.createTempDirectory('stateChartGenTesting')

    val fileName = 'foo.sctx'
    basePath.resolve(fileName).write(#[ 'scchart foo { initial state foo }' ], CREATE, WRITE)
    
    val strategyFileName = 'bar.kico'
    basePath.resolve(strategyFileName).write(

      #[ 'public system myerror.java /* label "foo" */ system de.cau.cs.kieler.sccharts.priority.java' ], CREATE, WRITE
    )
    
    runGenerate(basePath, '--stdout', '-s', strategyFileName, fileName)
    
    assertSysOutEquals('''
      Did load bar.kico with errors:

      Line 1, column 46: mismatched input 'system' expecting 'label'
    ''')
  }
  
  // ----------------------------------------------------------------------------------------------
  
  @After

  def void removeBaseDir() {
    basePath?.deleteDirRecursively
    basePath = null
  }
  
  // ----------------------------------------------------------------------------------------------

  private def commandLineRun(Path basePath, String... args) {

    val CommandLine cmd = new CommandLine(new TestableGenerator(basePath)) // 
                            .setColorScheme(CommandLine.Help.defaultColorScheme(CommandLine.Help.Ansi.OFF))
    cmd.execute(args)
  }
  
  private def runValidate(Path basePath, String... args) {
    commandLineRun(basePath, #[ 'validate'] + args)
  }
  
  private def runDraw(Path basePath, String... args) {
    commandLineRun(basePath, #[ 'draw'] + args)
  }
  
  private def runGenerate(Path basePath, String... args) {
    commandLineRun(basePath, #[ 'generate'] + args)
  }
  
  private def isWindows() {
    System.getProperty('os.name').toLowerCase.contains('win')
  }
  
//  private def assertFileEquals(Path file, String expected) {
//    Assert.assertTrue("Diagram model doesn't exist at the expected location.", file.exists)
//    
//    val diagramModel = new String(file.readAllBytes, StandardCharsets.UTF_8)
//    Assert.assertEquals(expected, diagramModel)
//  }
		
  private def assertSysOutEquals(String expected) {
    Assert.assertEquals('Found outputs in stdErr:', '', syserr.toString)
    Assert.assertEquals(expected, sysout.toString(UTF8))
  }
  
  private def assertSysOutStartsWith(String expected) {
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