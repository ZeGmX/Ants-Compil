# Compilateur Ants


Chambard Mathieu
Espana Gutierrez Pablo
Mulot Lendy
Neyrand Côme

Notre langage se nomme DNAnt.
Ce langage comporte plusieurs structures de contrôle familières à l'utilisateur
telles que IF, ELSE, WHILE, REPEAT, DEF, CALL...
Il ne possède pas de Goto.
La création d'un fichier .brain se réalise grâce à la commande :

./antsc Fichier_Entree > Fichier_Sortie

Guide pour l'utilisateur :

Chaque structure de contrôle commence et se termine par un élément propre.
L'utilisateur a accès à un certain nombre de fonctions prédéfinies.
Pour la structure de boucle conditionnelle, ce dernier peut tester une condition
fabriquée à partir des tests que peut réaliser la fourmi et des opérateurs logiques
usuels (ET, OU, EGAL, NON...). Il est à noter que la fourmi ne peut réaliser
qu'un seul test par étape, et que des conditions composées de plusieurs tests
peuvent donc prendre plusieurs étapes.

ex :

if [(food aleft and foe aleft) or {marker ahead 0 == marker aleft 0}] then
  turn left
else
  turn right
endif

Concernant la boucle while, on ne peut réaliser qu'un seul test simple
(sans opérateurs logiques). 

L'instruction repeat permet de répéter plusieurs commandes un certain nombre
de fois afin de rendre le code plus lisible pour l'utilisateur.

Les instructions def et call vont de paire : l'utilisateur peut définir un bloc
d'instruction avec def en lui assignant un identifiant (ici un entier) puis
l'appeler plus tard avec call. Attention cependant à ne pas appeler avant d'avoir
défini en amont dans le code ! Si on effectue un call d'une fonction non définie,
le compilateur renverra un message d'erreur associé.

L'utilisateur peut également laisser des commentaires dans son code. Il faut
cependant mettre un point entre chaque caractère...

ex :

/* f.o.n.c.t.i.o.n */ $ /* d.e.m.i.t.o.u.r */ $
def 0 :
  repeat 3 times :
    turn left
  endrepeat;
  moveerror enderror  
enddef

$

/* c.o.l.l.i.s.i.o.n */ $
while rock ahead :
  call 0 endcall
endwhile

$

moveerror turn left enderror


Nous avons également joint un fichier écrit en DNAnt (Fichier_entree.txt) dans
le répertoire ants, qui, une fois compilé en our_first.brain, réussit à vaincre
random_search.brain en duel (c'est un début !).


Pour arriver au bout de ce projet, nous avons dans un premier temps implémenté 
les fonctions de bases du langage d'arrivé dans notre langage de départ, puis 
nous avons réfléchies aux fonctionnalités qui pourraient être utiles dans le 
but particulier de controler les fourmis, avant de les implémenter.

## Dépendances

Le compilateur est compilé avec les dépendances suivantes :

  - OCaml 4.08 ou plus
  - Le système de construction [Dune](https://dune.build/) version 1.11 ou plus
  - Le générateur de parser [`simple-parser-gen`](https://github.com/timothee-haudebourg/ocaml-simple-parser)
  - `ocp-indent` pour indenter les fichiers générés par le générateur de parser.

Si OPAM (version 2 ou plus) est installé, l'installation des dépendances
se fait en deux lignes dans votre terminal :
```
$ opam install ocamlfind dune ocp-indent
$ curl http://people.irisa.fr/Timothee.Haudebourg/teaching/prog1/projects/ants/install-deps.sh | sh
```

Vous pouvez tester la bonne installation de `simple-parser-gen` avec la commande
```
$ simple-parser-gen --help
```

## Compilation

En vous plaçant dans le répertoire contenant le fichier `Makefile`,
exécutez la commande :
```
$ make
```

L’exécutable `antsc` et tous les fichiers nécessaires à sa création seront
construits en utilisant les règles décrites dans le `Makefile`.

### Génération du parser

La génération du parser est effectuée dans le `Makefile` grâce à l’outil
`simple-parser-gen`. L'outil prend en entrée le fichier `src/lang.grammar`
décrivant la grammaire du langage que vous souhaitez compiler.
3 modules sont ainsi générés, en 6 fichiers :

  - Le module `Ast` (fichiers `ast.ml`, `ast.mli`) contient la définition
    de l'arbre de syntaxe abstraite (la structure d'un programme) du langage,
    et des fonctions d'affichage.
    ```
    simple-parser-gen --ast src/lang.grammar | ocp-indent > src/ast.ml
    ```
    Le pipe `|` redirige la sortie de `simple-parser-gen` vers `ocp-indent` pour
    indenter le code généré. Enfin `>` écrit la sortie dans le fichier `src/ast.ml`.

    Le fichier `src/ast.mli` est généré de la même manière en passant l'option
    `-i` (pour "interface") à `simple-parser-gen`.

  - Le module `Lexer` (fichiers `lexer.ml`, `lexer.mli`) contient le *lexer*
    du langage, qui s'occupe de découper les mots du langage.
    Il est généré avec l'option `--lexer` de `simple-parser-gen`.

  - Le module `Parser` (fichiers `parser.ml`, `parser.mli`) contient le *parser*
    du langage, qui s'occupe de générer un arbre de syntaxe abstraite à partir
    d'un *lexer*.
