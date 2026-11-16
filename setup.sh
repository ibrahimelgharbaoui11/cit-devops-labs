#!/usr/bin/env bash
# =====================================================================
#  ClubHub Rescue — Lab 02 · Linux Fundamentals
#  Cellule DevOps · Club Informatique & Télécom
#
#  Usage :
#     bash setup.sh            prépare la mission dans ~/clubhub-rescue
#     bash setup.sh --reset    remet la mission à zéro
#     bash setup.sh --stop     arrête les processus du lab
#
#  Fonctionne sur Ubuntu/Debian (VM, WSL, Killercoda…). Pas besoin de sudo.
#  Prérequis : bash, python3 (curl conseillé).
# =====================================================================
set -u

BASE="${CLUBHUB_RESCUE_DIR:-$HOME/clubhub-rescue}"
PORT=8090

d() { printf '%s' "$1" | base64 -d; }
F1=$(d 'Q0xVQntoaWRkZW5fZmlsZXNfYXJlX25vdF9pbnZpc2libGV9')
F2=$(d 'Q0xVQntsb2dzX3RlbGxfdGhlX3RydXRofQ==')
F3=$(d 'Q0xVQntmaW5kX2l0X2ZpeF9pdH0=')
F4B='Q0xVQntjaG1vZF9wbHVzX3hfZm9yX3RoZV93aW59'
F5B='Q0xVQntraWxsX3RoZV96b21iaWV9'
F6B='Q0xVQntjbHViaHViX2lzX2FsaXZlfQ=='

say()  { printf '\033[1;36m[setup]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[erreur]\033[0m %s\n' "$*"; exit 1; }

stop_all() {
  pkill -f '^clubhub-zombie' 2>/dev/null
  pkill -f '^clubhub-server' 2>/dev/null
  sleep 0.5
}

case "${1:-}" in
  --stop)  stop_all; say "Processus du lab arrêtés."; exit 0 ;;
  --reset) stop_all; rm -rf "$BASE"; say "Ancienne mission supprimée." ;;
  "") ;;
  *) fail "Option inconnue : $1 (utilisez --reset ou --stop)" ;;
esac

# ---------- Vérifications -------------------------------------------
command -v python3 >/dev/null 2>&1 || fail "python3 est requis. Installez-le : sudo apt update && sudo apt install -y python3"
command -v curl >/dev/null 2>&1 || say "Conseil : installez curl (sudo apt install -y curl). Le lab l'utilise dans les missions 5 et 6."
[ -e "$BASE" ] && fail "$BASE existe déjà. Pour recommencer : bash setup.sh --reset"
python3 - "$PORT" <<'PY' || fail "Le port 8090 est déjà utilisé sur cette machine. Libérez-le puis relancez."
import socket, sys
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[1]))); s.close()
PY

say "Construction du serveur ClubHub (en panne)…"
S="$BASE/server"
mkdir -p "$S"/{home/admin/Documents,var/log,opt/clubhub,srv/www,run,tmp/cache/.thumbnails,tmp/sessions}

# ---------- Briefing -------------------------------------------------
cat > "$BASE/README.txt" <<'EOF'
=====================================================================
   ALERTE · ClubHub est en panne !
=====================================================================

Vendredi, 23 h 47. Les inscriptions au hackathon du club ouvrent
demain matin… et le serveur ClubHub ne répond plus.

L'ancien administrateur, Yassine, est parti en vacances sans laisser
de documentation. Il a seulement dit : « J'ai laissé une note dans
mon dossier personnel du serveur. »

Le serveur se trouve dans le dossier : server/
Son dossier personnel : server/home/admin/

VOTRE MISSION
  Remettre ClubHub en ligne sur le port 8090.

RÈGLES DU JEU
  - Chaque mission vous rapporte un FLAG de la forme CLUB{...}.
  - Notez chaque flag dans le fichier flags.txt (un par ligne) :
        echo 'CLUB{...}' >> flags.txt
  - À tout moment, vérifiez votre progression avec :
        ./check.sh
  - Interdit : lire le script setup.sh. Un vrai admin n'a pas de
    corrigé !

Bonne chance. Le club compte sur vous.
EOF

printf '# Mes flags (un par ligne) :\n' > "$BASE/flags.txt"
date +%s > "$BASE/.started"

# ---------- Mission 1 : fichiers cachés ------------------------------
cat > "$S/home/admin/todo.txt" <<'EOF'
TODO avant les vacances :
- [x] migrer ClubHub vers le nouveau serveur
- [ ] corriger la config (j'ai mis un port bizarre…)
- [ ] arrêter l'ancienne version qui tourne encore
- [ ] écrire la doc (…un jour)
EOF
printf 'Liste des participants : voir la base de données.\n' > "$S/home/admin/Documents/hackathon.txt"
: > "$S/home/admin/Documents/photo_hackathon_2025.jpg"
cat > "$S/home/admin/.note_admin.txt" <<EOF
Salut le/la remplaçant(e) !

Bravo, tu as trouvé ma note. Les fichiers qui commencent par un point
sont cachés : seul « ls -a » les montre.

  FLAG : $F1

Je n'ai pas eu le temps de réparer ClubHub. Tout ce qui s'est passé
est écrit dans le journal du serveur :

  server/var/log/clubhub.log

Il est long… Lis surtout LA FIN du fichier. Et j'y ai aussi caché un
flag : cherche le mot FLAG dedans.

— Yassine
EOF

# ---------- Mission 2 : les logs -------------------------------------
awk -v flag="$F2" 'BEGIN{
  split("GET /events 200|GET /events/42 200|POST /login 200|GET /members 200|POST /events/12/register 201|GET /api/health 200|GET /favicon.ico 404|POST /login 401|GET /admin 403|db: query events took 12ms|db: query members took 48ms|cache: hit ratio 0.87|scheduler: reminder emails queued|auth: session renewed", m, "|");
  n=14; h=18; mi=0; s=3;
  for(i=1;i<=2400;i++){
    s+=7; if(s>=60){s-=60; mi++} if(mi>=60){mi-=60; h++}
    lvl="INFO "; if(i%13==0) lvl="DEBUG"; if(i%29==0) lvl="WARN ";
    msg=m[(i*7)%n+1];
    if(i%97==0){ lvl="ERROR"; msg="db: connection timeout (retrying)" }
    if(i==1337){ lvl="DEBUG"; msg="backup: admin secret note -> FLAG=" flag }
    printf "2026-11-14 %02d:%02d:%02d %s %s\n", h, mi, s, lvl, msg
  }
}' > "$S/var/log/clubhub.log"
cat >> "$S/var/log/clubhub.log" <<'EOF'
2026-11-14 23:41:02 INFO  deploy: migration to new server finished
2026-11-14 23:41:05 WARN  config: loading clubhub.conf (chemin perdu pendant la migration : utilisez find)
2026-11-14 23:41:06 INFO  config: PORT=80
2026-11-14 23:41:06 ERROR server: cannot bind 0.0.0.0:80 -> Permission denied
2026-11-14 23:41:06 ERROR server: ports below 1024 require root privileges. Official ClubHub port is 8090
2026-11-14 23:41:07 WARN  process: old instance 'clubhub-zombie' did not stop correctly
2026-11-14 23:41:07 WARN  deploy: start.sh is not executable (check permissions)
2026-11-14 23:41:08 FATAL server: ClubHub is DOWN
EOF
printf '2026-11-14 08:00:01 sshd: Accepted publickey for admin\n2026-11-14 23:50:12 sshd: session closed for admin\n' > "$S/var/log/auth.log"
printf 'kernel: boot ok\nsystemd: reached target multi-user\n' > "$S/var/log/system.log"

# ---------- Mission 3 : find + édition ---------------------------------
for a in apps services legacy; do
  for y in 2023 2024 2025; do
    for c in config backup old; do mkdir -p "$S/etc/$a/$y/$c"; done
    printf 'name=%s\nenabled=false\n' "$a-$y" > "$S/etc/$a/$y/config/app.conf"
  done
done
mkdir -p "$S/etc/apps/2025/clubhub/config" "$S/etc/legacy/2023/clubhub"
printf '# ANCIEN fichier de 2023, ne pas utiliser\nPORT=7000\n' > "$S/etc/legacy/2023/clubhub/clubhub.conf.old"
cat > "$S/etc/apps/2025/clubhub/config/clubhub.conf" <<EOF
# =========================================
#  ClubHub — configuration du serveur
# =========================================
# Bien joué, tu as trouvé le bon fichier !
# FLAG : $F3
#
# AVANT de modifier : fais une copie de sauvegarde
#   (même nom + .bak, dans le même dossier).
#
# Le port officiel de ClubHub est 8090.
# Les ports < 1024 sont réservés à l'administrateur (root).

APP_NAME=ClubHub
ENV=production
PORT=80
DB_FILE=/srv/clubhub/clubhub.db
EOF

# ---------- Mission 4 & 6 : le script de démarrage -------------------
cat > "$S/opt/clubhub/server.py" <<'PY'
import base64, http.server, socketserver, sys
PORT = int(sys.argv[1])
FLAG = base64.b64decode(sys.argv[2]).decode()
PAGE = f"""
   ____ _       _     _   _       _
  / ___| |_   _| |__ | | | |_   _| |__
 | |   | | | | | '_ \\| |_| | | | | '_ \\
 | |___| | |_| | |_) |  _  | |_| | |_) |
  \\____|_|\\__,_|_.__/|_| |_|\\__,_|_.__/

  ClubHub est EN LIGNE sur le port {PORT}.

  Prochains événements :
   - Hackathon du club ........ samedi 9 h
   - Atelier Docker ........... mardi 18 h
   - Soirée jeux & pizza ...... jeudi 19 h

  FLAG : {FLAG}

  Dernière étape : lancez ./check.sh dans ~/clubhub-rescue
"""
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = PAGE.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
try:
    srv = socketserver.TCPServer(("0.0.0.0", PORT), H)
except OSError as e:
    print(f"OSError: [Errno {e.errno}] Address already in use" if e.errno == 98 else e, flush=True)
    sys.exit(1)
print(f"listening on {PORT}", flush=True)
srv.serve_forever()
PY

cat > "$S/opt/clubhub/start.sh" <<EOF
#!/usr/bin/env bash
# Script de démarrage de ClubHub
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
ROOT="\$(cd "\$DIR/../.." && pwd)"
CONF="\$ROOT/etc/apps/2025/clubhub/config/clubhub.conf"
LOG="\$ROOT/var/log/clubhub.log"
OUT="\$ROOT/var/log/server.out"
PIDFILE="\$ROOT/run/clubhub.pid"
now() { date '+%Y-%m-%d %H:%M:%S'; }

echo "== ClubHub · démarrage =="
echo "Le script s'exécute enfin. FLAG : \$(printf %s '$F4B' | base64 -d)"

if [ ! -f "\$CONF" ]; then
  echo "ERREUR : configuration introuvable (\$CONF)"; exit 1
fi
PORT=\$(grep -E '^[[:space:]]*PORT=' "\$CONF" | tail -n 1 | cut -d= -f2 | tr -d ' "\r')
case "\$PORT" in ''|*[!0-9]*) echo "ERREUR : PORT invalide dans clubhub.conf (« \$PORT »)"; exit 1;; esac

if [ "\$PORT" -lt 1024 ]; then
  echo "\$(now) ERROR server: cannot bind 0.0.0.0:\$PORT -> Permission denied" >> "\$LOG"
  echo "ERREUR : Permission denied sur le port \$PORT."
  echo "         Les ports < 1024 sont réservés à root. Corrigez PORT dans clubhub.conf."
  exit 1
fi
if [ "\$PORT" != "$PORT" ]; then
  echo "ERREUR : le reverse proxy du club attend ClubHub sur le port $PORT (actuel : \$PORT)."
  exit 1
fi
if [ -f "\$PIDFILE" ] && kill -0 "\$(cat "\$PIDFILE")" 2>/dev/null; then
  echo "ClubHub tourne déjà (PID \$(cat "\$PIDFILE")) sur http://localhost:\$PORT"; exit 0
fi

nohup bash -c 'exec -a clubhub-server python3 "\$0" "\$1" "\$2"' "\$DIR/server.py" "\$PORT" '$F6B' > "\$OUT" 2>&1 &
PID=\$!
sleep 1.5
if kill -0 "\$PID" 2>/dev/null; then
  echo "\$PID" > "\$PIDFILE"
  echo "\$(now) INFO  server: ClubHub started on port \$PORT (PID \$PID)" >> "\$LOG"
  echo "OK : ClubHub tourne (PID \$PID)."
  echo "     Testez-le : curl http://localhost:\$PORT"
else
  echo "\$(now) ERROR server: cannot bind 0.0.0.0:\$PORT -> Address already in use" >> "\$LOG"
  echo "ERREUR : Address already in use."
  echo "         Le port \$PORT est déjà occupé par un autre programme."
  echo "         Qui répond sur ce port ? Quel processus est-ce ?"
  exit 1
fi
EOF
chmod 644 "$S/opt/clubhub/start.sh"     # volontairement NON exécutable

# ---------- Mission 5 : le zombie ------------------------------------
cat > "$S/run/zombie.py" <<PY
import base64, http.server, socketserver
FLAG = base64.b64decode("$F5B").decode()
PAGE = f"""
  Grrr... Je suis le ZOMBIE de l'ancienne version de ClubHub.
  Personne ne m'a arrete pendant la migration, alors je squatte
  le port $PORT pour toujours !

  ... sauf si tu trouves mon PID et que tu m'arretes (kill).
  Indice : je m'appelle clubhub-zombie.

  FLAG : {FLAG}
"""
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = PAGE.encode()
        self.send_response(503)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
socketserver.TCPServer(("0.0.0.0", $PORT), H).serve_forever()
PY
nohup bash -c 'exec -a clubhub-zombie python3 "$0"' "$S/run/zombie.py" >/dev/null 2>&1 &
disown 2>/dev/null

# ---------- Bonus : le fichier géant ---------------------------------
head -c 20000000 /dev/zero > "$S/tmp/cache/.thumbnails/core.dump" 2>/dev/null
for i in 1 2 3 4 5; do printf 'session %s\n' "$i" > "$S/tmp/sessions/sess_$i"; done

# ---------- Vérificateur ---------------------------------------------
cat > "$BASE/check.sh" <<'EOF'
#!/usr/bin/env bash
# Vérifie votre progression. Lancez : ./check.sh
B="$(cd "$(dirname "$0")" && pwd)"
S="$B/server"
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; N='\033[0m'
ok=0; total=0
line() { total=$((total+1)); if [ "$1" = 1 ]; then ok=$((ok+1)); printf "  ${G}[OK]${N} %s\n" "$2"; else printf "  ${R}[--]${N} %s\n" "$2"; fi; }
has_flag() { for l in $(grep -o 'CLUB{[^}]*}' "$B/flags.txt" 2>/dev/null); do
  [ "$(printf %s "$l" | sha256sum | cut -c1-64)" = "$1" ] && return 0; done; return 1; }
up() { if command -v curl >/dev/null 2>&1; then curl -s --max-time 2 "http://localhost:8090" | grep -q "EN LIGNE"
       else python3 -c "import urllib.request;print(urllib.request.urlopen('http://localhost:8090',timeout=2).read().decode())" 2>/dev/null | grep -q "EN LIGNE"; fi; }
zombie() { ps -eo args 2>/dev/null | grep -v grep | grep -q '^clubhub-zombie'; }
v() { if eval "$1" >/dev/null 2>&1; then echo 1; else echo 0; fi; }

H=(f3dabb4b427a242bb0d244cd8ec8b2823c6323eabcea43134c37ae2c24b9b968 9e52d2e8b8df485cb872262248b5230e37860de17a531beca7cc6f077a2b5d1a 9021400523df66e35f05c2bd53425cc4e4e284c373ec003198bd418f006f0a20 046cdf898c3ad29eac5871c617797e3245d229bb16a6906a77ec4804953ffe53 08fcc5f0ef1e486767f6d438ac731f01c7c5ca7f2a45aa3e1638d1dcf2cb12b2 a1e3a685d4b5cb641c85ea963acd11aba764cb0cfced1d9d2787d3f620cbbe3d)
CONF="$S/etc/apps/2025/clubhub/config/clubhub.conf"

echo; echo "=========== ClubHub Rescue · progression ==========="
echo "Mission 1 · Le dossier de l'admin";   line "$(v 'has_flag ${H[0]}')" "Flag 1 trouvé"
echo "Mission 2 · Les logs";                line "$(v 'has_flag ${H[1]}')" "Flag 2 trouvé"
echo "Mission 3 · La configuration";        line "$(v 'has_flag ${H[2]}')" "Flag 3 trouvé"
                                            line "$(v '[ -f "$CONF.bak" ]')" "Sauvegarde clubhub.conf.bak créée"
                                            line "$(v 'grep -Eq "^[[:space:]]*PORT=8090[[:space:]]*$" "$CONF"')" "PORT corrigé à 8090"
echo "Mission 4 · Les permissions";         line "$(v 'has_flag ${H[3]}')" "Flag 4 trouvé"
                                            line "$(v '[ -x "$S/opt/clubhub/start.sh" ]')" "start.sh est exécutable"
echo "Mission 5 · Le processus zombie";     line "$(v 'has_flag ${H[4]}')" "Flag 5 trouvé"
                                            line "$(v '! zombie')" "clubhub-zombie est arrêté"
echo "Mission 6 · ClubHub en ligne";        line "$(v 'has_flag ${H[5]}')" "Flag 6 trouvé"
                                            line "$(v up)" "ClubHub répond sur http://localhost:8090"
echo
echo "Bonus";
b=0
if [ ! -e "$S/tmp/cache/.thumbnails/core.dump" ]; then b=$((b+1)); printf "  ${Y}[★]${N} Fichier géant supprimé\n"; else printf "  [ ] Bonus A : libérer l'espace disque\n"; fi
if [ -x "$B/status.sh" ] && "$B/status.sh" >/dev/null 2>&1; then b=$((b+1)); printf "  ${Y}[★]${N} Script status.sh fonctionnel\n"; else printf "  [ ] Bonus B : écrire status.sh\n"; fi
if [ -f "$B/whoami.txt" ] && [ -s "$B/whoami.txt" ]; then b=$((b+1)); printf "  ${Y}[★]${N} Carte d'identité du serveur (whoami.txt)\n"; else printf "  [ ] Bonus C : créer whoami.txt\n"; fi
echo
printf "Score : %s/%s" "$ok" "$total"; [ "$b" -gt 0 ] && printf "  + %s bonus" "$b"; echo
if [ "$ok" = "$total" ]; then
  s=$(cat "$B/.started" 2>/dev/null || date +%s); m=$(( ($(date +%s) - s) / 60 ))
  printf "${G}"
  echo "  ######################################################"
  echo "  #   SERVEUR SAUVÉ ! ClubHub est en ligne.            #"
  echo "  #   Le hackathon peut commencer. Merci, admin !      #"
  echo "  ######################################################"
  printf "${N}"; echo "  Temps de mission : ${m} min"
fi
echo
EOF
chmod +x "$BASE/check.sh"

sleep 1
say "Mission prête dans : $BASE"
echo
echo "   cd $BASE"
echo "   cat README.txt"
echo
