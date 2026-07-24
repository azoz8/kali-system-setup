<div align="center">

# 🛠️ Kali Linux System Setup

**سكريبت إعداد شامل لنظام Kali Linux — بضغطة واحدة**

سكريبت ذكي وقابل لإعادة التشغيل يجهّز بيئة عمل احترافية كاملة على Kali Linux:
أدوات التطوير، Python، Node.js، Docker، Zsh، تحسينات الأداء، واختصارات مفيدة.

[![Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Kali](https://img.shields.io/badge/platform-Kali%20Linux-557C94?logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![Idempotent](https://img.shields.io/badge/idempotent-yes-success)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/azoz8/kali-system-setup?color=blue&label=إصدار)](https://github.com/azoz8/kali-system-setup/releases) [![Last Commit](https://img.shields.io/github/last-commit/azoz8/kali-system-setup?color=green)](https://github.com/azoz8/kali-system-setup/commits/main)

</div>

---

## ✨ المزايا

- ✅ **ذكي وآمن** — يتحقق من الأدوات المثبتة مسبقاً ولا يكرر العمل
- 🔁 **قابل لإعادة التشغيل** — شغّله مرات متعددة بدون أعراض جانبية
- 👤 **يتكيّف مع المستخدم الحالي** تلقائياً (لا أسماء مستخدمين مكوّدة)
- 🎨 **مخرجات ملوّنة** ومنسّقة لمتابعة التقدم بوضوح
- 🐍 **متوافق مع PEP 668** — المكتبات من `apt` والتطبيقات عبر `pipx`، بلا `--break-system-packages`
- 🛡️ **يفشل بصوت عالٍ** — `set -Eeuo pipefail` مع `trap` يطبع رقم السطر، وسجل كامل في `/var/log/kali-setup-*.log`
- 📦 **تثبيت مرن** — يفحص توفر كل حزمة قبل التثبيت ويسمّي المفقود بدل أن يفشل كاملاً
- ⚡ **شامل** — من الأدوات الأساسية حتى تحسينات نواة الشبكة

---

## 🚀 التشغيل السريع

### الطريقة 1: من الملف المضغوط

```bash
# نزّل وفك الضغط
wget https://github.com/azoz8/kali-system-setup/releases/download/v1.0.0/system-setup.tar.xz
tar -xf system-setup.tar.xz
cd system-setup

# شغّل بصلاحيات root
sudo bash setup_system.sh
```

### الطريقة 2: استنساخ المستودع

```bash
git clone https://github.com/azoz8/kali-system-setup.git
cd kali-system-setup
sudo bash setup_system.sh
```

> ⚠️ **مهم:** يحتاج السكريبت صلاحيات `root`. سيخرج فوراً إن لم يُشغَّل بـ `sudo`.

### الخيارات

```bash
bash setup_system.sh --version   # رقم الإصدار (لا يحتاج root)
bash setup_system.sh --help      # المساعدة
```

يُكتب سجل كامل لكل تشغيل في `/var/log/kali-setup-<التاريخ>.log`
(أو `/tmp` إن تعذّرت الكتابة في `/var/log`).

---

## 📦 ما الذي يثبّته السكريبت؟

<table>
<tr>
<td width="50%" valign="top">

### 🔧 الأدوات الأساسية
- `build-essential` `curl` `wget` `git`
- `vim` `nano` — محررات نصوص
- `htop` `btop` — مراقبة الموارد
- `tmux` `screen` — جلسات طرفية
- `tree` `jq` `fzf` — أدوات إنتاجية
- `ripgrep` `bat` `fd-find` — بدائل عصرية
- `nmap` `net-tools` — أدوات الشبكة
- `unzip` `zip` `p7zip` — ضغط الملفات
- `tealdeer` (الأمر `tldr`) `fastfetch` `plocate`

</td>
<td width="50%" valign="top">

### 🐍 Python 3
- `python3-venv` `python3-dev`
- `ipython3` — طرفية تفاعلية
- `pipx` — لتطبيقات Python معزولة
- مكتبات من apt: `python3-requests` `python3-httpx`
  `python3-rich` `python3-typer` `python3-pandas` `python3-numpy`
- تطبيقات عبر pipx: `black` `flake8` `jupyterlab` `httpie`

### 🟢 Node.js
- آخر إصدار **LTS** عبر NodeSource الرسمي
- `npm` تلقائياً

### 🐳 Docker
- `docker.io` + `docker-compose`
- تفعيل تلقائي عند الإقلاع
- إضافة المستخدم لمجموعة `docker`

</td>
</tr>
<tr>
<td valign="top">

### 🐚 Zsh + Oh My Zsh
- ثيم **agnoster** الاحترافي
- **zsh-autosuggestions** — اقتراح ذكي للأوامر
- **zsh-syntax-highlighting** — تلوين فوري
- إضافات `history` و `sudo`

</td>
<td valign="top">

### ⚙️ Git
- محرر افتراضي: `vim`
- ألوان مفعّلة في المخرجات
- الفرع الافتراضي: `main`
- دمج بدلاً من rebase

</td>
</tr>
</table>

---

## ⚡ تحسينات الأداء

### `/etc/security/limits.d/99-custom.conf`
| الإعداد | القيمة | الفائدة |
|---------|--------|---------|
| `nofile` | **65,536** | رفع حد الملفات المفتوحة |
| `nproc` | **32,768** | رفع حد العمليات |

تُطبَّق على `*` و على `root` صراحةً (الرمز `*` لا يشمل root).
وللخدمات، يُكتب `/etc/systemd/system.conf.d/99-limits.conf` بـ `DefaultLimitNOFILE=65536`
لأن `pam_limits` لا يطال وحدات systemd.

### `/etc/sysctl.d/99-custom.conf`
| المعامل | القيمة | الغرض |
|---------|--------|-------|
| `net.core.somaxconn` | `65535` | زيادة طابور اتصالات الشبكة |
| `net.ipv4.tcp_max_syn_backlog` | `65535` | استيعاب دفعات اتصالات أكبر |
| `net.ipv4.ip_local_port_range` | `32768 60999` | مدى المنافذ المؤقتة — لا ينزل تحت 32768 حتى لا تُحجز منافذ خدمات مثل 3306 و 5432 و 8080 |
| `net.ipv4.tcp_fin_timeout` | `15` | تسريع إغلاق الاتصالات |
| `vm.swappiness` | `10` | تفضيل RAM على Swap |
| `vm.dirty_ratio` | `15` | تحسين أداء الكتابة |

---

## 🎯 الاختصارات (Aliases)

يضيف السكريبت ملف `~/.config/shell/aliases.sh` (يُحمَّل في bash و zsh) يحتوي على اختصارات منظّمة.

> ℹ️ حتى الإصدار v1.0.0 كان المسار `~/.bash_aliases`. لم يعد السكريبت يكتب فوقه —
> إن كان لديك ملف قديم فسيبقى كما هو، ويمكنك نقل ما أضفته إليه يدوياً.

<details>
<summary><b>🔄 النظام</b></summary>

```bash
update    # تحديث كامل للنظام
install   # تثبيت حزمة
clean     # تنظيف الحزم غير الضرورية
bat       # batcat (تجاوز تعارض الأسماء)
fd        # fdfind  (تجاوز تعارض الأسماء)
```
</details>

<details>
<summary><b>📂 التنقل والسلامة</b></summary>

```bash
ll, la, l       # عرض ملفات بصيغ مختلفة
.., ..., ....   # رجوع مجلد/مجلدين/ثلاثة
rm, cp, mv      # تطلب تأكيداً قبل التنفيذ (-i)
```
</details>

<details>
<summary><b>🌐 الشبكة</b></summary>

```bash
myip       # عرض IP العام
localip    # عرض IP المحلي
ports      # جميع المنافذ المفتوحة
listening  # المنافذ التي تستمع
```
</details>

<details>
<summary><b>📊 المعالجات والذاكرة</b></summary>

```bash
topmem    # أعلى 10 عمليات استهلاكاً للذاكرة
topcpu    # أعلى 10 عمليات استهلاكاً للمعالج
meminfo   # معلومات الذاكرة
cpuinfo   # معلومات المعالج
diskusage # استهلاك القرص (مرتب)
```
</details>

<details>
<summary><b>🔀 Git</b></summary>

```bash
gs   # git status
ga   # git add
gc   # git commit
gp   # git push
gl   # git log --oneline --graph --decorate
gd   # git diff
```
</details>

<details>
<summary><b>🐍 Python و 🐳 Docker</b></summary>

```bash
py    # python3
pip   # pip3
venv  # python3 -m venv

dps   # docker ps
dpa   # docker ps -a
di    # docker images
dex   # docker exec -it
```
</details>

---

## 📋 ملاحظات ما بعد التشغيل

1. **أعد تسجيل الدخول** لتفعيل:
   - استخدام Docker بدون `sudo`
   - تطبيق aliases في جلسة نظيفة

2. **لتحويل Shell الافتراضي إلى Zsh:**
   ```bash
   chsh -s $(which zsh)
   ```

3. السكريبت **idempotent** — يمكنك تشغيله بأمان متى احتجت تحديث الإعدادات.

---

## 📁 محتويات المستودع

```
.
├── .github/
│   └── workflows/
│       └── ci.yml        # shellcheck + اختبار تشغيل داخل حاوية Kali
├── setup_system.sh       # السكريبت القابل للتشغيل
├── README.md             # هذا الملف
├── CHANGELOG.md          # سجل التغييرات
└── LICENSE               # رخصة MIT
```

---

## 🤝 المساهمة

أي تحسين أو اقتراح مرحَّب به — افتح **Issue** أو **Pull Request**.

## 📜 الرخصة

موزَّع تحت رخصة [MIT](LICENSE) — استخدمه وعدّل عليه بحرية.

---

<div align="center">

**صُنع بـ ❤️ لمجتمع أمن المعلومات**

</div>
