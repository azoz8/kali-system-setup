# Changelog

جميع التغييرات الجوهرية لهذا المشروع موثقة في هذا الملف.

الصيغة مبنية على [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)،
والمشروع يتبع [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[v1.0.0]: https://github.com/azoz8/kali-system-setup/releases/tag/v1.0.0
