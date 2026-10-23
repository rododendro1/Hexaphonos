import ArmoniaCLI
import Foundation

let resultado = LineaDeComandos.ejecutar(Array(CommandLine.arguments.dropFirst()))
if let datos = resultado.datos {
    // Un fichero binario no se escribe en la terminal.
    guard isatty(STDOUT_FILENO) == 0 else {
        FileHandle.standardError.write(Data("armonia: el MIDI es un fichero binario; guárdalo con > fichero.mid\n".utf8))
        exit(2)
    }
    FileHandle.standardOutput.write(datos)
} else {
    FileHandle.standardOutput.write(Data(resultado.salida.utf8))
}
FileHandle.standardError.write(Data(resultado.error.utf8))
exit(resultado.codigo)
