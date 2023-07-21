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

package de.scheidtbachmann.statemachine.cli;

import static org.assertj.core.api.Assumptions.assumeThat;
import static org.assertj.core.api.BDDAssertions.then;

import org.assertj.core.api.Assumptions;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import picocli.CommandLine;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

class GeneratorTest {

    private static final String TEST_FILE_NAME = "foo.sctx";
    private static final String STRATEGY_FILE_NAME = "bar.kico";
    private static final String OUTPUT_FOLDER = "gen";

    private static final String EMPTY_INPUT = "";
    private static final String INVALID_INPUT = "scchart foo { state }";
    private static final String SIMPLE_INPUT = "scchart foo { initial state foo }";

    private static final String EMPTY_STRAGEGY = "";
    private static final String INVALID_STRATEGY =
        "public system myerror.java /* label \"foo\" */ system de.cau.cs.kieler.sccharts.priority.java";
    private static final String SIMPLE_STRATEGY =
        "public system my.java label \"foo\" system de.cau.cs.kieler.sccharts.priority.java";

    private final PrintStream originalSysOut = System.out;
    private final PrintStream originalSysErr = System.err;
    private final ByteArrayOutputStream interceptingSysOut = new ByteArrayOutputStream();
    private final ByteArrayOutputStream interceptingSysErr = new ByteArrayOutputStream();

    private Path basePath;

    @BeforeEach
    void prepareStreams() {
        System.setOut(new PrintStream(interceptingSysOut));
        System.setErr(new PrintStream(interceptingSysErr));
    }

    @AfterEach
    void restoreStreams() {
        System.setOut(originalSysOut);
        System.setErr(originalSysErr);
    }

    @AfterEach
    void removeBaseDir() throws IOException {
        if (basePath != null) {
            deleteDirRecursively(basePath);
            basePath = null;
        }
    }

    @Nested
    class NoCommand {
        @Test
        void testNoArgs() throws IOException {
            whenRunningWithoutCommand();

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("noCmd.noArgs.stdout");
        }
    }

    @Nested
    class Validate {
        @Test
        void testValidate_NoInput() throws IOException {
            whenValidatingInput(Paths.get(""));

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("validate.noFile.stdout");
        }

        @Test
        void testValidate_InputFromStdIn() throws IOException {
            givenInputInStdin(INVALID_INPUT);

            whenValidatingInput(Paths.get(""), "--stdin");

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("validate.fromStdin.stdout");
        }

        @Test
        void testValidate_InputFromFile() throws IOException {
            givenTempDirForTest();
            givenInputInFile(INVALID_INPUT);

            whenValidatingInput(basePath, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("validate.fromFile.stdout");
        }
    }

    @Nested
    class Draw {
        @Test
        void testDraw_NoInput() throws IOException {
            whenDrawingDiagram(Paths.get(""));

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("draw.noFile.stdout");
        }

        @Test
        void testDraw_EmptyStdIn() throws IOException {
            givenInputInStdin(EMPTY_INPUT);

            whenDrawingDiagram(Paths.get(""), "--stdin");

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("draw.emptyStdin.start");
        }
    }

    @Nested
    class Generate {
        @Test
        void testGenerate_NoInput() throws IOException {
            whenGeneratingCode(Paths.get(""));

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.noFile.stdout");
        }

        @Test
        void testGenerate_InputFromStdIn_OutputToStdOut() throws IOException {
            givenInputInStdin(SIMPLE_INPUT);

            whenGeneratingCode(basePath, "--stdin", "--stdout");

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.fromStdin.start");
        }

        @Test
        void testGenerate_EmptyStdIn_OutputToStdOut() throws IOException {
            givenInputInStdin(EMPTY_INPUT);

            whenGeneratingCode(basePath, "--stdin", "--stdout");

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.emptyStdin.start");
        }

        @Test
        void testGenerateNonExistingInput() throws IOException {
            whenGeneratingCode(Paths.get(""), TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.missingFile.stdout");
        }

        @Test
        void testGenerateEmptyInput() throws IOException {
            givenTempDirForTest();
            givenInputInFile(EMPTY_INPUT);

            whenGeneratingCode(basePath, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.emptyFile.stdout");
        }

        @Test
        void testGenerateOutputStdOut() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);

            whenGeneratingCode(basePath, "--stdout", TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.validFile.start");
        }

        @Test
        void testGenerateOutputNonWritable01() throws IOException {
            Assumptions.assumeThat(runningOnWindows()).isFalse();

            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenOutputPathIsWriteProtected();

            whenGeneratingCode(basePath, "-o", OUTPUT_FOLDER, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.blockedOutput.stdout");
        }

        @Test
        void testGenerateOutputNonWritable02() throws IOException {
            Assumptions.assumeThat(runningOnWindows()).isFalse();

            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenOutputPathIsWriteProtected();

            whenGeneratingCode(basePath, "-o", OUTPUT_FOLDER + "/" + OUTPUT_FOLDER, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.blockedOutput.start");
        }

        @Test
        void testGenerateOutputStrategy() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);

            whenGeneratingCode(basePath, "--stdout", "-s de.cau.cs.kieler.sccharts.priority", TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.validStrategy.start");
        }

        @Test
        void testGenerateOutputCustomStrategy() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenStrategyInFile(SIMPLE_STRATEGY);

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputStartsWithDataFromFile("generate.customStrategy.start");
        }

        @Test
        void testGenerateOutputCustomStrategyMissing() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.missingStrategy.stdout");
        }

        @Test
        void testGenerateOutputCustomStrategyWrongExtenstion() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            final String strategyFileName = "bar.kic";
            Files.createFile(basePath.resolve(strategyFileName));

            whenGeneratingCode(basePath, "--stdout", "-s", strategyFileName, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.invalidStrategyExtension.stdout");
        }

        @Test
        void testGenerateOutputCustomStrategyIsDirectory() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            Files.createDirectory(basePath.resolve(STRATEGY_FILE_NAME));

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.directoryAsStrategy.stdout");
        }

        @Test
        void testGenerateOutputCustomStrategyUnreadable() throws IOException {
            assumeThat(runningOnWindows()).isFalse();

            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenStrategyInFile(SIMPLE_STRATEGY);
            givenStrategyFileIsUnreadable();

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.unreadableStrategy.stdout");
        }

        @Test
        void testGenerateOutputCustomStrategyEmpty() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenStrategyInFile(EMPTY_STRAGEGY);

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.emptyStrategy.stdout");
        }

        @Test
        void testGenerateOutputCustomStrategyErroneous() throws IOException {
            givenTempDirForTest();
            givenInputInFile(SIMPLE_INPUT);
            givenStrategyInFile(INVALID_STRATEGY);

            whenGeneratingCode(basePath, "--stdout", "-s", STRATEGY_FILE_NAME, TEST_FILE_NAME);

            thenErrorOutputIsEmpty();
            thenRegularOutputMatchesDataFromFile("generate.brokenStrategy.stdout");
        }
    }

    /*
     * ----------------------------------------------------------------------------------
     */

    private void givenTempDirForTest() throws IOException {
        basePath = Files.createTempDirectory("stateChartGenTesting");
    }

    private void givenInputInStdin(final String input) {
        System.setIn(new ByteArrayInputStream(input.getBytes()));
    }

    private void givenInputInFile(final String input) throws IOException {
        Files.write(basePath.resolve(TEST_FILE_NAME), List.of(input), StandardOpenOption.CREATE,
            StandardOpenOption.WRITE);
    }

    private void givenStrategyInFile(final String strategy) throws IOException {
        Files.write(basePath.resolve(STRATEGY_FILE_NAME), List.of(strategy), StandardOpenOption.CREATE,
            StandardOpenOption.WRITE);
    }

    private void givenStrategyFileIsUnreadable() {
        basePath.resolve(STRATEGY_FILE_NAME).toFile().setReadable(false, false);
    }

    private void givenOutputPathIsWriteProtected() throws IOException {
        Files.createDirectory(basePath.resolve(OUTPUT_FOLDER)).toFile().setWritable(false, false);
    }

    private void whenRunningWithoutCommand() {
        commandLineRun(Paths.get(""));
    }

    private void whenValidatingInput(final Path basePath, final String... args) {
        final String[] params = Stream.concat(Stream.of("validate"), Arrays.stream(args)).toArray(String[]::new);
        commandLineRun(basePath, params);
    }

    private void whenDrawingDiagram(final Path basePath, final String... args) {
        final String[] params = Stream.concat(Stream.of("draw"), Arrays.stream(args)).toArray(String[]::new);
        commandLineRun(basePath, params);
    }

    private void whenGeneratingCode(final Path basePath, final String... args) {
        final String[] params = Stream.concat(Stream.of("generate"), Arrays.stream(args)).toArray(String[]::new);
        commandLineRun(basePath, params);
    }

    private void thenErrorOutputIsEmpty() {
        then(interceptingSysErr.toString()).isEmpty();
    }

    private void thenRegularOutputMatchesDataFromFile(final String fileName) throws IOException {
        final Path filePath = Path.of("", "src/test/resources/expectedOutput").resolve(fileName);
        final List<String> allLinesFromFile = Files.readAllLines(filePath);
        final String expected =
            allLinesFromFile.stream().collect(Collectors.joining(System.lineSeparator(), "", System.lineSeparator()));
        then(interceptingSysOut.toString(StandardCharsets.UTF_8)).isEqualTo(expected);
    }

    private void thenRegularOutputStartsWithDataFromFile(final String fileName) throws IOException {
        final Path filePath = Path.of("", "src/test/resources/expectedOutput").resolve(fileName);
        final List<String> allLinesFromFile = Files.readAllLines(filePath);
        final String expected =
            allLinesFromFile.stream().collect(Collectors.joining(System.lineSeparator(), "", System.lineSeparator()));
        then(interceptingSysOut.toString(StandardCharsets.UTF_8)).startsWith(expected.trim());
    }

    /*
     * ----------------------------------------------------------------------------------
     */

    private boolean runningOnWindows() {
        return System.getProperty("os.name").toLowerCase().contains("win");
    }

    private void commandLineRun(final Path basePath, final String... args) {
        final CommandLine cmd = new CommandLine(new TestableGenerator(basePath))
            .setColorScheme(CommandLine.Help.defaultColorScheme(CommandLine.Help.Ansi.OFF));
        cmd.execute(args);
    }

    private void deleteDirRecursively(final Path path) throws IOException {
        Files.walk(path).sorted(Comparator.reverseOrder()).map(Path::toFile).forEach(File::delete);
    }
}
