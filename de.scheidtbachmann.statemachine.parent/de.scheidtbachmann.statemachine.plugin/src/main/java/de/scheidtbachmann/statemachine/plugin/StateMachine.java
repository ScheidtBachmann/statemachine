package de.scheidtbachmann.statemachine.plugin;

public class StateMachine {
	/** The file name of the stateMachine that should be compiled. */
	private String fileName;

	/** The folder the generated files should be placed in */
	private String outputFolder = "sm-gen";

	/** The compilation strategy to use during code generation */
	private String strategy = "de.cau.cs.kieler.sccharts.statebased";
	
	/** The model that should be taken from the file if multiple models are defined in one chart */
	private String selectedModel;

	public String getFileName() {
		return fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}

	public String getOutputFolder() {
		return outputFolder;
	}

	public void setOutputFolder(String outputFolder) {
		this.outputFolder = outputFolder;
	}

	public String getStrategy() {
		return strategy;
	}

	public void setStrategy(String strategy) {
		this.strategy = strategy;
	}

	public String getSelectedModel() {
		return selectedModel;
	}

	public void setSelectedModel(String selectedModel) {
		this.selectedModel = selectedModel;
	}
}
