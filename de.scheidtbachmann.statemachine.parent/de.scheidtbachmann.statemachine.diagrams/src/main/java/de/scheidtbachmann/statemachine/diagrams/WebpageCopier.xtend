package de.scheidtbachmann.statemachine.diagrams

import java.io.Closeable
import java.nio.file.FileSystemNotFoundException
import java.nio.file.FileSystems
import java.nio.file.Path
import java.nio.file.Paths
import java.util.jar.JarFile

import static java.nio.file.StandardCopyOption.*

import static extension java.nio.file.Files.*

class WebpageCopier {
	
	static val PAGE_FOLDER_NAME = 'page'
	
	def static copyStaticPageParts(Path outlet) {
		var Closeable closeable
		val it = WebpageCopier.classLoader.getResource(PAGE_FOLDER_NAME)
		if (protocol == 'jar') {
			val file = new JarFile(file.substring(0, file.indexOf('!')).replaceFirst('^file:', ''))
			closeable = file
			file.stream.filter[
				!isDirectory && name.startsWith(PAGE_FOLDER_NAME)
			].forEach[
				val target = outlet.resolve(Paths.get(name.substring(5)))
				target.parent.createDirectories()
				file.getInputStream(it).copy(target, REPLACE_EXISTING)
			]
		} else {
			try {
				FileSystems.getFileSystem(toURI);
			} catch ( FileSystemNotFoundException e ) {
				closeable = FileSystems.newFileSystem(toURI, emptyMap)
			} catch ( Throwable t) {
				// do nothing; chsch: on osx I get an IllegalArgumentException if the path is unequal to '/'
			}
			
			val root = Paths.get(toURI)
			for (it :  root.find(5)[ it, attributes | attributes.regularFile ].iterator.toIterable) {
				val target = outlet.resolve(root.relativize(it))
				target.parent.createDirectories()
				copy(target, REPLACE_EXISTING)
			}
		}
		closeable?.close()
	}
}