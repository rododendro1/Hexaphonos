// El módulo `Armonia` no tiene código propio: reexporta los de cada capa y de cada familia, de modo que
// `import Armonia` da la API de siempre. Quien solo necesite una capa puede importarla sola
// (`import ArmoniaTeoria` trae el Núcleo, de que depende, pero no la Partitura ni las Representaciones).

@_exported import ArmoniaNucleo
@_exported import ArmoniaTeoria
@_exported import ArmoniaRepresentaciones
@_exported import ArmoniaPartitura
@_exported import ArmoniaTrastes
