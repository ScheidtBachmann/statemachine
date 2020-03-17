package de.scheidtbachmann.statemachine.cli

import com.google.inject.Inject
import com.google.inject.Injector
import com.google.inject.Provider
import de.cau.cs.kieler.kicool.compilation.CodeContainer
import de.cau.cs.kieler.kicool.compilation.Compile
import de.cau.cs.kieler.kicool.registration.KiCoolRegistration
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeGenerator
import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup
import de.cau.cs.kieler.scg.ScgPackage
import de.scheidtbachmann.statemachine.transformators.ModelSelect
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.net.URLClassLoader
import java.nio.file.Path
import java.nio.file.Paths
import java.util.Collections
import java.util.Map
import java.util.function.Function
import org.eclipse.core.runtime.IStatus
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.util.Wrapper
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Model.CommandSpec
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import picocli.CommandLine.Spec

import static extension java.nio.file.Files.*
import de.cau.cs.kieler.sccharts.processors.transformators.ModelSelect

@Command(name='scc', header="Scheidt & Bachmann StateChart Compiler", version="0.2.0", mixinStandardHelpOptions=true)
class Generator implements Runnable {

  static val CMD_VALIDATE = 'validate'
  static val CMD_DRAW = 'draw'
  static val CMD_GENERATE = 'generate'

  @Accessors(PROTECTED_SETTER)
  CommandLine.Help.Ansi ansi = CommandLine.Help.Ansi.AUTO

  @Spec
  CommandSpec commandSpec

  String sourceFileName

  @Inject
  Provider<ResourceSet> resourceSetProvider
  Resource resource

  @Inject
  Provider<IResourceValidator> validatorProvider

  // customization hook for testing purposes
  package def getBasePath() {
    Paths.get('')
  }

  /**
   * External entry point. Delegates to picoCLI more or less immediately.
   */
  def static void main(String[] args) {
    // Trigger injection before the tool runs
    val Injector injector = new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration
    ScgPackage.eINSTANCE.eClass
    val CommandLine cmd = new CommandLine(injector.getInstance(Generator))
    val exitCode = cmd.execute(args)
    System.exit(exitCode)
  }

  override void run() {
    // implementation of the main command that just shows the global help content
    commandSpec.commandLine.usage(System.out, ansi)
  }

  /*
   * ------------------------
   * Resource helper functions
   * ------------------------
   */
  /**
   * Load a file resource or load a resource from stdin.
   */
  def loadResource(String fileName, boolean useStdIn) {
    if (resource !== null) {
      // Only load a resource if no resource has been loaded before
      return resource
    } else if (useStdIn) {
      // Load resource from stdin. Simulate a file resource by calling the 'file' stdIn.sm
      resource = resourceSetProvider.get().createResource(
        URI::createFileURI('stdIn.sctx')
      )
      resource.load(System.in, emptyMap)
      return resource
    } else if (!fileName.nullOrEmpty) {
      // Load resource from file
      sourceFileName = fileName
      // Resolve the injected ResourceSet
      val set = resourceSetProvider.get()
      // Create file URI from basePath and fileName
      val sourceFile = URI::createFileURI(basePath.resolve(fileName).toString)

      // Make sure the source file does indeed exist
      if (set.getURIConverter().exists(sourceFile, Collections::emptyMap())) {
        // Load the resource (through all the Ecore Black Magic)
        resource = set.getResource(sourceFile, true)
        return resource
      }
    }
  }

  /**
   * Check whether the resource is indeed fully loaded
   */
  def boolean checkResourceLoaded(Resource res) {
    val loaded = (res !== null && res.isLoaded)
    if (!loaded) {
      if (sourceFileName.nullOrEmpty) {
        println('No input file name is given!')
      } else {
        println('''Input file '«sourceFileName»' not found!''')
      }
    }
    return loaded
  }

  /*
   * ------------------------
   * VALIDATION
   * ------------------------
   */
  /**
   * Definition of the validation command.
   * Has an option to read from stdin and takes a filename to read from if stdin is not used.
   */
  @Command(name=CMD_VALIDATE, header='Check the given input file for syntactic and semantic errors and problems.', parameterListHeading="%nParameters:%n", optionListHeading="%nOptions:%n", sortOptions=false)
  def void validate(
    @Option(names='--stdin', description="Forces the validator to read input from stdIn.")
    boolean stdIn,
    @Parameters(arity="0..1", paramLabel="sourceFile", description="The input state chart file.")
    String sourceFileName
  ) {
    // Check if the combination of option and/or parameter are valid
    if (!stdIn && sourceFileName.nullOrEmpty) {
      // Not reading from stdin but also no filename given -> print usage and be done with it
      commandSpec.subcommands.get(CMD_VALIDATE).usage(System.out, ansi)
    } else {
      // Parameters make sense. Try to load the file and validate if successful
      if (sourceFileName.loadResource(stdIn).checkResourceLoaded()) {
        doValidate()
      }
    }
  }

  /**
   * Do the real validation work.
   */
  private def doValidate() {
    // Resolve the injected provider for a validator
    val IResourceValidator validator = validatorProvider.get
    // Validate the resource and gather all the issues
    val issues = validator.validate(resource, CheckMode.ALL, null)
    if (issues.nullOrEmpty) {
      // Validation successful. We happy!
      println('Input is fine.')
    } else {
      // Something is not fine. Filter various severities
      val errors = issues.filter[severity == Severity.ERROR].toList
      val warnings = issues.filter[severity == Severity.WARNING].toList
      val infos = issues.filter[severity == Severity.INFO].toList
      // Print all the issues to stdout
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

  /*
   * ------------------------
   * CODE GENERATION
   * ------------------------
   */
  /**
   * Definition of the generation command.
   * Takes options for reading from stdin, writing to stdout, changing the output folder,
   * and loading a user-supplied strategy.
   * Takes a filename as optional parameter if stdin is not used for reading.
   */
  @Command(name=CMD_GENERATE, separator=" ", header='Generate executable code corresponding to the given input file.', parameterListHeading="%nParameters:%n", optionListHeading="%nOptions:%n", sortOptions=false)
  def void generate(
    @Option(names='--stdin', description="Forces the generator to read input from stdIn.")
    boolean stdIn,
    @Option(names=#['-o',
      '--output'], paramLabel='<path>', defaultValue='gen', description="The destination folder of the generated artifacts. %nDefault is: ${DEFAULT-VALUE}.")
    Path outlet,
    @Option(names='--stdout', description="Forces the generator to write generated content to stdOut.")
    boolean stdOut,
    @Option(names=#['-s',
      '--strategy'], paramLabel='<strategy>', completionCandidates=StrategyCandidates, defaultValue='de.cau.cs.kieler.sccharts.statebased', description="The generation strategy to apply. %nCandidates are: ${COMPLETION-CANDIDATES}. %nDefault is: %n  ${DEFAULT-VALUE}.")
    String strategy,
    @Option(names='--select', description="The parts of the model that should be taken from the input file", paramLabel='<model>')
    String selectedCharts,
    @Parameters(arity='0..1', paramLabel='<sourceFile>', description="The input state chart file.")
    String sourceFileName
  ) {
    // Check if the options/parameters make sense
    if (!stdIn && sourceFileName.nullOrEmpty) {
      // Not reading from stdin but also no filename given. Print usage and be done with it.
      commandSpec.subcommands.get(CMD_GENERATE).usage(System.out, ansi)
    } else {
      // The file/stream options make sense.
      // Try to load the resource and compile it if possible. (Through black emf magic)
      if (sourceFileName.loadResource(stdIn).checkResourceLoaded()) {
        // Make sure the resource makes at least a litte bit sense
        if (resource.contents.head === null) {
          // Resource seems to be empty
          println('No content found in the provided resource.')
        } else if (stdOut) {
          // Resource is okay and writing to stdout. Get on with it.
          doGenerate(strategy, null, selectedCharts)
        } else {
          // Build up the output path
          val outputPath = basePath.toAbsolutePath.resolve(outlet)
          // Make sure the output path is valid (writable directory)
          if (outputPath.exists) {
            if (outputPath.isDirectory) {
              if (outputPath.isWritable) {
                // All good. Let's do it!
                doGenerate(strategy, outputPath, selectedCharts)
              } else {
                // Output path is a directory but seems to be write-protected
                println('The provided output path does exist, but writing is not permitted.')
                return
              }
            } else {
              // Output path exists, but is no directory
              println('The provided output path exists but is not a directory.')
              return
            }
          } else {
            // The output path doesn't exist, yet. Create the directory and then compile there.
            try {
              // Try to create the directory (and parent directories if needed)
              outputPath.createDirectories()
            } catch (IOException e) {
              // Output couldn't be created. That's it, I'm out of here.
              println('The provided output path does not exist, creation failed with an exception:')
              println('Reason: ' + e.class.canonicalName + ': ' + e.message)
              return
            }
            // We got our output path, start compilation
            doGenerate(strategy, outputPath, selectedCharts)
          }
        }
      }
    }
  }

  /**
   * Does some of the heavy lifting for code generation.
   * Loads the strategy before compilation, calls compilation, and writes files afterwards.
   */
  def doGenerate(String strategy, Path outlet, String selectedCharts) {
    // Make sure the compilation strategy is available
    val strategyId = strategy.loadStrategy()

    if (strategyId === null) {
      // The given strategy id couldn't be resolved, abort at this point
      return
    } else if (!sourceFileName.nullOrEmpty) {
      // Print log output when using file input
      print('''Compiling «sourceFileName» using strategy '«strategyId»'...''')
    } else {
      // Print log output when compiling from stdin
      print('''Compiling using strategy '«strategyId»'...''')
    }

    // Prepare alternate streams for stdout and stderr.
    // They can be used to analyze the output after compilation.
    val altSysout = new ByteArrayOutputStream()
    val altSyserr = new ByteArrayOutputStream()

    // Perform the actual compilation
    val result = doCompile(strategyId, selectedCharts, altSysout, altSyserr)

    // Check the proper compilation result
    if (result instanceof CodeContainer) {
      // We got some data from the compilation.
      if (outlet === null) {
        // Printing output to stdout.
        // Print a header with the filename and dump the contents afterwards.
        println(result.files.map [
          '''
            «fileName»:
              «code»
          '''
        ].join)
      } else {
        // Writing to a given output folder. Create files for every item in the result.
        for (f : result.files) {
          try {
            // Resolving the filename and writing the data
            val res = outlet.resolve(f.fileName).write(f.code.bytes)
            // We happy, print log
            println('''Wrote «res»''')
          } catch (IOException e) {
            println('''Writing «f.fileName» failed: «e.message»''')
          } catch (SecurityException e) {
            println('''Writing «f.fileName» failed: «e.message»''')
          }
        }
      }

    } else {
      // Compilation failed for some reason.
      println('No code generated.')
    }

    // Grab all the data from the alternate stdout/stderr streams and write that to the output.
    if (altSyserr.size !== 0) {
      System.err.printf('%nFailures occured:%n')
      System.err.write(altSyserr.toByteArray)
    }
    if (altSysout.size !== 0) {
      System.out.printf('%nFurther notes: occured:%n')
      System.out.write(altSyserr.toByteArray)
    }
  }

  /**
   * Invokes the actual compilation through KiCool.
   */
  def doCompile(String strategyId, String selectedCharts, ByteArrayOutputStream altSysout, ByteArrayOutputStream altSyserr) {
    // Store the current stdout/stderr streams to restore them in the end.
    val sysoutOri = System.out
    val syserrOri = System.err
    // Activate the alternate streams for stdout/stderr
    System.setOut(new PrintStream(altSysout))
    System.setErr(new PrintStream(altSyserr))

    try {
      // The compilation context describes and configures the complete compilation chain
      val ctx = Compile.createCompilationContext(strategyId, resource.contents.head)
      // the following property setting only applies to strategy 'de.cau.cs.kieler.sccharts.statebased'
      ctx.startEnvironment.setProperty(StatebasedCCodeGenerator.LEAN_MODE, true)
      if (!selectedCharts.nullOrEmpty) {
        ctx.startEnvironment.setProperty(ModelSelect.SELECTED_MODEL, selectedCharts)
      }
      // Perform the compilation and return the model
      return ctx.compile().model
    } catch (Throwable t) {
      // Something(TM) went wrong. No idea at this point.
      t.printStackTrace()
      return null
    } finally {
      // Cleanup after compilation. Restore previous stdout/stderr.
      System.setErr(syserrOri)
      System.setOut(sysoutOri)
      println('done.')
    }
  }

  /**
   * Checks the given id against the pre-installed compilation strategies.
   * If the id matches, the pre-installed strategy is used, otherwise the provided strategy description is loaded.
   */
  def loadStrategy(String strategy) {
    // Check if the given strategy id is already known
    if (KiCoolRegistration.systemModels.map[id].exists[it == strategy]) {
      // It is known. Just keep it that way.
      return strategy
    } else if (!strategy.endsWith('.kico')) {
      // Some unknown file ending is used for a compilation strategy. Reject that.
      println('''The extension of the provided strategy file '«strategy»' is invalid, see help content.''')
      return null
    } else {
      // We want to load a "new" strategy. Resolve the filename for the strategy.
      val strategyPath = basePath.resolve(strategy)
      if (!strategyPath.exists) {
        // The given strategy path doesn't point anywhere.
        println('''The provided strategy file '«strategy»' does not exist.''')
        return null
      } else if (!strategyPath.isRegularFile) {
        // The given strategy path doesn't point to a file.
        println('''The provided strategy file '«strategy»' is not a file.''')
        return null
      } else if (!strategyPath.isReadable) {
        // The given strategy path points to a file that is not readable.
        println('''The provided strategy file '«strategy»' is not readable.''')
        return null
      }

      // Resolve the strategy path to a URI
      val strategyURI = URI.createFileURI(strategyPath.toString)
      // Gather the dark magicians of emf and load the strategy resource
      val strategyResource = resource.resourceSet.getResource(strategyURI, true)

      // Prepare the issues that were generated during resource loading into a string
      val issues = strategyResource.errors + strategyResource.warnings
      val String issuesText = if (issues.iterator.hasNext) {
          '''
            «FOR it : issues»
              Line «line», column «column»: «it.message»
            «ENDFOR»
          '''
        }

      // Check that the resource did indeed provide a compilation system
      val strategyData = strategyResource.contents.head
      if (strategyData instanceof de.cau.cs.kieler.kicool.System) {
        // We got a compilation system. Make sure it doesn't collide with an existing strategy id.
        if (KiCoolRegistration.systemModels.map[id].exists[it == strategyData.id]) {
          // We got conflicting IDs
          println('''Did load «strategy», but the strategy's id «strategyData.id» is already used.''')
          return null
        } else if (issuesText === null) {
          // Strategy is fine and we can register it in KiCool
          println('''Did load «strategy» without errors.''')
          KiCoolRegistration.registerTemporarySystem(strategyData)
          return strategyData.id
        } else {
          // We had some issues while loading the strategy, strategy shouldn't be used/registered.
          print('''
            Did load «strategy» with errors:
            «issuesText»
          ''')
          return null
        }
      } else {
        // Not a compilation system. Probably null (?).
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

  /*
   * ------------------------
   * IMAGE RENDERING
   * ------------------------
   */
  /**
   * Generates a rendered image of the statechart.
   * Accepts option for reading from stdin, changing the output folder,
   * and choosing the image output format.
   */
  @Command(name=CMD_DRAW, separator=" ", header='Draw the state chart specified in given input file.', parameterListHeading="%nParameters:%n", optionListHeading="%nOptions:%n", sortOptions=false)
  def void draw(
    @Option(names='--stdin', description="Forces the artist to read input from stdIn.")
    boolean stdIn,
    @Option(names=#['-f',
      '--format'], paramLabel='<format>', defaultValue='png', completionCandidates=FormatCandidates, description="The desired output format of the diagram drawings. %nCandidates are: ${COMPLETION-CANDIDATES}. %nDefault is: ${DEFAULT-VALUE}.")
    String format,
    @Option(names=#['-o',
      '--output'], paramLabel='<path>', defaultValue='diagrams', description="The destination folder of the drawn diagram pages. %nDefault is: ${DEFAULT-VALUE}.")
    Path outlet,
//		@Option(names = '-diagModelOnly', description = "Instructes the artist to skip copying the static page components.")
//		boolean diagramModelOnly,
    @Parameters(arity="0..1", paramLabel="<sourceFile>", description="The input state chart file.")
    String sourceFileName
  ) {
    // Check the combination of options/parameters
    if (!stdIn && sourceFileName.nullOrEmpty) {
      // Not reading from stdin, but also no file given. Show usage.
      commandSpec.subcommands.get(CMD_DRAW).usage(System.out, ansi)
    } else {
      // Reading from stdin or file. Seems to make sense. Load the input resource.
      if (sourceFileName.loadResource(stdIn).checkResourceLoaded()) {
        // Resource loading successful
        if (resource.contents.head === null) {
          // Resource seems to be empty. Or at least no proper model found.
          println('No content found in the provided resource.')
        } else {
          // Resolve the output path for image generation
          val resolved = basePath.toAbsolutePath.resolve(outlet)
          // Check if the path is usable
          if (resolved.exists) {
            if (resolved.isDirectory) {
              if (resolved.isWritable) {
                // Path looks good, we are GO for image generation
                doDraw(resolved, format)
              } else {
                println('The provided output path does exist, but writing is not permitted.')
                return
              }
            } else {
              println('The provided output path exists but is not a directory.')
              return
            }
          } else {
            // The path doesn't exist, yet. We can try to create it.
            try {
              // Create output directory (and parent directories if needed)
              resolved.createDirectories()
            } catch (IOException e) {
              // Creation failed for some unknown reason (probably file permissions?)
              println('The provided output path does not exist, creation failed with an exception:')
              println('Reason: ' + e.class.canonicalName + ': ' + e.message)
              return
            }
            // Output path has been created. Now we can generate the image.
            doDraw(resolved, format)
          }
        }
      }
    }
  }

  /**
   * Do some housekeeping for image generation and delegate to the actual rendering system.
   */
  def void doDraw(Path outlet, String format) {
    // some log output (with the filename if possible)
    if (!sourceFileName.nullOrEmpty) {
      print('''Creating diagram model for «sourceFileName»...''')
    } else {
      print('''Creating diagram model...''')
    }

    // Store the current stdout/stderr streams and install alternate streams for later analysis
    val sysoutOri = System.out
    val syserrOri = System.err

    val altSysout = new ByteArrayOutputStream()
    val altSyserr = new ByteArrayOutputStream()

    System.setOut(new PrintStream(altSysout))
    System.setErr(new PrintStream(altSyserr))

    val result = new Wrapper<Pair<IStatus, Object>>

    // Load the correct SWT implementation, depending on the operating system
    try {
      val parentLoader = this.class.classLoader

      // Determine the correct SWT implementation to use
      val swtPath = switch os: System.properties.get('os.name').toString.toLowerCase {
        case os.startsWith('mac'): {
          parentLoader.getResource('swt/org.eclipse.swt.cocoa.macosx.x86_64/')
        }
        case os.startsWith('win'): {
          if (System.properties.get('os.arch').toString.endsWith('86')) {
            parentLoader.getResource('swt/org.eclipse.swt.win32.win32.x86/')
          } else {
            parentLoader.getResource('swt/org.eclipse.swt.win32.win32.x86_64/')
          }
        }
        case os.startsWith('linux'): {
          parentLoader.getResource('swt/org.eclipse.swt.gtk.linux.x86_64/')
        }
      }

      // In order to use the chosen SWT runtime lib, a new class loader is instantiated.
      // For security reason, only classes loaded by that loader or child loaders
      // can refer to classes loaded by this loader.
      // Therefore all the diagramming parts need to be loaded by this loader, too,
      // and, thus, must be invoked via reflection
      val drawingLoader = new URLClassLoader(#[
        // The SWT library determined previously
        swtPath,
        // All .statemachine.diagrams code is placed in diagramming folder during mvn build
        parentLoader.getResource('diagramming/')
      ], parentLoader)

      // Load the actual renderer and prime it with the current data
      drawingLoader.loadClass('de.scheidtbachmann.statemachine.diagrams.DiagramRenderer')?.
        newInstance() as Function<Map<String, Object>, IStatus> => [
        val args = newHashMap(#[ // need a writable map here!
          'param-input' -> resource.contents,
          'param-format' -> format,
          'param-outlet' -> outlet
        ])
        
        // Apply the rendering and grab the output folder name
        result.set(apply(args) -> args.get('result-written-folders'))
      ]
    } catch (Throwable t) {
      // Something broken here. Quite a lot can go wrong here.
      t.printStackTrace()
    } finally {

      if (result.get?.key !== null && !result.get.key.isOK) {
        // In case the diagram generation return some non-OK status, print them
        sysoutOri.println
        sysoutOri.println(result.get.key.toString)
        result.get.key.exception?.printStackTrace(sysoutOri)
      }

      // Restore the original stdout/stderr streams
      System.setErr(syserrOri)
      System.setOut(sysoutOri)
      println('done.')
    }

    // Gather errors/warnings from the alternate streams
    if (altSyserr.size !== 0) {
      System.err.printf('%nFailures occured:%n')
      System.err.write(altSyserr.toByteArray)
    }
    if (altSysout.size !== 0) {
      System.out.printf('%nFurther notes occured:%n')
      System.out.write(altSysout.toByteArray)
    }
  }

  /**
   * Possible strategies registered in compilation system. Mainly used for listing all strategies in the help text.
   */
  static class StrategyCandidates implements Iterable<String> {
    // Request all known compilation systems from KiCool and store in a nice sorted list
    val sortedIds = KiCoolRegistration.systemModels.map[id].sort

    // Use the iterator to detect the end and append the "bring your own strategy" help text
    override iterator() {
      val sorted = sortedIds.iterator
      sorted.map [
        '%n  ' + if (sorted.hasNext) it else it + ', %n  or a path to a custom <.kico> file'
      ]
    }
  }

  /**
   * Possible file endings to use for the image export.
   */
  static class FormatCandidates implements Iterable<String> {

    /** The different formats. We support rasterized images as well as vector images. */
    val candidates = #['bmp', 'jpeg', 'png', 'svg']

    override iterator() {
      candidates.iterator
    }
  }
}
