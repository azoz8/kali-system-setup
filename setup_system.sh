#!/bin/bash
# System Setup Script for Kali Linux
# Run with: sudo bash setup_system.sh

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} ${1:-}"; }
info() { echo -e "${BLUE}[→]${NC} ${1:-}"; }
warn() { echo -e "${YELLOW}[!]${NC} ${1:-}"; }
error() { echo -e "${RED}[✗]${NC} ${1:-}"; }

if [ "$EUID" -ne 0 ]; then
    error "يرجى تشغيل السكريبت بصلاحيات root: sudo bash setup_system.sh"
    exit 1
fi

# تشغيل غير تفاعلي: بدونه يتوقف السكريبت على حوارات conffile أو needrestart
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# سجل التنفيذ — نفضّل /var/log ونسقط إلى /tmp إن تعذّرت الكتابة
LOG_FILE="/var/log/kali-setup-$(date +%F-%H%M%S).log"
if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="/tmp/kali-setup-$(date +%F-%H%M%S).log"
    touch "$LOG_FILE"
fi
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'error "فشل التنفيذ عند السطر $LINENO — راجع السجل: $LOG_FILE"' ERR

# كشف بيئة الحاوية: systemctl و sysctl لا يعملان داخلها، نتخطاهما بدل الفشل
IN_CONTAINER=0
if [ -f /run/.containerenv ] || [ -f /.dockerenv ] ||
   { command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -c &>/dev/null; }; then
    IN_CONTAINER=1
    info "تم كشف بيئة حاوية — سيتم تخطّي عمليات systemd و sysctl"
fi

ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || whoami)}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

if [ "$ACTUAL_USER" = "root" ]; then
    warn "شُغّل السكريبت كـ root مباشرة — إعدادات المستخدم ستُطبّق على /root"
fi

# getent قد يرجع قيمة فارغة؛ بدون هذا الفحص تتحوّل المسارات إلى /.zshrc وما شابه
if [ -z "$ACTUAL_HOME" ] || [ ! -d "$ACTUAL_HOME" ]; then
    error "تعذّر تحديد مجلد المنزل للمستخدم $ACTUAL_USER"
    exit 1
fi
ACTUAL_GROUP=$(id -gn "$ACTUAL_USER")

# apt-get install بقائمة طويلة يفشل بالكامل لو حزمة واحدة مفقودة، فلا يُثبَّت شيء.
# نفحص التوفر أولاً، نثبّت المتاح دفعة واحدة، ونسمّي المفقود صراحة.
install_available() {
    local available=() missing=() pkg
    for pkg in "$@"; do
        if apt-cache show "$pkg" &>/dev/null; then
            available+=("$pkg")
        else
            missing+=("$pkg")
        fi
    done
    # ملاحظة: (( 0 )) ترجع حالة 1 وتُسقط السكريبت تحت set -e، لذا if لا &&
    if ((${#available[@]})); then
        apt-get install -y "${available[@]}"
    fi
    if ((${#missing[@]})); then
        warn "حزم غير متاحة في المستودع: ${missing[*]}"
    fi
}

echo ""
echo "=================================================="
echo "   إعداد نظام Kali Linux - بدء التثبيت"
echo "=================================================="
echo ""

# ─── 1. تحديث النظام ───────────────────────────────
info "تحديث قوائم الحزم..."
apt-get update -y
log "تم تحديث قوائم الحزم"

info "ترقية الحزم المثبتة..."
# full-upgrade ضروري على توزيعة rolling: upgrade يترك حزماً معلّقة (held back)
apt-get -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" full-upgrade -y
log "تم ترقية الحزم"

# ─── 2. الأدوات الأساسية ──────────────────────────
info "تثبيت الأدوات الأساسية..."
# fastfetch بدل neofetch (المشروع مؤرشف وأُزيل من مستودعات Debian/Kali)
# plocate بدل locate، و sudo لأن السكريبت يعتمد عليه في إعدادات المستخدم
CORE_PKGS=(build-essential curl wget git vim nano htop btop tree unzip zip
           p7zip-full net-tools dnsutils whois traceroute nmap tcpdump openssl
           ca-certificates apt-transport-https gnupg lsb-release jq tmux screen
           fastfetch plocate bash-completion man-db tldr bat fd-find ripgrep fzf
           sudo)
install_available "${CORE_PKGS[@]}"

log "تم تثبيت الأدوات الأساسية"

# ─── 3. Python ────────────────────────────────────
info "تثبيت أدوات Python..."
PYTHON_PKGS=(python3 python3-pip python3-venv python3-dev python3-setuptools
             python3-wheel ipython3)
install_available "${PYTHON_PKGS[@]}"

# المكتبات من apt احتراماً لـ PEP 668: الكتابة فوق حزم مُدارة بـ apt
# تكسر أدوات Kali المبنية على Python
PYTHON_LIBS=(python3-requests python3-httpx python3-rich python3-typer
             python3-pandas python3-numpy)
install_available "${PYTHON_LIBS[@]}"

# التطبيقات المستقلة عبر pipx، كل واحد في حلقة مستقلة حتى لا يوقف فشلُ واحدٍ الباقي
install_available pipx
if command -v pipx &>/dev/null; then
    sudo -u "$ACTUAL_USER" -H pipx ensurepath >/dev/null || warn "تعذّر ضبط PATH لـ pipx"
    for app in black flake8 jupyterlab httpie; do
        sudo -u "$ACTUAL_USER" -H pipx install "$app" || warn "تعذّر تثبيت $app عبر pipx"
    done
else
    warn "pipx غير متاح — تخطّي تثبيت أدوات Python المستقلة"
fi

log "تم تثبيت Python وأدواته"

# ─── 4. Node.js ───────────────────────────────────
info "تثبيت Node.js..."
if ! command -v node &>/dev/null; then
    if curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; then
        apt-get install -y nodejs
        log "تم تثبيت Node.js $(node --version) و npm $(npm --version)"
    else
        warn "تعذّر إعداد مستودع NodeSource — تخطّي Node.js"
    fi
else
    log "Node.js مثبت مسبقاً: $(node --version)"
fi

# ─── 5. Docker ────────────────────────────────────
info "تثبيت Docker..."
if ! command -v docker &>/dev/null; then
    install_available docker.io docker-compose
    if [ "$IN_CONTAINER" -eq 1 ]; then
        info "داخل حاوية — تخطّي تفعيل خدمة docker"
    else
        systemctl enable docker
        systemctl start docker
    fi
    log "تم تثبيت Docker"
else
    log "Docker مثبت مسبقاً"
fi
usermod -aG docker "$ACTUAL_USER" || warn "تعذّر إضافة $ACTUAL_USER إلى مجموعة docker"

# ─── 6. Git Configuration ─────────────────────────
info "إعداد Git..."
# لكل مفتاح على حدة: الشرط القديم (غياب .gitconfig كلياً) كان يحرم أي مستخدم
# لديه ملف مسبق من كل الإعدادات. ولا ندهس قيمة ضبطها المستخدم بنفسه.
git_set_if_unset() {
    sudo -u "$ACTUAL_USER" -H git config --global --get "$1" &>/dev/null ||
        sudo -u "$ACTUAL_USER" -H git config --global "$1" "$2"
}

git_set_if_unset core.editor "vim"
git_set_if_unset color.ui true
git_set_if_unset pull.rebase false
git_set_if_unset init.defaultBranch main
git_set_if_unset core.autocrlf input
log "تم إعداد Git الأساسي"

# ─── 7. Zsh + Oh My Zsh ──────────────────────────
info "تثبيت Zsh..."
install_available zsh
if [ ! -d "$ACTUAL_HOME/.oh-my-zsh" ]; then
    # -H إلزامي: بدونه يبقى HOME=/root فيُركَّب Oh My Zsh في مجلد root
    sudo -u "$ACTUAL_USER" -H env RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended ||
        warn "تعذّر تشغيل مثبّت Oh My Zsh"
else
    log "Oh My Zsh مثبت مسبقاً"
fi

# نتحقق من نتيجة التثبيت فعلياً قبل أي تعديل على .zshrc بدل ابتلاع الفشل
if [ -d "$ACTUAL_HOME/.oh-my-zsh" ] && [ -f "$ACTUAL_HOME/.zshrc" ]; then
    # تغيير الثيم
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$ACTUAL_HOME/.zshrc"
    log "تم إعداد Oh My Zsh والثيم"
else
    error "Oh My Zsh غير موجود في $ACTUAL_HOME — تخطّي تخصيص .zshrc"
fi

# إضافة plugins مفيدة
if [ -f "$ACTUAL_HOME/.zshrc" ]; then
    if ! grep -q "zsh-autosuggestions" "$ACTUAL_HOME/.zshrc"; then
        # تثبيت zsh-autosuggestions
        ZSH_CUSTOM="$ACTUAL_HOME/.oh-my-zsh/custom"
        sudo -u "$ACTUAL_USER" -H git clone https://github.com/zsh-users/zsh-autosuggestions \
            "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || warn "تعذّر استنساخ zsh-autosuggestions"
        sudo -u "$ACTUAL_USER" -H git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" || warn "تعذّر استنساخ zsh-syntax-highlighting"
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history sudo)/' \
            "$ACTUAL_HOME/.zshrc"
        log "تم تثبيت Zsh plugins"
    fi
fi

# ─── 8. Aliases مفيدة ─────────────────────────────
info "إضافة aliases مفيدة..."
# ملف مملوك للسكريبت: آمن للكتابة فوقه في كل تشغيل، بخلاف ~/.bash_aliases
# الذي قد يحتوي إضافات المستخدم
ALIASES_DIR="$ACTUAL_HOME/.config/shell"
ALIASES_FILE="$ALIASES_DIR/aliases.sh"
mkdir -p "$ALIASES_DIR"
cat > "$ALIASES_FILE" << 'ALIASES'
# System
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias search='apt search'
alias clean='sudo apt autoremove -y && sudo apt autoclean'

# Navigation
alias ll='ls -alh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Network
alias myip='curl -s ifconfig.me && echo'
alias localip='hostname -I | awk "{print \$1}"'
alias ports='ss -tulanp'
alias listening='ss -tlnp'

# Processes
alias psa='ps aux'
alias psg='ps aux | grep'
alias topmem='ps aux --sort=-%mem | head -10'
alias topcpu='ps aux --sort=-%cpu | head -10'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'

# Docker
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'

# Modern replacements — أسماء الثنائيات في Debian/Kali تختلف عن اسم الأمر الأصلي
alias bat='batcat'
alias fd='fdfind'

# Useful
alias h='history | grep'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias diskusage='du -sh * | sort -rh | head -20'
alias meminfo='free -h'
alias cpuinfo='lscpu | head -20'
ALIASES

chown "$ACTUAL_USER:$ACTUAL_GROUP" "$ACTUAL_HOME/.config" "$ALIASES_DIR" "$ALIASES_FILE"

# تحميل الملف من bashrc و zshrc
ALIASES_SOURCE_LINE='[ -f ~/.config/shell/aliases.sh ] && . ~/.config/shell/aliases.sh'
for rc in "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF '.config/shell/aliases.sh' "$rc"; then
        printf '\n# Load custom aliases\n%s\n' "$ALIASES_SOURCE_LINE" >> "$rc"
    fi
done

# ملف الإصدارات السابقة يُترك كما هو — قد يحتوي إضافات المستخدم
if [ -f "$ACTUAL_HOME/.bash_aliases" ]; then
    info "الموقع الجديد للـ aliases هو ~/.config/shell/aliases.sh — تُرك ~/.bash_aliases القديم كما هو"
fi

log "تم إضافة aliases"

# ─── 9. تحسين الأداء ─────────────────────────────
info "تحسين إعدادات النظام..."

# زيادة حد الـ file descriptors عبر drop-in بدل append على limits.conf
# (الكتابة فوق ملف مملوك للسكريبت idempotent بطبيعتها)
mkdir -p /etc/security/limits.d
cat > /etc/security/limits.d/99-custom.conf << 'LIMITS'
*    soft nofile 65536
*    hard nofile 65536
*    soft nproc  32768
*    hard nproc  32768

# الرمز * لا يشمل root — لا بد من ذكره صراحة
root soft nofile 65536
root hard nofile 65536
root soft nproc  32768
root hard nproc  32768
LIMITS

# pam_limits لا يُطبَّق على خدمات systemd — تحتاج drop-in خاصاً بها
mkdir -p /etc/systemd/system.conf.d
printf '[Manager]\nDefaultLimitNOFILE=65536\n' > /etc/systemd/system.conf.d/99-limits.conf

# تحسين sysctl للشبكة
cat > /etc/sysctl.d/99-custom.conf << 'SYSCTL'
# تحسين الشبكة
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
# لا تنزل بالحد الأدنى تحت 32768: النواة تحجز المدى كمنافذ ephemeral،
# وأي مدى يبدأ من 1024 يبتلع منافذ خدمات مثل 3306 و 5432 و 8080
# فتظهر أخطاء Address already in use متقطعة مع Docker و PostgreSQL
net.ipv4.ip_local_port_range = 32768 60999
net.ipv4.tcp_fin_timeout = 15

# تحسين الذاكرة
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
SYSCTL

if [ "$IN_CONTAINER" -eq 1 ]; then
    info "داخل حاوية — تخطّي تطبيق sysctl (/proc/sys للقراءة فقط)"
else
    sysctl -p /etc/sysctl.d/99-custom.conf >/dev/null || warn "تعذّر تطبيق بعض قيم sysctl"
fi
log "تم تحسين إعدادات النظام"

# ─── 10. تنظيف ───────────────────────────────────
info "تنظيف الحزم غير الضرورية..."
apt-get autoremove -y
apt-get autoclean -y
log "تم التنظيف"

# ─── تحديث قاعدة بيانات locate ───────────────────
info "تحديث قاعدة بيانات البحث..."
# plocate يوفّر updatedb.plocate؛ نقبل أياً منهما ولا نفشل إن غاب الاثنان
if command -v updatedb.plocate &>/dev/null; then
    updatedb.plocate || true
elif command -v updatedb &>/dev/null; then
    updatedb || true
else
    info "أداة updatedb غير متوفرة — تخطّي"
fi

# ─── ملخص ─────────────────────────────────────────
echo ""
echo "=================================================="
echo -e "   ${GREEN}اكتمل الإعداد بنجاح!${NC}"
echo "=================================================="
echo ""
echo "تم تثبيت وإعداد:"
echo "  ✓ تحديث كامل للنظام"
echo "  ✓ الأدوات الأساسية (curl, wget, git, vim, htop, tmux...)"
echo "  ✓ Python 3 + pip + venv + حزم مفيدة"
if command -v node &>/dev/null; then
    echo "  ✓ Node.js $(node --version) + npm $(npm --version)"
else
    echo "  ! Node.js لم يتم تثبيته (تحقق من الإنترنت)"
fi
if command -v docker &>/dev/null; then
    echo "  ✓ Docker $(docker --version | awk '{print $3}' | tr -d ',')"
fi
echo "  ✓ Zsh + Oh My Zsh + plugins"
echo "  ✓ Aliases مفيدة في ~/.config/shell/aliases.sh"
echo "  ✓ تحسين أداء النظام (sysctl, limits)"
echo ""
echo "ملاحظات مهمة:"
echo "  → أعد تشغيل الجلسة لتطبيق جميع التغييرات"
echo "  → لتفعيل Zsh: chsh -s \$(which zsh)"
echo "  → لاستخدام Docker بدون sudo: أعد تسجيل الدخول"
echo ""
