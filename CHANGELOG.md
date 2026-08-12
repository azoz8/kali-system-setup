# Changelog

جميع التغييرات الجوهرية لهذا المشروع موثقة في هذا الملف.

الصيغة مبنية على [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)،
والمشروع يتبع [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] — 2026-07-24

إصدار إصلاحات تشغيلية. يحتوي تغييراً واحداً يمسّ التوافق: **مسار ملف الـ aliases**.

#### 🔧 مُصلَح
- **قسم الأدوات الأساسية لم يكن يثبّت شيئاً إطلاقاً**: `neofetch` أُزيل من مستودعات
  Debian/Kali (المشروع مؤرشف منذ 2024)، فكان `apt-get install` يفشل بالقائمة كاملةً
  والخطأ مبتلَع بـ `2>/dev/null`. الآن تُفحص كل حزمة على حدة عبر `apt-cache show`،
  ويُثبَّت المتاح ويُسمّى المفقود صراحةً.
- **`sudo -u` بلا `-H`**: كانت `$HOME` تبقى `/root`، فيُركَّب Oh My Zsh في مجلد root
  وتفشل كل تعديلات `sed` على `.zshrc` بصمت بسبب `|| true`. أُضيف `-H` لكل الاستدعاءات،
  وصار السكريبت يتحقق من وجود `.oh-my-zsh` فعلياً قبل أي تعديل.
- **`net.ipv4.ip_local_port_range`**: القيمة `1024 65535` كانت تجعل النواة تحجز منافذ
  خدمات شائعة (3306، 5432، 8080) كمنافذ ephemeral، فتظهر أخطاء
  `Address already in use` متقطعة مع Docker و PostgreSQL. صارت `32768 60999`.
- **`apt-get upgrade` على توزيعة rolling** كان يترك حزماً معلّقة (held back) —
  استُبدل بـ `full-upgrade` في وضع غير تفاعلي.
- **ادعاء الـ idempotency**: كان `cat > ~/.bash_aliases` يمسح ملف المستخدم في كل تشغيل.
- **`git config`** كان محبوساً داخل شرط غياب `.gitconfig` كلياً، فأي مستخدم لديه ملف
  مسبق لا يحصل على أي إعداد. صار كل مفتاح يُفحص على حدة بلا دهس قيمة موجودة.
- **`limits.conf`**: الرمز `*` لا يشمل `root` ولا خدمات systemd.
- `raw.github.com` (اسم مضيف قديم) → `raw.githubusercontent.com`.
- تحذير `SC2015` من shellcheck في سطري ملخّص Docker و Node.js.

#### 🔄 مُغيَّر
- **⚠️ مسار الـ aliases**: من `~/.bash_aliases` إلى `~/.config/shell/aliases.sh`
  (ملف مملوك للسكريبت، آمن للكتابة فوقه). الملف القديم **لا يُحذف ولا يُعدَّل** —
  انقل ما أضفته إليه يدوياً إن رغبت.
- **⚠️ `neofetch` → `fastfetch`**، **`locate` → `plocate`** (مع `updatedb.plocate`)،
  و **`tldr` → `tealdeer`** (حزمة `tldr` غير موجودة في مستودعات Kali، و`tealdeer`
  يوفّر الأمر `tldr` نفسه).
- **حزم Python**: حُذف `pip3 install --break-system-packages` نهائياً — كان يكتب فوق
  حزم مُدارة بـ apt وقد يكسر أدوات Kali. المكتبات صارت من apt عبر `python3-*`،
  والتطبيقات المستقلة (`black`, `flake8`, `jupyterlab`, `httpie`) عبر `pipx`.
  بهذا صار ادعاء التوافق مع PEP 668 في التوثيق مطابقاً للتنفيذ.
- `limits` تُكتب في `/etc/security/limits.d/99-custom.conf` بدل الإلحاق بـ `limits.conf`.
- إضافة `sudo` إلى الحزم الأساسية لأن إعدادات المستخدم تعتمد عليه.

#### ✅ مُضاف
- `set -Eeuo pipefail` مع `trap` على `ERR` يطبع رقم السطر ومسار السجل.
- سجل كامل لكل تشغيل في `/var/log/kali-setup-<التاريخ>.log` (fallback إلى `/tmp`).
- كشف بيئة الحاوية: تُتخطّى عمليات `systemctl` و `sysctl` بـ `info` واضح بدل الفشل.
- حارس يحذّر عند تشغيل السكريبت كـ root مباشرة، وفحص صلاحية مجلد المنزل.
- `--version` و `--help`، وثابت `VERSION` في رأس السكريبت.
- `alias bat='batcat'` و `alias fd='fdfind'` — كانا موثّقين في README ومفقودين من الكود.
- تكامل مستمر في `.github/workflows/ci.yml`: `shellcheck -x` + تشغيل السكريبت
  **مرتين** داخل حاوية `kalilinux/kali-rolling` للتحقق من الـ idempotency.

---

## [v1.0.0] — 2026-05-06

### الإصدار الأول 🎉

#### ✅ مُضاف
- تحديث كامل للنظام وترقية جميع الحزم
- تثبيت أدوات التطوير الأساسية: `curl`, `wget`, `git`, `vim`, `nano`, `htop`, `btop`, `tmux`, `screen`
- أدوات الإنتاجية العصرية: `fzf`, `bat`, `fd-find`, `ripgrep`
- أدوات الشبكة: `nmap`, `net-tools`, `dnsutils`, `traceroute`, `tcpdump`
- Python 3 كامل: `venv`, `pip`, `ipython3`, `requests`, `httpx`, `rich`, `jupyter`, `pandas`, `numpy`
- Node.js LTS عبر NodeSource الرسمي + npm
- Docker + docker-compose مع تفعيل تلقائي عند الإقلاع
- Zsh + Oh My Zsh + إضافات: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `history`, `sudo`
- ثيم `agnoster` الاحترافي لـ Zsh
- إعداد Git الأساسي (محرر، ألوان، فرع افتراضي main)
- ملف `~/.bash_aliases` بأكثر من 30 اختصاراً منظماً
- تحسين أداء النظام عبر `sysctl` و `limits.conf`

#### 🔧 تقني
- السكريبت idempotent — آمن لإعادة التشغيل أكثر من مرة
- يتكيف تلقائياً مع اسم المستخدم الحالي (بدون أسماء مكوّدة)
- مخرجات ملوّنة ومنسّقة لمتابعة التقدم
- متوافق مع PEP 668 (يستخدم `apt` و `pipx` لتجنب تعارضات بيئة Kali)

---

[v1.1.0]: https://github.com/ABDUAZIZX/kali-system-setup/releases/tag/v1.1.0
[v1.0.0]: https://github.com/ABDUAZIZX/kali-system-setup/releases/tag/v1.0.0
