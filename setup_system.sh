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
apt-get install -y \
    build-essential \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    btop \
    tree \
    unzip \
    zip \
    p7zip-full \
    net-tools \
    dnsutils \
    whois \
    traceroute \
    nmap \
    tcpdump \
    openssl \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release \
    jq \
    tmux \
    screen \
    neofetch \
    locate \
    bash-completion \
    man-db \
    tldr \
    bat \
    fd-find \
    ripgrep \
    fzf \
    2>/dev/null || warn "بعض الأدوات قد لا تكون متاحة"

log "تم تثبيت الأدوات الأساسية"

# ─── 3. Python ────────────────────────────────────
info "تثبيت أدوات Python..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    ipython3

# تثبيت حزم Python المفيدة
pip3 install --break-system-packages \
    requests \
    httpx \
    rich \
    typer \
    black \
    flake8 \
    ipython \
    jupyter \
    pandas \
    numpy \
    2>/dev/null || warn "بعض حزم Python قد لا تكون مثبتة"

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
    apt-get install -y docker.io docker-compose
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
if [ ! -f "$ACTUAL_HOME/.gitconfig" ]; then
    sudo -u "$ACTUAL_USER" git config --global core.editor "vim"
    sudo -u "$ACTUAL_USER" git config --global color.ui true
    sudo -u "$ACTUAL_USER" git config --global pull.rebase false
    sudo -u "$ACTUAL_USER" git config --global init.defaultBranch main
    sudo -u "$ACTUAL_USER" git config --global core.autocrlf input
    log "تم إعداد Git الأساسي"
fi

# ─── 7. Zsh + Oh My Zsh ──────────────────────────
info "تثبيت Zsh..."
apt-get install -y zsh
if [ ! -d "$ACTUAL_HOME/.oh-my-zsh" ]; then
    sudo -u "$ACTUAL_USER" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null
    log "تم تثبيت Oh My Zsh"
    # تغيير الثيم
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
else
    log "Oh My Zsh مثبت مسبقاً"
fi

# إضافة plugins مفيدة
if [ -f "$ACTUAL_HOME/.zshrc" ]; then
    if ! grep -q "zsh-autosuggestions" "$ACTUAL_HOME/.zshrc"; then
        # تثبيت zsh-autosuggestions
        ZSH_CUSTOM="$ACTUAL_HOME/.oh-my-zsh/custom"
        sudo -u "$ACTUAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions \
            "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" 2>/dev/null || true
        sudo -u "$ACTUAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history sudo)/' \
            "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
        log "تم تثبيت Zsh plugins"
    fi
fi

# ─── 8. Aliases مفيدة ─────────────────────────────
info "إضافة aliases مفيدة..."
ALIASES_FILE="$ACTUAL_HOME/.bash_aliases"
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

# Useful
alias h='history | grep'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias diskusage='du -sh * | sort -rh | head -20'
alias meminfo='free -h'
alias cpuinfo='lscpu | head -20'
ALIASES

chown "$ACTUAL_USER:$ACTUAL_GROUP" "$ALIASES_FILE"

# تأكد من تحميل aliases في bashrc
if [ -f "$ACTUAL_HOME/.bashrc" ] && ! grep -q ".bash_aliases" "$ACTUAL_HOME/.bashrc"; then
    echo -e '\n# Load custom aliases\n[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$ACTUAL_HOME/.bashrc"
fi

# إضافة لـ zshrc أيضاً
if [ -f "$ACTUAL_HOME/.zshrc" ] && ! grep -q ".bash_aliases" "$ACTUAL_HOME/.zshrc"; then
    echo -e '\n# Load custom aliases\n[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$ACTUAL_HOME/.zshrc"
fi

log "تم إضافة aliases"

# ─── 9. تحسين الأداء ─────────────────────────────
info "تحسين إعدادات النظام..."

# زيادة حد الـ file descriptors
if ! grep -q "^\* soft nofile" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'LIMITS'
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
LIMITS
fi

# تحسين sysctl للشبكة
cat > /etc/sysctl.d/99-custom.conf << 'SYSCTL'
# تحسين الشبكة
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
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
updatedb 2>/dev/null || true

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
node --version &>/dev/null && echo "  ✓ Node.js $(node --version) + npm $(npm --version)" || echo "  ! Node.js لم يتم تثبيته (تحقق من الإنترنت)"
docker --version &>/dev/null && echo "  ✓ Docker $(docker --version | awk '{print $3}' | tr -d ',')" || true
echo "  ✓ Zsh + Oh My Zsh + plugins"
echo "  ✓ Aliases مفيدة في ~/.bash_aliases"
echo "  ✓ تحسين أداء النظام (sysctl, limits)"
echo ""
echo "ملاحظات مهمة:"
echo "  → أعد تشغيل الجلسة لتطبيق جميع التغييرات"
echo "  → لتفعيل Zsh: chsh -s \$(which zsh)"
echo "  → لاستخدام Docker بدون sudo: أعد تسجيل الدخول"
echo ""
