# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Florent « fls » Sautour, Campus Beaupeyrat
#
# lib/check.sh : fonctions communes aux programmes ./check des TP reseau (serie net, labs Kathara).
# Source unique : sources/sio1/net-sio1/lib/ dans cours-fls (chaque netXX/lab/lib en est un lien). Publiee
# a la racine du depot public net-sio1 (netXX/lib -> ../lib) et copiee dans les archives .zip (voir
# publish.sh et make-lab-zip.sh). A charger depuis check :
#   . "$(dirname "$(readlink -f "$0")")/lib/check.sh"
#
#   start "Nom du TP" N "$@"       bandeau, options : ./check, ./check 2 (une mission), ./check --reset
#                                  (CHECK_WORD=preuve avant le chargement : « Preuve 1 », « 4 preuves »)
#   mission K "Titre"              debut de la mission K. Faux si elle est a sauter (une autre mission est
#                                  demandee, ou elle est deja validee) :  if mission 1 "Le cable"; then … fi
#   lab <lab> <machine>            controle « le lab tourne » (✓/✗) ; faux s'il est arrete :
#                                  if mission 1 "…" && lab lab0-cable pc1; then …
#   check "libelle" commande…      lance la commande : ✓ si elle reussit, ✗ sinon
#   hint "conseil"                 conseil affiche sous le dernier ✗
#   ask id "question" <sha256>     pose la question : ✓ si la reponse normalisee a cette empreinte
#   ask_is id "question" valeur    idem, comparee a une valeur lue dans le lab (une MAC…)
#                                  Une bonne reponse est retenue : elle n'est plus reposee.
#   ex <lab> <machine> "commande"  sortie de la commande dans la machine (vide si le lab est arrete)
#   addr <lab> <machine> [dev]     adresses IPv4 de l'interface (192.168.10.1/24, une par ligne)
#   has_addr <lab> <machine> a/m   vrai si l'interface eth0 a exactement cette adresse, et elle seule
#   reach <lab> <machine> ip…      vrai si le ping de la machine vers chaque ip passe
#   startup <lab> <machine> regex  vrai si le .startup contient une ligne (hors commentaires) qui correspond
#   not commande…                  inverse le resultat :  check "pc1 ne joint pas pc3" not reach lab1 pc1 …
#   clean                          vrai si aucun controle de la mission n'a echoue jusqu'ici
#   finish "message final"         bilan ; exit 0 si toutes les missions sont validees, exit 1 sinon
#
# Les labs se font l'un apres l'autre (kathara lclean entre deux) : une mission validee est retenue dans
# .check-state, avec sa date, et n'est plus recontrolee (./check K la recontrole, ./check --reset oublie tout).

D="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STATE="$D/.check-state"
if [ -t 1 ]; then
  _G=$'\e[32m'; _R=$'\e[31m'; _Y=$'\e[33m'; _B=$'\e[1m'; _D=$'\e[2m'; _N=$'\e[0m'
else
  _G=; _R=; _Y=; _B=; _D=; _N=
fi
_word="${CHECK_WORD:-mission}"; _only=""; _nmis=0; _cur=""; _fail=0; _last=0; _score=0; _total=0

start() {
  _nmis="$2"
  case "${3:-}" in
    "") ;;
    --reset|--raz) rm -f "$STATE"; echo "${_word^}s remises à zéro."; exit 0 ;;
    *) if [[ "$3" =~ ^[0-9]+$ ]] && [ "$3" -ge 1 ] && [ "$3" -le "$_nmis" ]; then _only="$3"
       else echo "Usage : ./check [1-$_nmis] | ./check --reset"; exit 2; fi ;;
  esac
  command -v kathara >/dev/null || { echo "${_Y}kathara introuvable : lancez ./check sur la VM Debian13-Kathara.${_N}"; exit 2; }
  touch "$STATE" 2>/dev/null || { echo "${_Y}Impossible d'écrire $STATE : lancez ./check dans le dossier du TP, avec votre compte.${_N}"; exit 2; }
  echo; echo "${_B}[ $1 ]${_N}"
}

_validated() { grep -m1 "^m$1 " "$STATE" 2>/dev/null | cut -d' ' -f2-; }
_close() {
  [ -n "$_cur" ] || return 0
  if [ "$_fail" -eq 0 ]; then
    sed -i "/^m$_cur /d" "$STATE"; echo "m$_cur $(date '+%d/%m à %H:%M')" >> "$STATE"
    echo "  ${_G}→ $_word $_cur validée${_N}"
  elif [ -n "$(_validated "$_cur")" ]; then
    echo "  ${_D}($_word $_cur déjà validée le $(_validated "$_cur") : elle le reste)${_N}"
  fi
  _cur=""
}

mission() {
  _close
  echo; echo "${_B}${_word^} $1 : $2${_N}"
  if [ -n "$_only" ] && [ "$_only" != "$1" ]; then echo "  ${_D}(passée : ./check $_only ne contrôle que la $_word $_only)${_N}"; return 1; fi
  local v; v="$(_validated "$1")"
  if [ -n "$v" ] && [ -z "$_only" ]; then echo "  ${_G}✓${_N} validée le $v ${_D}(./check $1 pour la recontrôler)${_N}"; return 1; fi
  _cur="$1"; _fail=0; return 0
}

_mark() {
  _total=$((_total + 1))
  if [ "$1" -eq 0 ]; then echo "  ${_G}✓${_N} $2"; _score=$((_score + 1)); _last=0
  else echo "  ${_R}✗${_N} $2"; _last=1; _fail=1; fi
}

check() { local label="$1"; shift; "$@" >/dev/null 2>&1; _mark $? "$label"; }
clean() { [ "$_fail" -eq 0 ]; }
hint() { [ "$_last" -eq 1 ] && echo "    ${_D}→ $1${_N}"; return 0; }

ex() { kathara exec -d "$D/$1" "$2" "$3" 2>/dev/null | tr -d '\r'; }
running() { [ "$(ex "$1" "$2" "echo ok")" = ok ]; }
lab() {
  check "le lab $1 tourne" running "$1" "$2"
  hint "cd $1 puis kathara lstart --noterminals ; lancez ./check depuis le dossier du TP"
  [ "$_last" -eq 0 ]
}
addr() { ex "$1" "$2" "ip -4 -o address show dev ${3:-eth0}" | grep -oE 'inet [0-9.]+/[0-9]+' | cut -d' ' -f2; }
has_addr() { [ "$(addr "$1" "$2" "${4:-eth0}")" = "$3" ]; }
reach() {
  local l="$1" m="$2" ip; shift 2
  for ip in "$@"; do ex "$l" "$m" "ping -c 2 -W 1 $ip" | grep -q " 0% packet loss" || return 1; done
}
not() { ! "$@"; }
startup() { grep -v '^[[:space:]]*#' "$D/$1/$2.startup" 2>/dev/null | grep -qE "$3"; }

# reponse normalisee : minuscules, sans article en tete, sans espaces, sans 0x, MAC avec des « : »
_norm() {
  local v
  v="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E "s/^[[:space:]]*(un|une|le|la|les) +//; s/^[[:space:]]*l'//" | tr -d '[:space:]')"
  v="${v#0x}"
  [[ "$v" =~ ^([0-9a-f]{2}-){5}[0-9a-f]{2}$ ]] && v="${v//-/:}"
  printf '%s' "$v"
}
_ask() {
  local id="$1" q="$2" kind="$3" want="$4" r v
  if grep -qx "q:$id" "$STATE" 2>/dev/null; then _mark 0 "$q : réponse juste (déjà donnée)"; return; fi
  if [ ! -t 0 ]; then _mark 1 "$q"; hint "lancez ./check dans un terminal pour répondre"; return; fi
  read -r -p "  ? $q (Entrée si pas encore trouvé) : " r
  v="$(_norm "$r")"
  if [ -z "$v" ]; then _mark 1 "$q : pas encore de réponse"; return; fi
  if { [ "$kind" = hash ] && [ "$(printf '%s' "$v" | sha256sum | cut -d' ' -f1)" = "$want" ]; } ||
     { [ "$kind" = value ] && [ -n "$want" ] && [ "$v" = "$(_norm "$want")" ]; }; then
    echo "q:$id" >> "$STATE"; _mark 0 "$q : réponse juste"
  else
    _mark 1 "$q : « $r » n'est pas la bonne réponse"
  fi
}
ask() { _ask "$1" "$2" hash "$3"; }
ask_is() { _ask "$1" "$2" value "$3"; }

finish() {
  _close
  local n=0 k
  for k in $(seq 1 "$_nmis"); do [ -n "$(_validated "$k")" ] && n=$((n + 1)); done
  echo
  [ "$_total" -gt 0 ] && echo "  Contrôles de ce passage : $_score/$_total"
  echo "  ${_B}Bilan $n/$_nmis ${_word}s${_N}"
  if [ "$n" -eq "$_nmis" ]; then echo; echo "${_G}$1${_N}"; exit 0; fi
  echo "  Corrigez les ✗ (conseil sous chacun), puis relancez ./check."
  exit 1
}
