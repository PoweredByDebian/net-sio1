# Réseau : BTS SIO 1

Labs [Kathara](https://www.kathara.org/) et programmes de contrôle `./check` des TP de réseau
(cours net01 à net07) du BTS SIO 1, Campus Beaupeyrat. Un dossier par TP (`net01/`…), un dossier
par lab dedans (`lab1-config/`…).

## Récupérer les labs (une fois, sur votre VM)

```bash
git clone https://github.com/PoweredByDebian/net-sio1.git
```

## À chaque TP

Mettez le dépôt à jour, puis placez-vous dans le dossier du TP :

```bash
cd ~/net-sio1 && git pull
cd net02
```

Un lab se démarre dans son dossier (`cd lab1-config`, puis `kathara lstart --noterminals`) et
s'arrête avec `kathara lclean`.

## Faire le point

Depuis le dossier du TP (`~/net-sio1/net02`), pendant que le lab de la mission tourne :

```bash
./check            # toutes les missions
./check 2          # la mission 2 seulement
./check --reset    # remet les missions à zéro
```

✓ c'est bon, ✗ c'est à revoir (avec un conseil). Une mission validée le reste, même après l'arrêt
du lab. Quand tout est juste, il finit par `exit 0` : appelez le professeur. Il ne modifie rien
dans les labs. L'ancien nom `./verifier` marche encore : c'est un raccourci vers `./check`.

## Si `git pull` refuse

Vous avez modifié un fichier (un `.startup`…) que le professeur a aussi corrigé. Mettez vos modifications
de côté, mettez à jour, puis reprenez-les :

```bash
git stash && git pull && git stash pop
```

## À savoir

- Ce dépôt ne contient **aucune réponse** : les valeurs à trouver y sont vérifiées par empreinte
  (sha256), elles ne sont pas lisibles.
- `./check` sert à **vous guider**. Ce n'est pas lui qui note le TP.

---

Florent `fls` Sautour · Campus Beaupeyrat · code sous licence GPL-3.0-or-later (fichier `LICENSE`).
