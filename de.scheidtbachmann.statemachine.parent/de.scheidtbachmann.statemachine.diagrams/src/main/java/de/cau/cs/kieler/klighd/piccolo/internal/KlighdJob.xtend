package de.cau.cs.kieler.klighd.piccolo.internal

import java.util.function.Consumer
import java.util.function.Supplier
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.core.runtime.NullProgressMonitor
import org.eclipse.swt.widgets.Display

class KlighdJob {
	
	val Supplier<Display> displayProvider
	val Consumer<IProgressMonitor> task
	
	new(String description, Supplier<Display> displayProvider, Consumer<IProgressMonitor> task) {
		this.displayProvider = displayProvider
		this.task = task
	}
	
	def schedule() {
		schedule(0)
	}
	
	def schedule(long delayInMilliSeconds) {
		task.accept(new NullProgressMonitor())
	}
	
	def cancel() {
	}
	
	
// TODO: move the following to an eclipse-specific Job-based implementation
//        /* Constructor */ {
//            this.setSystem(true);
//        }
//
//        @Override
//        protected IStatus run(final IProgressMonitor monitor) {
//            if (display != null) {
//                display.asyncExec(diagramUpdateRunnable);
//
//            } else {
//                // if no SWT display is required just execute 'diagramUpdateRunnable'
//                //  (within this job's worker thread)
//                diagramUpdateRunnable.run();
//            }
//
//            return Status.OK_STATUS;
//        }
}