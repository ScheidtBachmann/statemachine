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

package de.scheidtbachmann.statemachine.codegen.lean.java

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import com.google.inject.Inject
import de.cau.cs.kieler.annotations.Annotatable
import de.cau.cs.kieler.annotations.CommentAnnotation
import de.cau.cs.kieler.annotations.StringAnnotation
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions
import de.cau.cs.kieler.kexpressions.Expression
import de.cau.cs.kieler.kexpressions.ReferenceCall
import de.cau.cs.kieler.kexpressions.ReferenceDeclaration
import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.ValuedObjectReference
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsTypeExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.DelayType
import de.cau.cs.kieler.sccharts.PreemptionType
import de.cau.cs.kieler.sccharts.Scope
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.Transition
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.processors.statebased.DebugAnnotations
import de.cau.cs.kieler.sccharts.processors.statebased.lean.codegen.AbstractStatebasedLeanTemplate
import java.util.LinkedList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class StatebasedLeanJavaTemplate extends AbstractStatebasedLeanTemplate {

    @Inject extension AnnotationsExtensions
    @Inject extension KExpressionsTypeExtensions
    @Inject extension KExpressionsValuedObjectExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension EnhancedStatebasedJavaCodeSerializeHRExtensions

    static val INTERFACE_PARAM_NAME = "arg"

    // Output for the generated code and interface
    @Accessors(PUBLIC_GETTER) val source = new StringBuilder
    @Accessors(PUBLIC_GETTER) val context = new StringBuilder

    // Externally set flags to configure generated code   
    @Accessors var String superClass = null
    @Accessors var List<StatebasedLeanJavaFeatureOverrides> featureOverrides = newLinkedList()
    
    var boolean generateContextInterface = false
    protected Iterable<VariableDeclaration> eventDeclarations


    def void create(State rootState) {
        this.rootState = rootState

        processDeclarations()
        addNeededImports()

        scopes = <Scope>newLinkedList
        scopeNames = <Scope, String>newHashMap
        scopeEnumNames = <Scope, String>newHashMap
        contextStructNames = <Scope, String>newHashMap
        regionCounter = 0
        stateEnumCounter = 1
        enumerateScopes(rootState)

        createCode()
        createContextInterface()    
    }
    
    private def Iterable<VariableDeclaration> processDeclarations() {
        generateContextInterface = rootState.declarations
            .exists[hasAnnotation('Context')]
        eventDeclarations = rootState.declarations
            .filter(VariableDeclaration)
            .filter[hasAnnotation('InputEvent')]
    }
    
    private def void addNeededImports() {
        addImports("java.util.stream.Stream")

        if (eventDeclarations.size > 0) {
            addImports("java.util.Arrays",
                "java.util.Collection",
                "java.util.Collections"
            )
        }
        
        if (isLoggingEnabled) {
            addImports("org.slf4j.Logger", "org.slf4j.LoggerFactory")
        }
        
        if (isStringContainerEnabled) {
            addImports("de.scheidtbachmann.statemachine.runtime.StateMachineRootContext",
                "de.scheidtbachmann.statemachine.runtime.StateMachineStateContainer")
        } else {
            addImports("java.util.stream.Collectors")            
        }
        
        if (isExecutorEnabled) {
            addImports(
                "java.util.Arrays",
                "java.util.Collection",
                "java.util.List",
                "java.util.concurrent.Callable",
                "java.util.concurrent.ExecutionException",
                "java.util.concurrent.ScheduledExecutorService",
                "java.util.concurrent.TimeUnit",
                "de.scheidtbachmann.statemachine.runtime.MultiEventSupplier",
                "de.scheidtbachmann.statemachine.runtime.SingleEventSupplier",
                "de.scheidtbachmann.statemachine.runtime.execution.StateMachineExecutionFactory",
                "de.scheidtbachmann.statemachine.runtime.execution.StateMachineTimeoutManager")
        }
        
        if (isHistoryEnabled) {
            addImports(
                "java.util.Collections",
                "java.util.LinkedList",
                "java.util.List",
                "de.scheidtbachmann.statemachine.runtime.StateMachineHistoryEntry"
            )
        }
    }

    protected def void createCode() {
        source.append('''
          @SuppressWarnings("all")
          @de.scheidtbachmann.statemachine.runtime.StateMachineForContext(« rootState.uniqueName »«StatebasedLeanJavaCodeGenerator.CONTEXT_SUFFIX ».class)
          @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
          public class « rootState.uniqueName »« IF superClass !== null » extends « superClass »« ENDIF » {
              
            « generatePeripheralObjects() »
            « generateDebuggingHelper() »
            « generateInputEvents() »
            « generateIface() »
            « generateRuntimeDataStructures() »
            « generateBehaviour() »
            « generateInteractions() »
            « generateCurrentStateOutput() »
            « generateConstructor() »
            « generateDisposal() »
            « generateTimeoutMethods() »
            « generateGlobalObjects() »
            « generateActivityHistory() »
          }
        ''')
    }

    private def generatePeripheralObjects() {
        // CHECKSTYLEOFF LineLength - This is template code that cannot be arbitrarily formatted
        return '''
            « IF isLoggingEnabled »
              private static final Logger LOG = LoggerFactory.getLogger(«rootState.uniqueName».class);
              private final String loggingPrefix;
              
            « ENDIF »
            « IF isExecutorEnabled »
              private final StateMachineExecutionFactory executionFactory;
              private final ScheduledExecutorService executor;

            « ENDIF »
        '''
        // CHECKSTYLEON LineLength
    }

    private def generateDebuggingHelper() {
        // CHECKSTYLEOFF LineLength - This is template code that cannot be arbitrarily formatted
        return '''
            « IF rootState.hasAnnotation("ORIGINAL_SCCHART") »
              public static final String ORIGINAL_SCCHART = "« rootState.getAnnotation("ORIGINAL_SCCHART").asStringAnnotation.values.head »";
              
            « ENDIF »
            « IF DebugAnnotations.USE_ANNOTATIONS »
              /**
               * Annotation for debugging
               */
              private static @interface SCChartsDebug {
                 public String originalName() default "";
                 public int originalStateHash() default 0;
              }
              
            « ENDIF »
        '''
        // CHECKSTYLEON LineLength
    }    

    private def generateInputEvents() {
        return '''
            « IF eventDeclarations.size > 0 »
              @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
              public enum InputEvent {
                « FOR decl : eventDeclarations SEPARATOR ',' »
                  «FOR event : decl.valuedObjects SEPARATOR ', ' »«event.name»« ENDFOR »
                « ENDFOR »
              }

            «ENDIF»
        '''
    }

    private def CharSequence generateIface() {
        return '''
            « IF isIfaceNeeded() »
              /**
               * The interface containing all model variables (inputs, outputs)
               */
              @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
              public class Iface {
                « rootState.createDeclarations »
                
                public void assertAccessFromValidThread() {
                  if (!executionFactory.isRunningInExecutor()) {
                    « IF isThreadAccessWarnOnly »
                      LOG.warn("Illegal thread for access to statemachine interface", new Exception());
                    « ELSE »
                      throw new RuntimeException("Illegal thread for access to statemachine interface");
                    « ENDIF »
                  }
                }
              }

              public Iface iface;

            « ENDIF »
        '''
    }
    
    private def generateRuntimeDataStructures() {
        return '''
            « generateRootRuntimeStructure() »
            « generateScopeRuntimeStructures() »
        '''
    }

    private def generateRootRuntimeStructure() {
        val rootRegions = rootState.regions.filter(ControlflowRegion)
        return '''
            private TickData rootContext;
            « IF generateContextInterface »
              private final «rootState.uniqueName»Context externalContext;
            « ENDIF »

            /**
             * Enumeration for the thread states of the root level program.
             * The chosen scheduling regime (IUR) uses four states to maintain the statuses of threads.
             */
            @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
            public enum ThreadStatus {
              TERMINATED, RUNNING, READY, PAUSING;
            }

            /**
             * Runtime data for the root level program
             */
            @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
            public static class TickData« IF isStringContainerEnabled » implements StateMachineRootContext« ENDIF » {
              ThreadStatus threadStatus;

              « FOR r : rootRegions »
                « r.uniqueContextMemberName » « r.uniqueName » = new « r.uniqueContextMemberName »();
              « ENDFOR »

              public Stream<String> getCurrentState() {
                return Stream.of(
                  « FOR r : rootRegions SEPARATOR ',' »
                    « r.uniqueName ».getCurrentState()
                  « ENDFOR »
                ).flatMap(i -> i);
              }
            }

        '''            
    }

    private def generateScopeRuntimeStructures() {
        return '''
            « FOR r : scopes.filter(ControlflowRegion) »
              /**
               * Enumeration for all states of the « r.name » region
               */
              @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
              public enum « r.uniqueName »States {
                « FOR s : r.states SEPARATOR ', ' »
                  « s.uniqueEnumName »("« getSourceState(s) »")«IF s.isHierarchical », 
                  « s.uniqueEnumName»RUNNING("« getSourceState(s) »")« ENDIF »
                « ENDFOR »
                ;

                private String origin;

                « r.uniqueName »States(String origin) {
                  this.origin = origin;
                }

                public String getOrigin() {
                  return origin;
                }
              }

              /**
               * The runtime thread data of region « r.name »
               */
              @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
              public static class « r.uniqueContextMemberName » {
                ThreadStatus threadStatus;
                « r.uniqueName »States activeState;
                « IF r.needsDelayedEnabled »
                  boolean delayedEnabled;
                « ENDIF »
                « FOR c : r.states.map[ regions ].flatten.filter(ControlflowRegion) »
                  « c.uniqueContextMemberName » « c.uniqueContextName » = new « c.uniqueContextMemberName »();
                « ENDFOR »

                public Stream<String> getCurrentState() {
                  if (activeState != null) {
                    switch (activeState) {
                      « FOR s : r.states.filter[isHierarchical] »
                        case « s.uniqueEnumName »:
                        case « s.uniqueEnumName »RUNNING:
                          return Stream.of(
                            « FOR subr : s.regions.filter(ControlflowRegion) SEPARATOR ',' »
                              « subr.uniqueContextName ».getCurrentState()
                            « ENDFOR »  
                          ).flatMap(i -> i);
                      « ENDFOR »
                      default:
                        return Stream.of(activeState.getOrigin().replaceAll("^State (.+) \\(-?[0-9]+\\)$", "$1"));
                    }
                  } else {
                    return Stream.empty();
                  }
                }
              }

            « ENDFOR »
        '''
    }

    private def generateBehaviour() {
        return '''
            «FOR s : scopes»
              « IF (s instanceof State) »
                « createCodeState(s) »
              « ENDIF »
              « IF (s instanceof ControlflowRegion) »
                « createSourceControlflowRegion(s) »
              « ENDIF »

            « ENDFOR »
        '''
    }

    private def generateInteractions() {
        // CHECKSTYLEOFF LineLength - This is template code that cannot be arbitrarily formatted
        return '''
            « IF eventDeclarations.size > 0 »
              private void writeEventsToIfaceInputs(Collection<InputEvent> events) {
                Collection<InputEvent> nullSafeEvents = events != null ? events : Collections.emptyList();
              « FOR decl : eventDeclarations »
                « FOR vo: decl.valuedObjects »
                  iface.«vo.name» = nullSafeEvents.contains(InputEvent.«vo.name»);
                « ENDFOR »
              « ENDFOR »
              }

            « ENDIF »
            private void reset() {
              « FOR r : rootState.regions.filter(ControlflowRegion) »
                rootContext.« r.uniqueContextName ».activeState = « r.uniqueName »States.« r.states.filter[ initial ].head.uniqueEnumName »;
                rootContext.« r.uniqueContextName ».threadStatus = ThreadStatus.READY;
              « ENDFOR »

              rootContext.threadStatus = ThreadStatus.READY;
            }

            private void tick() {
              « generateTraceLogging('"Performing tick on StateMachine"') »
              if (rootContext.threadStatus == ThreadStatus.TERMINATED) return;
            
              « rootState.uniqueName »_root(rootContext);
            }

            « IF isExecutorEnabled »
              « generateExecutorInteractions »
            « ELSE »
              « generateSimpleInteractions »
            « ENDIF »

        '''
        // CHECKSTYLEON LineLength
    }
    
    private def generateExecutorInteractions() {
        // CHECKSTYLEOFF LineLength - This is template code that cannot be arbitrarily formatted
        return '''
            public void init() {
              init(null, null);
            }

            public void init(Runnable preInitTask, Runnable postInitTask) {
              executor.execute(() -> {
                try {
                  if (preInitTask != null) {
                    preInitTask.run();
                  }
                  « generateTraceLogging('"Initializing StateMachine"') »
                  reset();
                  « IF eventDeclarations.size > 0 »
                    writeEventsToIfaceInputs(Collections.emptyList());
                  « ENDIF »
                  tick();
                  if (postInitTask != null) {
                    postInitTask.run();
                  }
                } catch (final Throwable t) {
                  « generateErrorLogging('"Exception in statemachine initialization", t') »
                }
              });
            }

            public void apply(InputEvent... events) {
              apply(null, Arrays.asList(events), null);
            }

            public void apply(Collection<InputEvent> events) {
              apply(null, events, null);
            }

            public void apply(Runnable preExecutionTask, InputEvent event) {
              apply(preExecutionTask, List.of(event), null);
            }

            public void apply(Runnable preExecutionTask, Collection<InputEvent> events) {
              apply(preExecutionTask, events, null);
            }

            public void apply(InputEvent event, Runnable postExecutionTask) {
              apply(null, List.of(event), postExecutionTask);
            }

            public void apply(Collection<InputEvent> events, Runnable postExecutionTask) {
              apply(null, events, postExecutionTask);
            }

            public void apply(Runnable preExecutionTask, InputEvent event, Runnable postExecutionTask) {
              apply(preExecutionTask, List.of(event), postExecutionTask);
            }

            public void apply(Runnable preExecutionTask, Collection<InputEvent> events, Runnable postExecutionTask) {
              executor.execute(() -> {
                « IF isHistoryEnabled »
                  final StateMachineHistoryEntry historyEntry = new StateMachineHistoryEntry();
                  addHistoryEntry(historyEntry);
                « ENDIF »
                try {
                  if (preExecutionTask != null) {
                    preExecutionTask.run();
                  }
                  « generateDebugLogging('"Performing action on input events {} while in state {}", events, getCurrentState()') »
                  « IF isHistoryEnabled »
                    historyEntry.setStartState(getCurrentState().toString());
                    historyEntry.setEvents(events.toString());
                  « ENDIF »
                  « IF eventDeclarations.size > 0 »
                    writeEventsToIfaceInputs(events);
                  « ENDIF»
                  tick();
                  if (postExecutionTask != null) {
                    postExecutionTask.run();
                  }
                  « generateDebugLogging('"Action done, finished in state {}", getCurrentState()') »
                  « IF isHistoryEnabled »
                    historyEntry.setEndState(getCurrentState().toString());
                  « ENDIF »
                } catch (final Throwable t) {
                  « generateErrorLogging('"Exception in statemachine application", t') »
                  « IF isHistoryEnabled »
                    historyEntry.setThrowable(t);
                  « ENDIF »
                }
              });
            }

            public void apply(SingleEventSupplier<InputEvent> eventSupplier) {
              apply(eventSupplier, null);
            }

            public void apply(SingleEventSupplier<InputEvent> eventSupplier, Runnable postExecutionTask) {
              apply(() -> {
                InputEvent suppliedEvent = eventSupplier.getEvent();
                return suppliedEvent != null ? List.of(suppliedEvent) : Collections.emptyList();
              }, postExecutionTask);
            }

            public void apply(MultiEventSupplier<InputEvent> eventsSupplier) {
              apply(eventsSupplier, null);
            }

            public void apply(MultiEventSupplier<InputEvent> eventsSupplier, Runnable postExecutionTask) {
              executor.execute(() -> {
                « IF isHistoryEnabled »
                  final StateMachineHistoryEntry historyEntry = new StateMachineHistoryEntry();
                  addHistoryEntry(historyEntry);
                « ENDIF »
                try {
                  Collection<InputEvent> events = eventsSupplier.getEvents();
                  « generateDebugLogging('"Performing action on input events {} while in state {}", events, getCurrentState()') »
                  « IF isHistoryEnabled »
                    historyEntry.setStartState(getCurrentState().toString());
                    historyEntry.setEvents(events.toString());
                  « ENDIF »
                  « IF eventDeclarations.size > 0 »
                    writeEventsToIfaceInputs(events);
                  « ENDIF»
                  tick();
                  if (postExecutionTask != null) {
                    postExecutionTask.run();
                  }
                  « generateDebugLogging('"Action done, finished in state {}", getCurrentState()') »
                  « IF isHistoryEnabled »
                    historyEntry.setEndState(getCurrentState().toString());
                  « ENDIF »
                } catch (final Throwable t) {
                  « generateErrorLogging('"Exception in statemachine application", t') »
                  « IF isHistoryEnabled »
                    historyEntry.setThrowable(t);
                  « ENDIF »
                }
              });
            }

            public <T> T query(Callable<T> dataRequest) {
              try {
                if (executionFactory.isRunningInExecutor()) {
                  return dataRequest.call();
                } else {
                  return executor.submit(dataRequest).get();
                }
              } catch (Exception e) {
                LOG.error(loggingPrefix + " - " + "Exception in statemachine application", e);
                return null;
              }
            }
        '''
        // CHECKSTYLEON LineLength
    }
    
    private def generateSimpleInteractions() {
        return '''
            public void init() {
              « generateTraceLogging('"Initializing StateMachine"') »
              reset();
              « IF eventDeclarations.size > 0 »
                writeEventsToIfaceInputs(Collections.emptyList());
              « ENDIF »
              tick();
            }
            
            public void apply(InputEvent... events) {
              apply(Arrays.asList(events));
            }

            public void apply(Collection<InputEvent> events) {
              « generateTraceLogging('"Performing action on input events {}", events') »
              « IF eventDeclarations.size > 0 »
                writeEventsToIfaceInputs(events);
              « ENDIF»
              tick();
            }
        '''
    }
    
    private def generateCurrentStateOutput() {
        return '''
            « IF isStringContainerEnabled »
              public StateMachineStateContainer getCurrentState() {
                return new StateMachineStateContainer(rootContext);
              }
            « ELSE »
              public String getCurrentState() {
                return rootContext.getCurrentState().distinct().collect(Collectors.joining(","));
              }
            « ENDIF »

        '''
    }
    
    private def generateConstructor() {
        var parameters = new LinkedList<String>();
        if (generateContextInterface) {
            parameters.add(rootState.uniqueName + "Context externalContext")
        }
        if (isExecutorEnabled) {
            parameters.add("StateMachineExecutionFactory executionFactory")
        }
        if (isLoggingEnabled) {
            parameters.add("String loggingPrefix")
        }
        return '''
            public « rootState.uniqueName »(« parameters.join(", ") ») {
              « IF generateContextInterface »
                this.externalContext = externalContext;
              « ENDIF »
              « IF isExecutorEnabled »
                this.executionFactory = executionFactory;
                « IF isLoggingEnabled »
                  this.executor = executionFactory.createExecutor("« rootState.uniqueName »" + loggingPrefix);
                  this.loggingPrefix = loggingPrefix;
                « ELSE »
                  this.executor = executionFactory.createExecutor("« rootState.uniqueName »");
                « ENDIF »
              « ENDIF »
              « IF isIfaceNeeded »
              this.iface = new Iface();
              « ENDIF »
              this.rootContext = new TickData();
            }

        '''
    }
    
    private def generateDisposal() {
        return '''
            public void dispose() {
              « IF isExecutorEnabled »
                if (this.executor != null) {
                  executionFactory.releaseExecutor(this.executor);
                }
              « ENDIF »
            }
        '''
    }
    
    private def generateTimeoutMethods() {
        return '''
            « IF isExecutorEnabled »
              public StateMachineTimeoutManager createTimeout(String timeoutId, long delay, TimeUnit timeUnit, 
                  Runnable timeoutAction, boolean autoStart) {
                return executionFactory.createTimeout(executor, timeoutId, delay, timeUnit, timeoutAction, autoStart);
              }

            « ENDIF »
        '''
    }

    private def generateGlobalObjects() {
        return '''
            « FOR globalObject : modifications.get(EnhancedStatebasedJavaCodeSerializeHRExtensions.GLOBAL_OBJECTS) »
              « globalObject »
            « ENDFOR »
        '''
    }    
    
    private def generateActivityHistory() {
        return '''
            « IF isHistoryEnabled »

              private final static int MAX_HISTORY_ENTRIES = 10;

              private final List<StateMachineHistoryEntry> activityHistory = new LinkedList<>();

              public List<StateMachineHistoryEntry> getActivityHistory() {
                return Collections.unmodifiableList(activityHistory);
              }

              private void addHistoryEntry(StateMachineHistoryEntry historyEntry) {
                activityHistory.add(historyEntry);
                while (activityHistory.size() > 10) {
                  activityHistory.remove(0);
                }
              }
            « ENDIF »
        '''
    }
    
    private def CharSequence createCodeState(State state) {
        val originalName = state.getAnnotation("OriginalState")?.asStringAnnotation?.values?.head
        val originalNameHashAnnotation = state.getAnnotation("OriginalNameHash")?.asIntAnnotation 
        val originalStateHashCode = if (originalNameHashAnnotation === null) 0 else originalNameHashAnnotation.value

        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        return '''
            « generateJavaDocFromCommentAnnotations(state) »
            « IF originalName !== null »@SCChartsDebug(originalName = "« originalName »", originalStateHash = « originalStateHashCode »)«ENDIF»
            private void « state.uniqueName »« IF (state == rootState) »_root« ENDIF »(« state.uniqueContextMemberName » context) {
              « generateTraceLogging('''"Activating state « state.getStringAnnotationValue("SourceState") »"''') »
            « IF state.isHierarchical »
            « IF state !== rootState »
              « FOR r : state.regions.filter(ControlflowRegion) »
                context.« r.uniqueContextName ».activeState = « r.uniqueName »States.« r.states.filter[ initial ].head.uniqueEnumName »;
                « IF r.needsDelayedEnabled »
                context.« r.uniqueContextName ».delayedEnabled = false;
                « ENDIF »
                context.« r.uniqueContextName ».threadStatus = ThreadStatus.READY;
              « ENDFOR »

              context.activeState = « state.parentRegion.uniqueName »States.« state.uniqueEnumName »RUNNING;
            }

            « state.generateJavaDocFromCommentAnnotations »
            « IF originalName !== null »@SCChartsDebug(originalName = "« originalName »", originalStateHash = « originalStateHashCode »)«ENDIF»
            private void « state.uniqueName »_running(« state.uniqueContextMemberName » context) {
              « IF isLoggingEnabled »LOG.trace("Activating state « state.getStringAnnotationValue("SourceState") »");« ENDIF »
            « ENDIF »
              « createCodeSuperstate(state) »
            « ENDIF »
              « addSimpleStateCode(state) »
            }
        '''
        //CHECKSTYLEON LineLength
    }

    protected def CharSequence createCodeSuperstate(State state) {
        return '''
            « FOR r : state.regions.filter(ControlflowRegion) »
                if (context.« r.uniqueName ».threadStatus != ThreadStatus.TERMINATED) {
                  context.« r.uniqueName ».threadStatus = ThreadStatus.RUNNING;
                }
            « ENDFOR »
            « FOR r : state.regions.filter(ControlflowRegion) »        
                « r.uniqueName »(context.« r.uniqueContextName »);
            « ENDFOR »        
        '''
    }

    protected def CharSequence addSimpleStateCode(State state) {
        val hasDefaultTransition = state.outgoingTransitions.exists [
            trigger === null && delay == DelayType.IMMEDIATE && preemption != PreemptionType.TERMINATION
        ]

        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        return '''
          « IF state.isFinal »
            context.threadStatus = ThreadStatus.TERMINATED;
          « ELSE »
            « IF state.outgoingTransitions.size == 1 && 
                 state.outgoingTransitions.head.delay == DelayType.IMMEDIATE && 
                 state.outgoingTransitions.head.trigger === null &&
                 state.outgoingTransitions.head.preemption != PreemptionType.TERMINATION »
              « addTransitionEffectCode(state.outgoingTransitions.head) » « addTransitionComment(state.outgoingTransitions.head) »
            «ELSE»
              « FOR t : state.outgoingTransitions.indexed »
                « addTransitionConditionCode(t.key, state.outgoingTransitions.size, t.value, hasDefaultTransition) »
              « ENDFOR »
              « IF !hasDefaultTransition »
                « IF state.outgoingTransitions.size == 0 »
                  « IF (state.isHierarchical) »
                    « addDelayedEnabledCode(state) »
                  « ENDIF »
                  context.threadStatus = ThreadStatus.READY;
                « ELSE »
                  } else {
                    « IF (state.isHierarchical) »
                      « addDelayedEnabledCode(state) »
                    « ENDIF »
                    context.threadStatus = ThreadStatus.READY;
                  }
                « ENDIF »
              « ENDIF »
            « ENDIF »
          « ENDIF »
        '''
        //CHECKSTYLEON LineLength
    }

    protected def CharSequence addDelayedEnabledCode(State state) {
        return '''
          « FOR r : state.regions.filter(ControlflowRegion) »
            « IF r.needsDelayedEnabled »
            context.« r.uniqueName ».delayedEnabled = true;
            « ENDIF »
          « ENDFOR » 
        '''
    }

    protected def CharSequence addTransitionConditionCode(int index, int count, Transition transition, 
        boolean hasDefaultTransition) {
        valuedObjectPrefix = "iface."
        val defaultTransition = transition.trigger === null && transition.delay == DelayType.IMMEDIATE;
        var CharSequence condition = ""
        if (transition.preemption == PreemptionType.TERMINATION) {
            val termRegions = transition.sourceState.regions.filter(ControlflowRegion).indexed
            for (r : termRegions) {
                condition = condition + "context." + r.value.uniqueContextName +
                    ".threadStatus == ThreadStatus.TERMINATED"
                if(r.key != termRegions.size - 1) condition = condition + " && \n    "
            }
        } else {
            if (transition.immediate) {
                if(transition.trigger !== null) condition = transition.trigger.serializeHR else condition = "true"
            } else {
                if (transition.trigger === null)
                    condition = "context.delayedEnabled"
                else
                    condition = "context.delayedEnabled && (" + transition.trigger.serializeHR + ")"
            }
        }

        valuedObjectPrefix = ""

        return '''
          « IF index == 0 »
            if (« condition ») { « addTransitionComment(transition) »
          « ELSE »
            } else « IF !(defaultTransition) »if (« condition ») « ENDIF »{« addTransitionComment(transition) »
          « ENDIF » 
            « addTransitionEffectCode(transition) »
          « IF index == count-1 && hasDefaultTransition »
            }
          « ENDIF »
        '''
    }

    protected def CharSequence addTransitionEffectCode(Transition transition) {
        valuedObjectPrefix = "iface."
        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        val code = '''
          « FOR e : transition.effects »
            « e.serializeHR »;
          « ENDFOR »
          « IF transition.sourceState.parentRegion.needsDelayedEnabled »
          context.delayedEnabled = false;
          « ENDIF »
          « IF transition.sourceState != transition.targetState || transition.targetState.isHierarchical »
            context.activeState = « transition.targetState.parentRegion.uniqueName »States.« transition.targetState.uniqueEnumName »;
          « ENDIF »
        '''
        //CHECKSTYLEON LineLength        
        valuedObjectPrefix = ""
        return code
    }

    protected def CharSequence createSourceControlflowRegion(ControlflowRegion region) {
        return '''
          private void « region.uniqueName »(« region.uniqueContextMemberName » context) {
            while (context.threadStatus == ThreadStatus.RUNNING) {
              switch (context.activeState) {
                « FOR s : region.states »
                  case « s.uniqueEnumName »:
                    « s.uniqueName »(context);
                    « IF s.isHierarchical »
                      « s.uniqueName »_running(context);
                    « ENDIF »
                    break;
                  « IF  s.isHierarchical »
                    case « s.uniqueEnumName »RUNNING:
                      « s.uniqueName »_running(context);
                      break;
                  « ENDIF »
              «ENDFOR»
              }
            }
          }
        '''
    }

    protected def CharSequence createDeclarations(State state) {
        val declarations = rootState.declarations.filter(VariableDeclaration).map[it.valuedObjects].flatten.toList

        return '''
          « IF declarations.size > 0 »
            « FOR valuedObject : declarations »
              « createDeclaration(valuedObject) »

            « ENDFOR »
          « ENDIF »
        '''
    }

    protected def CharSequence createDeclaration(ValuedObject vo) {
        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        val voType = if (vo.type != ValueType.HOST || vo.variableDeclaration.hostType.nullOrEmpty) {
                vo.variableDeclaration.type.serializeHR
            } else {
                vo.variableDeclaration.hostType
            }
        val voCardinals = if (vo.isArray) {
                '''[«FOR cardinal : vo.cardinalities SEPARATOR ']['»« cardinal.serializeHR »«ENDFOR»]'''
            } else {
                ''
            }

        return '''
            private « voType » « vo.name »« IF vo.isArray »[] = new « voType »« ENDIF »« voCardinals »;« IF vo.isInput » // Input« ENDIF »« IF vo.isOutput » // Output«ENDIF»
            « IF !vo.variableDeclaration.hasAnnotation("InputEvent") »
              « IF vo.isOutput »
                public « voType »« IF vo.isArray »[]« ENDIF » « IF vo.isBool »is« ELSE »get« ENDIF »« vo.name.toFirstUpper »() {
                  assertAccessFromValidThread();
                  return « vo.name »;
                }
              « ENDIF »
              « IF vo.isInput »
                public void set« vo.name.toFirstUpper »(final « voType »« IF vo.isArray »[]« ENDIF » « vo.name ») {
                  assertAccessFromValidThread();
                  iface.« vo.name » = « vo.name »;
                }
              « ENDIF »
            « ENDIF »
        '''
        //CHECKSTYLEON LineLength
    }

    protected def createContextInterface() {
        if (generateContextInterface) {
            // We want to support method overloading (at least roughly)
            // So we gather all method calls and store the information of the used argument types 
            val Multimap<ReferenceDeclaration, List<CharSequence>> referenceUsages = HashMultimap.create
            // Grab all function calls to context methods
            val calls = rootState.eAllContents.filter(ReferenceCall).filter [
                valuedObject.referenceDeclaration.annotations.exists['Context'.equalsIgnoreCase(name)]
            ].toList
            // Gather all different parameter lists we can find
            for (call : calls) {
                // Use the declaration as the key to map the different calls to the same object
                val decl = call.valuedObject.referenceDeclaration
                // Map the parameters to the type by using the existing type inference
                // TODO This inference might need some work to support all cases
                val params = call.parameters.map[expression.inferTypeWithHostTypes]
                if (!referenceUsages.get(decl).exists[it.typesEqual(params)]) {
                    referenceUsages.put(decl, params)
                }
            }

            // Go through all different usages and serialize a method head for each
            context.append('''
              @SuppressWarnings({"unused","javadoc"})
              @de.scheidtbachmann.statemachine.runtime.ContextForStateMachine(« rootState.uniqueName ».class)
              @de.scheidtbachmann.statemachine.runtime.Generated(message = "de.scheidtbachmann.statemachine.compiler")
              public interface « rootState.uniqueName»«StatebasedLeanJavaCodeGenerator.CONTEXT_SUFFIX » {
                « FOR usage : referenceUsages.entries.sortBy[key.extern.head.code] »
                  « generateMethod(usage.key, usage.value) »
                « ENDFOR »
              }
            ''')
        }
    }

    /**
     * Compare two lists of parameter type strings 
     */
    protected def Boolean typesEqual(List<CharSequence> params1, List<CharSequence> params2) {
        return params1.join(',').equals(params2.join(','))
    }

    /**
     * Try to infer the type of an expression and 
     * create the string representation of the type.
     */
    protected def CharSequence inferTypeWithHostTypes(Expression expression) {
        // We first try the pre-implemented inference, that is able to detect mostly primitive types
        if (expression.inferType != ValueType.UNKNOWN) {
            return expression.inferType.serialize
        } else {
            // The first try returned unknown, so we have to step in. We mostly deal with references to host calls or objects.
            if (expression instanceof ValuedObjectReference) {
                // It is some kind of Reference, it could be many things, but let's start with VOs and calls 
                if (expression instanceof ReferenceCall) {
                    // Just hand it over to the annotation detection
                    return extractContextType(expression.valuedObject.declaration.asReferenceDeclaration)
                } else {
                    // Extract the host type directly from the VO
                    expression.valuedObject.declaration.asVariableDeclaration.hostType
                }
            } else {
                return 'Object'
            }
        }
    }

    /**
     * Generates the method head with the given list of types 
     */
    protected def CharSequence generateMethod(ReferenceDeclaration decl, List<CharSequence> types) {
        val paramList = if (types.length > 1) {
                // If we have multiple parameters, we want to count them down.
                // Sadly, we have to go through the list with a loop and count them manually
                // as there is no way to get the counter through a .map[], right?
                var int i = 0
                // Serialize the type to make sure it is matched to Java (i.e. String vs. string)
                '''«FOR type : types»«type» «INTERFACE_PARAM_NAME»«i++»« IF i < types.length», « ENDIF »«ENDFOR»'''
            } else {
                // If we have (at most) one parameter, we just call it whatever
                types.map[it + " " + INTERFACE_PARAM_NAME].join()
            }
            val comments = decl.annotations.filter(CommentAnnotation).head;

        '''

            « IF comments !== null »
            /**
             « FOR comment : comments.values »
             « FOR line : comment.split("\n") »
             * « line »
             « ENDFOR » 
             « ENDFOR »
             */
            « ENDIF »
            « extractContextType(decl) » « decl.extern.head.code »(« paramList »);
        '''
    }

    /**
     * Checks the given declaration for annotations with the return type. 
     */
    protected def extractContextType(ReferenceDeclaration decl) {
        val typeAnnotations = decl.annotations
            .filter(StringAnnotation)
            .filter['Context'.equalsIgnoreCase(name)]
            .filter [!values.nullOrEmpty]
        if (typeAnnotations.size == 0) {
            return "void"
        } else {
            return typeAnnotations.head.values.head
        }
    }

    private def generateJavaDocFromCommentAnnotations(Annotatable annotatable) {
        val comments = annotatable.annotations.filter(CommentAnnotation);
        return '''
            « IF comments !== null && !comments.empty »
                /**
                 « FOR commentAnnotation : comments»
                    « FOR comment : commentAnnotation.values »
                        « FOR line : comment.split("\n") »
                            * « line »
                        « ENDFOR » 
                    « ENDFOR »
                 « ENDFOR »
                 */
            « ENDIF »
        '''
    }
    
    protected def addTransitionComment(Transition transition) {
        val commentString = transition.annotations?.filter(CommentAnnotation).last?.values?.last
        if (commentString !== null && !commentString.equals("")) {
            return ''' // « commentString »'''
        }
    }
    
    private def CharSequence generateTraceLogging(String log) {
        return '''
            « IF isLoggingEnabled »
              LOG.trace(loggingPrefix + " - " + « log »);
            « ENDIF »
        '''
    }    

    private def CharSequence generateDebugLogging(String log) {
        return '''
            « IF isLoggingEnabled »
              LOG.debug(loggingPrefix + " - " + « log »);
            « ENDIF »
        '''
    }    

    private def CharSequence generateErrorLogging(String log) {
        return '''
            « IF isLoggingEnabled »
              LOG.error(loggingPrefix + " - " + « log »);
            « ENDIF »
        '''
    }

    private def boolean isLoggingEnabled() {
        return !featureOverrides.contains(StatebasedLeanJavaFeatureOverrides.NO_LOGGER)
    }
    
    private def boolean isExecutorEnabled() {
        return !featureOverrides.contains(StatebasedLeanJavaFeatureOverrides.NO_EXECUTOR) 
    }
    
    private def boolean isStringContainerEnabled() {
        return !featureOverrides.contains(StatebasedLeanJavaFeatureOverrides.NO_STRING_CONTAINER)
    }
    
    private def boolean isThreadAccessWarnOnly() {
        return featureOverrides.contains(StatebasedLeanJavaFeatureOverrides.THREADACCESS_WARN_ONLY)
    }
    
    private def boolean isHistoryEnabled() {
        return !featureOverrides.contains(StatebasedLeanJavaFeatureOverrides.NO_HISTORY)
    }
    
    private def boolean isIfaceNeeded() {
        return rootState.declarations.filter(VariableDeclaration).map[it.valuedObjects].flatten.size > 0
    }
    
    private def void addImports(String... newImports) {
        newImports.forEach[newImport |
            modifications.put("imports", newImport)
        ]
    }
    
    private def String getSourceState(State s) {
        return (s.getAnnotations("SourceState").last as StringAnnotation).values.head 
    }

    private def boolean needsDelayedEnabled(ControlflowRegion r) {
        return r.states.exists[s | s.outgoingTransitions.exists[t | !t.isImmediate && !t.isImplicitlyImmediate ]]
    }

    protected def findModifications() {
        return modifications
    }
}
