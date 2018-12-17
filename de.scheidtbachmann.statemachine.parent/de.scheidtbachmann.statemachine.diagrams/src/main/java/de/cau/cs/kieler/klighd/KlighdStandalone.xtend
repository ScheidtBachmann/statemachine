package de.cau.cs.kieler.klighd

import de.cau.cs.kieler.klighd.internal.ISynthesis
import de.cau.cs.kieler.klighd.krendering.SimpleUpdateStrategy
import de.cau.cs.kieler.klighd.piccolo.export.BitmapOffscreenRenderer
import de.cau.cs.kieler.klighd.piccolo.export.KlighdAbstractSVGGraphics
import de.cau.cs.kieler.klighd.piccolo.export.SVGGeneratorManager
import de.cau.cs.kieler.klighd.piccolo.export.SVGOffscreenRenderer
import de.cau.cs.kieler.klighd.piccolo.freehep.SemanticFreeHEPSVGGraphics
import de.cau.cs.kieler.klighd.piccolo.viewer.PiccoloViewer
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import de.cau.cs.kieler.klighd.syntheses.ReinitializingDiagramSynthesisProxy
import java.util.ServiceLoader
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.IConfigurationElement
import org.eclipse.core.runtime.InvalidRegistryObjectException
import org.eclipse.elk.alg.force.options.ForceMetaDataProvider
import org.eclipse.elk.alg.graphviz.layouter.GraphvizMetaDataProvider
import org.eclipse.elk.alg.layered.options.LayeredMetaDataProvider
import org.eclipse.elk.alg.mrtree.options.MrTreeMetaDataProvider
import org.eclipse.elk.alg.radial.options.RadialMetaDataProvider
import org.eclipse.elk.core.data.LayoutMetaDataService
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static de.cau.cs.kieler.klighd.KlighdDataManager.*

class KlighdStandalone {
	
	static Object staticInitializer = [ |
		LayoutMetaDataService.instance.registerLayoutMetaDataProviders(
			new GraphvizMetaDataProvider,
			new ForceMetaDataProvider,
			new LayeredMetaDataProvider,
			new MrTreeMetaDataProvider,
			new RadialMetaDataProvider);
		
		return null;
	].apply()
	
	
	static def IConfigurationElement[] getStandaloneExtensions(String extensionPointName) {
		switch extensionPointName {
			case EXTP_ID_DIAGRAM_SYNTHESES: {
				ServiceLoader.load(AbstractDiagramSynthesis, KlighdStandalone.classLoader).iterator.map[ it |
					new DiagramSynthesisExtension(it.class as Class<AbstractDiagramSynthesis<?>>)
				].toList
			}
			case EXTP_ID_EXTENSIONS:
				#[
					new ViewerExtension(PiccoloViewer.Provider),
					new UpdateStrategyExtension(SimpleUpdateStrategy),
					new OffscreenRendererExtension(BitmapOffscreenRenderer, 'bmp,jpeg,png'),
					new OffscreenRendererExtension(SVGOffscreenRenderer, 'svg')
				]
			case SVGGeneratorManager.EXTP_ID_SVGGENERATORS: {
				#[
					new SVGGeneratorExtension('de.cau.cs.kieler.klighd.piccolo.svggen.freeHEPExtended', SemanticFreeHEPSVGGraphics)
				]
			}
			default:
				#[]
		}
	}
	
	static class ViewerExtension extends KlighdExtension<IViewerProvider> {
		new(Class<? extends IViewerProvider> clazz) {
			super(ELEMENT_VIEWER, clazz)
		}
	}
	
	static class UpdateStrategyExtension extends KlighdExtension<IUpdateStrategy> {
		new(Class<? extends IUpdateStrategy> clazz) {
			super(ELEMENT_UPDATE_STRATEGY, clazz)
		}
	}
	
	static class OffscreenRendererExtension extends KlighdExtension<IOffscreenRenderer> {
		val String supportedFormats
		
		new(Class<? extends IOffscreenRenderer> clazz, String supportedFormats) {
			super(ELEMENT_OFFSCREEN_RENDERER, clazz)
			this.supportedFormats = supportedFormats
		}
		
		override getAttribute(String name) throws InvalidRegistryObjectException {
			switch name {
				case ATTRIBUTE_SUPPORTED_FORMATS: supportedFormats
				default: super.getAttribute(name)
			}
		}
	}
	
	static class SVGGeneratorExtension extends KlighdExtension<KlighdAbstractSVGGraphics> {
	
		new(String id, Class<? extends KlighdAbstractSVGGraphics> clazz) {
			super(null, id, clazz)
		}
	}
	
//	static class DiagramExporterExtension extends KlighdExtension<IDiagramExporter> {
//		val String fileExtension
//		new(Class<? extends IDiagramExporter> clazz, String fileExtension) {
//			super(ELEMENT_EXPORTER, clazz)
//			this.fileExtension = fileExtension
//		}
//		
//		override getAttribute(String name) throws InvalidRegistryObjectException {
//			switch name {
//				case 'extension': fileExtension
//				default: super.getAttribute(name)
//			}
//		}
//	}
	
	static class DiagramSynthesisExtension<T> extends KlighdExtension<ISynthesis> {
		val Class<AbstractDiagramSynthesis<T>> clazz
		
		new(Class<? extends AbstractDiagramSynthesis<T>> clazz) {
			super(ELEMENT_DIAGRAM_SYNTHESIS, clazz)
			this.clazz = clazz as Class<AbstractDiagramSynthesis<T>>
		}
		
		override createExecutableExtension(String propertyName) throws CoreException {
			if (clazz === null)
				throw new NullPointerException
			else
				return new ReinitializingDiagramSynthesisProxy(clazz) {};
		}
	}
	
	@Data
	@FinalFieldsConstructor
	private static class KlighdExtension<T> extends AbstractConfigurationElement {
		
		val String elementName
		val String id
		val Class<? extends T> clazz
		
		new(String elementName, Class<? extends T> clazz) {
			this(elementName, clazz.canonicalName, clazz)
		}
		
		override getName() throws InvalidRegistryObjectException {
			elementName
		}
		
		override getAttribute(String name) throws InvalidRegistryObjectException {
			switch name {
				case ATTRIBUTE_ID: id
				case ATTRIBUTE_CLASS: clazz.canonicalName
			}
		}
		
		override T createExecutableExtension(String propertyName) throws CoreException {
			if (clazz === null)
				throw new NullPointerException()
			else
				clazz.newInstance as T
		}
	}
	
	private static class AbstractConfigurationElement implements IConfigurationElement {
		
		override createExecutableExtension(String arg0) throws CoreException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getAttribute(String arg0) throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getAttribute(String arg0, String arg1) throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getAttributeAsIs(String arg0) throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getAttributeNames() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getChildren() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getChildren(String arg0) throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getContributor() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getDeclaringExtension() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getName() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getNamespace() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getNamespaceIdentifier() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getParent() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getValue() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getValue(String arg0) throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override getValueAsIs() throws InvalidRegistryObjectException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override isValid() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	}
}