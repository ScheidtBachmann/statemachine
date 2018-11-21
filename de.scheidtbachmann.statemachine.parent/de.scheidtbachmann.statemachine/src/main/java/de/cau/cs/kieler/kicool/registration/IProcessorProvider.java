package de.cau.cs.kieler.kicool.registration;

import de.cau.cs.kieler.kicool.compilation.Processor;

public interface IProcessorProvider {

	Iterable<Class<? extends Processor<?,?>>> getProcessors();
}
