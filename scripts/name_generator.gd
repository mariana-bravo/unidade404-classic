class_name NameGenerator
extends RefCounted

const SUBSTANTIVOS := [
    {"nome": "Operário", "genero": "m"},
    {"nome": "Unidade", "genero": "f"},
    {"nome": "Chassi", "genero": "m"},
    {"nome": "Sucata", "genero": "f"},
    {"nome": "Autômato", "genero": "m"},
    {"nome": "Máquina", "genero": "f"}
]
const COMPLEMENTOS := [
    {"m": "Cansado", "f": "Cansada"},
    {"m": "Desligado", "f": "Desligada"},
    {"m": "Defeituoso", "f": "Defeituosa"},
    {"m": "em Greve", "f": "em Greve"},
    {"m": "Sem Memória", "f": "Sem Memória"},
    {"m": "do Paraguai", "f": "do Paraguai"},
    {"m": "de Taubaté", "f": "de Taubaté"},
    {"m": "da Shopee", "f": "da Shopee"}
]

static func gerar_nome_robo() -> Dictionary:
    var base: Dictionary = SUBSTANTIVOS.pick_random()
    var complemento: Dictionary = COMPLEMENTOS.pick_random()
    return {"nome": "%s %s" % [base["nome"], complemento[base["genero"]]], "genero": base["genero"]}
