# Lab 02 — ClubHub Rescue

**Linux Fundamentals · Where Applications Run**
Cellule DevOps · Club Informatique & Télécom · Durée : 60 min · En binôme

> Vendredi, 23 h 47. Les inscriptions au hackathon du club ouvrent demain matin… et le serveur ClubHub ne répond plus.
> L'ancien admin est parti en vacances sans documentation. Pas d'interface graphique, pas de souris : **juste un terminal**.
> À vous de remettre ClubHub en ligne.

## Objectifs

À la fin du lab, vous saurez :

- vous déplacer dans un système de fichiers Linux (`pwd`, `ls`, `cd`) ;
- lire et chercher dans des fichiers (`cat`, `less`, `head`, `tail`, `grep`, `find`) ;
- copier et modifier un fichier de configuration (`cp`, `nano`) ;
- comprendre et changer des permissions (`ls -l`, `chmod`) ;
- trouver et arrêter un processus (`ps`, `kill`) ;
- vérifier qu'un service répond sur un port (`curl`).

C'est exactement ce que fait un ingénieur DevOps quand un serveur tombe en panne.

---

## 0. Préparer la mission (5 min)

Vous avez besoin d'un terminal Linux. Au choix :

| Environnement | Comment l'ouvrir |
| --- | --- |
| VM Ubuntu (VirtualBox) | Ouvrir l'application **Terminal** |
| WSL sur Windows | Menu Démarrer → **Ubuntu** |
| Navigateur | [killercoda.com/playgrounds/scenario/ubuntu](https://killercoda.com/playgrounds/scenario/ubuntu) |

Récupérez le script `setup.sh` donné par votre formateur, puis lancez :

```bash
bash setup.sh
cd ~/clubhub-rescue
cat README.txt
```

> Si `python3` ou `curl` manque : `sudo apt update && sudo apt install -y python3 curl`

### Les règles du jeu

- Chaque mission rapporte un **flag** de la forme `CLUB{...}`.
- Notez chaque flag dans `flags.txt` :
  ```bash
  echo 'CLUB{le_flag_trouvé}' >> ~/clubhub-rescue/flags.txt
  ```
  `>>` **ajoute** une ligne à la fin du fichier. (`>` l'écraserait : attention !)
- Vérifiez votre progression à tout moment : `./check.sh`
- Interdit d'ouvrir `setup.sh` : un vrai admin n'a pas de corrigé.
- Les indices sont cachés : ouvrez-les seulement si vous êtes bloqués.

---

## Antisèche

| Commande | Ce qu'elle fait | Exemple |
| --- | --- | --- |
| `pwd` | Où suis-je ? | `pwd` |
| `ls` / `ls -a` / `ls -l` | Lister / avec les fichiers cachés / avec les détails | `ls -la` |
| `cd` | Changer de dossier (`..` = dossier parent, `~` = maison) | `cd server/var/log` |
| `cat` | Afficher un fichier | `cat todo.txt` |
| `less` | Lire un long fichier (`q` pour quitter, `/mot` pour chercher) | `less clubhub.log` |
| `head` / `tail` | Début / fin d'un fichier | `tail -n 20 clubhub.log` |
| `grep` | Chercher un mot dans un fichier | `grep ERROR clubhub.log` |
| `wc -l` | Compter les lignes | `wc -l clubhub.log` |
| `\|` (pipe) | Envoyer le résultat d'une commande à une autre | `grep ERROR clubhub.log \| wc -l` |
| `find` | Chercher un fichier par son nom | `find . -name "*.conf"` |
| `cp` / `mv` / `rm` | Copier / déplacer-renommer / supprimer | `cp a.conf a.conf.bak` |
| `nano` | Éditer un fichier (`Ctrl+O` enregistrer, `Ctrl+X` quitter) | `nano clubhub.conf` |
| `chmod` | Changer les permissions | `chmod +x start.sh` |
| `ps aux` | Lister les processus | `ps aux \| grep python` |
| `kill` | Arrêter un processus par son PID | `kill 1234` |
| `curl` | Faire une requête HTTP | `curl http://localhost:8090` |
| `man` / `--help` | Lire la documentation | `man ls` |

Astuce : la touche **Tab** complète les noms de fichiers, et **↑** rappelle les commandes précédentes.

---

## Mission 1 · Le dossier de l'admin (8 min)

L'admin a dit : « J'ai laissé une note dans mon dossier personnel du serveur ». Son dossier est `server/home/admin/`.

**Objectif :** trouver la note et son flag.

<details><summary>Indice 1</summary>

Allez dans le dossier avec `cd`, puis regardez son contenu avec `ls`. Vous ne voyez que `todo.txt` et `Documents`… lisez quand même `todo.txt`.
</details>

<details><summary>Indice 2</summary>

Sous Linux, un fichier dont le nom commence par un point est **caché**. Quelle option de `ls` affiche *tout* (« all ») ?
</details>

**Question :** quel est le chemin absolu du dossier de l'admin ? (`pwd`)

---

## Mission 2 · Les logs ne mentent jamais (10 min)

La note vous envoie vers `server/var/log/clubhub.log`.

**Objectifs :**
1. Le fichier est très long : combien de lignes contient-il ?
2. Lisez **la fin** du fichier : que s'est-il passé ? Notez les 3 problèmes que vous voyez.
3. Combien de lignes contiennent `ERROR` ? (avant de lancer `start.sh`, qui écrira de nouvelles erreurs)
4. Un flag est caché quelque part dans le fichier. Trouvez-le sans tout lire.

<details><summary>Indice 1</summary>

`cat` affiche tout d'un coup, c'est illisible. Essayez `head`, `tail -n 20` ou `less`.
</details>

<details><summary>Indice 2</summary>

`grep MOT fichier` n'affiche que les lignes qui contiennent MOT. Avec `| wc -l`, vous comptez ces lignes.
</details>

> **Dans la vraie vie :** quand un service tombe, le premier réflexe d'un DevOps est `tail` sur les logs. Plus tard (séance 09), on enverra ces logs vers un outil de monitoring.

---

## Mission 3 · La configuration perdue (12 min)

Les logs parlent d'un fichier `clubhub.conf` perdu pendant la migration. Il est quelque part dans `server/etc/`, au milieu de dizaines de dossiers.

**Objectifs :**
1. Trouver le **bon** fichier `clubhub.conf` (attention aux pièges).
2. Faire une **sauvegarde** avant de modifier : `clubhub.conf.bak` dans le même dossier.
3. Corriger le port : les logs indiquent le port officiel de ClubHub.

<details><summary>Indice 1</summary>

Fouiller dossier par dossier prendrait des heures. `find` sait chercher par nom dans toute une arborescence : `find server -name "..."`.
</details>

<details><summary>Indice 2</summary>

`cp fichier fichier.bak` crée la copie. Ensuite `nano fichier`, modifiez la ligne `PORT=`, puis `Ctrl+O`, `Entrée`, `Ctrl+X`.
</details>

**Question :** pourquoi le port 80 ne marche-t-il pas pour un utilisateur normal ?

> **Dans la vraie vie :** on ne modifie jamais une config de production sans sauvegarde. À la séance 03, Git fera ce travail pour nous ; à la séance 08, Ansible écrira ces fichiers automatiquement.

---

## Mission 4 · Permission denied (8 min)

Le script de démarrage est dans `server/opt/clubhub/`. Lancez-le :

```bash
cd ~/clubhub-rescue/server/opt/clubhub
./start.sh
```

**Objectifs :**
1. Comprendre l'erreur en lisant les permissions du fichier.
2. Rendre le script exécutable, puis le relancer. Le flag apparaît dès qu'il s'exécute.

<details><summary>Indice 1</summary>

`ls -l` affiche par exemple `-rw-r--r--`. `r` = lire, `w` = écrire, `x` = exécuter. Il manque une lettre…
</details>

<details><summary>Indice 2</summary>

`chmod +x fichier` ajoute le droit d'exécution.
</details>

**Question :** que veulent dire les trois groupes `rw-` `r--` `r--` ?

---

## Mission 5 · Le processus zombie (10 min)

Le script s'exécute… mais affiche `Address already in use`. Un autre programme occupe le port 8090.

**Objectifs :**
1. Demandez au port 8090 qui il est : `curl http://localhost:8090`
2. Trouvez le **PID** du processus coupable.
3. Arrêtez-le proprement.

<details><summary>Indice 1</summary>

`ps aux` liste tous les processus. C'est long : filtrez avec `| grep zombie`. Le PID est la 2ᵉ colonne.
</details>

<details><summary>Indice 2</summary>

`kill PID` envoie un signal d'arrêt. Vérifiez ensuite avec `ps aux | grep zombie` qu'il a disparu (la ligne `grep zombie` elle-même ne compte pas).
</details>

> **Dans la vraie vie :** « le port est déjà utilisé » est l'une des erreurs les plus fréquentes en production. À la séance 10, Kubernetes redémarrera et arrêtera les processus à notre place.

---

## Mission 6 · ClubHub is back! (7 min)

**Objectifs :**
1. Relancez `./start.sh`.
2. Vérifiez que ClubHub répond, **depuis le terminal**.
3. Récupérez le dernier flag, puis lancez `~/clubhub-rescue/check.sh`.

Si tout est vert : félicitations, vous avez sauvé le hackathon !

---

## Bonus (pour les plus rapides)

**Bonus A · Disque plein.** Un fichier énorme et caché encombre `server/tmp/`. Trouvez-le et supprimez-le.
*Pistes :* `du -ah server | sort -h | tail`, ou `find server -size +10M`.

**Bonus B · Votre premier script de supervision.** Créez `~/clubhub-rescue/status.sh` qui affiche `ClubHub: UP` si le site répond, sinon `ClubHub: DOWN`. Rendez-le exécutable.
*Piste :* `curl -s http://localhost:8090 > /dev/null && echo "ClubHub: UP" || echo "ClubHub: DOWN"`

**Bonus C · Carte d'identité du serveur.** Enregistrez dans `~/clubhub-rescue/whoami.txt` : votre utilisateur, le nom de la machine et la version du noyau.
*Pistes :* `whoami`, `hostname`, `uname -a`, et la redirection `>>`.

---

## Débrief : pourquoi Linux en DevOps ?

| Mission | Compétence Linux | Ce que fait un DevOps avec |
| --- | --- | --- |
| 1 | Navigation, fichiers cachés | Explorer un serveur inconnu via SSH |
| 2 | `tail`, `grep`, pipes | Diagnostiquer une panne depuis les logs |
| 3 | `find`, `cp`, `nano` | Retrouver et corriger une configuration |
| 4 | Permissions, `chmod` | Rendre exécutables les scripts de déploiement |
| 5 | Processus, `ps`, `kill`, ports | Libérer un port, arrêter un service bloqué |
| 6 | `curl` | Vérifier qu'un service répond (health check) |
| Bonus B | Script bash | Automatiser une vérification : le début de l'automatisation |

La grande majorité des serveurs web, des conteneurs Docker et des clusters Kubernetes tournent sous Linux. Tout ce que vous verrez dans la suite de la formation s'appuie sur ces commandes.

## Bloqué ou tout cassé ?

```bash
bash setup.sh --reset   # recommence la mission depuis zéro
bash setup.sh --stop    # arrête les processus du lab à la fin de la séance
```

Si votre machine a redémarré pendant le lab, le zombie a disparu : faites `bash setup.sh --reset`.
